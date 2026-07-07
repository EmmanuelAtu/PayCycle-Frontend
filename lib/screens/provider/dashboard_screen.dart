import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/plan.dart';
import '../../widgets/bottom_nav.dart';
import 'subscribers_screen.dart';
import 'create_plan_screen.dart';
import '../../core/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;

  // User info — read from secure storage after login
  String _userName = '';

  // Provider summary — populated from endpoints
  double _totalRevenue = 0;
  int _activeSubscribers = 0;
  int _failedPayments = 0;
  String _nextBilling = '—';
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDashboard();
  }

  /// Fetches name from /auth/me — falls back to locally stored name
  /// so the topbar always shows something even if the network is slow.
  Future<void> _loadUserName() async {
    // Show stored name immediately while the request is in flight
    final stored = await ApiClient.getName();
    if (mounted && stored != null && stored.isNotEmpty) {
      setState(() => _userName = stored);
    }

    try {
      final me = await ApiClient.getMe();
      final name = me['name'] as String? ?? me['full_name'] as String?;
      if (name != null && name.isNotEmpty) {
        await ApiClient.saveName(name); // keep storage in sync
        if (mounted) setState(() => _userName = name);
      }
    } catch (e) {
      // Network failed — stored name already showing, nothing to do
      debugPrint('Could not fetch /auth/me: $e');
    }
  }

  /// Returns up to 2 uppercase initials from a full name
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Fetch Plans
      final plansJson = await ApiClient.getPlans();
      final webBase = ApiClient.webBaseUrl;

      final plans = plansJson.map((raw) {
        final p = raw as Map<String, dynamic>;
        final joinToken = p['join_token'] as String? ?? '';
        return Plan(
          id: p['id'].toString(),
          name: p['name'] as String? ?? '',
          amount: (p['amount'] as num?)?.toDouble() ?? 0, // plain Naira
          cycle: _cycleFromString(
              (p['billing_frequency'] ?? p['cycle']) as String?),
          billingDay: (p['billing_day'] as num?)?.toInt(),
          activeCount: (p['active_count'] as num?)?.toInt() ?? 0,
          failedCount: (p['failed_count'] as num?)?.toInt() ?? 0,
          overdueCount: (p['overdue_count'] as num?)?.toInt() ?? 0,
          // Construct the join URL from the token the backend returns
          paymentLink: joinToken.isNotEmpty
              ? '$webBase/join/$joinToken'
              : p['payment_link'] as String? ?? '',
        );
      }).toList();

      if (mounted) setState(() => _plans = plans);

      // 2. Try dashboard summary (quiet fail if endpoint not ready)
      try {
        final dashboardData = await ApiClient.getDashboard();
        if (mounted) {
          setState(() {
            _totalRevenue =
                (dashboardData['total_revenue'] as num?)?.toDouble() ?? 0;
            _activeSubscribers =
                (dashboardData['active_subscribers'] as num?)?.toInt() ?? 0;
            _failedPayments =
                (dashboardData['failed_payments'] as num?)?.toInt() ?? 0;
            _nextBilling =
                dashboardData['next_billing'] as String? ?? '—';
          });
        }
      } catch (dashError) {
        debugPrint('Dashboard endpoint not ready yet: $dashError');
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your plans. Pull down to retry.';
      });
      debugPrint('Plans sync failed: $e');
    }
  }

  BillingCycle _cycleFromString(String? value) {
    switch (value) {
      case 'daily':     return BillingCycle.daily;
      case 'weekly':    return BillingCycle.weekly;
      case 'quarterly': return BillingCycle.quarterly;
      case 'monthly':
      default:          return BillingCycle.monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kEmerald))
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                color: kEmerald,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildTopBar()),
                    SliverToBoxAdapter(child: _buildStatsBand()),
                    if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: _ErrorBanner(
                              message: _error!, onRetry: _loadDashboard),
                        ),
                      ),
                    if (_failedPayments > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: _FailureAlert(count: _failedPayments),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                        child: _buildPlansHeader(),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: _PlanCard(
                            plan: _plans[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SubscribersScreen(plan: _plans[i]),
                              ),
                            ),
                          ),
                        ),
                        childCount: _plans.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildTopBar() {
    final initials = _initials(_userName);
    final displayName = _userName.isNotEmpty ? _userName : 'Loading...';

    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: kEmerald,
            child: Text(
              initials,
              style: const TextStyle(
                  color: kWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const Text(
                  'Provider',
                  style: TextStyle(color: kSubText, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: kWhite, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: kWhite, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBand() {
    return Container(
      color: kNavyMid,
      padding: const EdgeInsets.all(14),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: [
          _StatCard(
            label: 'Total revenue',
            value:
                '₦${_totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            valueColor: const Color(0xFF4ADE80),
          ),
          _StatCard(
            label: 'Active subscribers',
            value: '$_activeSubscribers',
          ),
          _StatCard(
            label: 'Failed payments',
            value: '$_failedPayments',
            valueColor: const Color(0xFFF87171),
          ),
          _StatCard(label: 'Next billing', value: _nextBilling),
        ],
      ),
    );
  }

  Widget _buildPlansHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Your plans',
            style: TextStyle(
                color: kNavy, fontSize: 13, fontWeight: FontWeight.w500)),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreatePlanScreen())),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kEmerald,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: kWhite, size: 14),
                SizedBox(width: 4),
                Text('New plan',
                    style: TextStyle(
                        color: kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor = kWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: kSubText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kFailBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF09595), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off, color: kFailText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: kFailText, fontSize: 12, height: 1.5)),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    color: kFailText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}

class _FailureAlert extends StatelessWidget {
  final int count;
  const _FailureAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kFailBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF09595), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: kFailText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count subscriber${count > 1 ? 's' : ''} with failed payments. Retry or resend their payment links.',
                  style: const TextStyle(
                      color: kFailText, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscribersScreen())),
                  child: const Text(
                    'View failed payments',
                    style: TextStyle(
                        color: kFailText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

  static const _icons = {
    'math': Icons.menu_book_outlined,
    'gym': Icons.fitness_center_outlined,
    'brand': Icons.work_outline,
    'consult': Icons.work_outline,
    'piano': Icons.piano_outlined,
    'lesson': Icons.school_outlined,
  };

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _icons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.receipt_long_outlined;
  }

  String _formatAmount(double amount) {
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderC, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kEmeraldLt,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(_iconFor(plan.name), color: kEmeraldDk, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: const TextStyle(
                          color: kNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('${plan.totalSubscribers} subscribers',
                      style:
                          const TextStyle(color: kSubText, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (plan.activeCount > 0)
                        _StatusBadge('${plan.activeCount} active',
                            kEmeraldLt, const Color(0xFF00704A)),
                      if (plan.failedCount > 0) ...[
                        const SizedBox(width: 4),
                        _StatusBadge(
                            '${plan.failedCount} failed', kFailBg, kFailText),
                      ],
                      if (plan.overdueCount > 0) ...[
                        const SizedBox(width: 4),
                        _StatusBadge('${plan.overdueCount} overdue',
                            kWarnBg, kWarnText),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatAmount(plan.amount),
                    style: const TextStyle(
                        color: kNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(plan.cycle.label,
                    style:
                        const TextStyle(color: kSubText, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  const _StatusBadge(this.label, this.bg, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: text, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}