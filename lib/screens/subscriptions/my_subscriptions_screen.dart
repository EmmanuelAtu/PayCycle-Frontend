import 'package:flutter/material.dart';
import '../../core/theme.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  bool _loading = true;
  List<_Subscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    // PLACEHOLDER — replace with:
    // final data = await ApiClient.get('/subscriber/my-subscriptions');
    // final list = data['subscriptions'] as List;
    // _subs = list.map((e) => _Subscription.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _subs = [
        const _Subscription(
          id: '1',
          planName: 'Gym membership',
          providerName: 'FitLife Gym',
          amount: 8000,
          cycle: 'Weekly',
          nextChargeDate: 'Jul 3, 2025',
          status: _SubStatus.active,
        ),
        const _Subscription(
          id: '2',
          planName: 'Piano lessons',
          providerName: 'Tunde Music Academy',
          amount: 20000,
          cycle: 'Monthly',
          nextChargeDate: 'Jul 1, 2025',
          status: _SubStatus.active,
        ),
        const _Subscription(
          id: '3',
          planName: 'Brand consulting',
          providerName: 'Chukwu and Co.',
          amount: 120000,
          cycle: 'Quarterly',
          nextChargeDate: 'Sep 1, 2025',
          status: _SubStatus.failed,
        ),
      ];
      _loading = false;
    });
  }

  double get _totalMonthly {
    return _subs
        .where((s) => s.status == _SubStatus.active)
        .fold(0.0, (sum, s) {
      switch (s.cycle.toLowerCase()) {
        case 'daily':   return sum + s.amount * 30;
        case 'weekly':  return sum + s.amount * 4;
        case 'quarterly': return sum + s.amount / 3;
        default:        return sum + s.amount;
      }
    });
  }

  String _formatNum(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kEmerald))
                  : _subs.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadSubscriptions,
                          color: kEmerald,
                          child: ListView(
                            padding: const EdgeInsets.all(14),
                            children: [
                              _buildSummaryBand(),
                              const SizedBox(height: 16),
                              const Text('Active subscriptions',
                                  style: TextStyle(
                                      color: kNavy,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 10),
                              ..._subs.map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _SubCard(
                                      sub: s,
                                      onCancel: () => _confirmCancel(s),
                                    ),
                                  )),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: const Row(
        children: [
          Text('My subscriptions',
              style: TextStyle(
                  color: kWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryBand() {
    final activeCount = _subs.where((s) => s.status == _SubStatus.active).length;
    final failedCount = _subs.where((s) => s.status == _SubStatus.failed).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Est. monthly spend',
                    style: TextStyle(color: kSubText, fontSize: 11)),
                const SizedBox(height: 4),
                Text('N${_formatNum(_totalMonthly)}',
                    style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 22,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SummaryChip(label: '$activeCount active', isActive: true),
              if (failedCount > 0) ...[
                const SizedBox(height: 6),
                _SummaryChip(label: '$failedCount failed', isActive: false),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: kEmeraldLt,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.receipt_long_outlined,
                  color: kEmeraldDk, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('No subscriptions yet',
                style: TextStyle(
                    color: kNavy, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
              'When a provider shares a payment link with you, your subscriptions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kSubText, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(_Subscription sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel subscription?',
            style: TextStyle(
                color: kNavy, fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text(
          'You will no longer be charged for "${sub.planName}". This cannot be undone.',
          style: const TextStyle(color: kSubText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it',
                style: TextStyle(color: kSubText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel subscription',
                style: TextStyle(color: kFailText)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // PLACEHOLDER — replace with:
      // await ApiClient.post('/subscriber/cancel/${sub.id}');
      setState(() => _subs.removeWhere((s) => s.id == sub.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sub.planName} subscription cancelled'),
          backgroundColor: kNavy,
        ),
      );
    }
  }
}

// ── Data ───────────────────────────────────────────────────────

enum _SubStatus { active, failed, paused }

class _Subscription {
  final String id;
  final String planName;
  final String providerName;
  final double amount;
  final String cycle;
  final String nextChargeDate;
  final _SubStatus status;

  const _Subscription({
    required this.id,
    required this.planName,
    required this.providerName,
    required this.amount,
    required this.cycle,
    required this.nextChargeDate,
    required this.status,
  });

  factory _Subscription.fromJson(Map<String, dynamic> json) => _Subscription(
        id: json['id'] as String,
        planName: json['plan_name'] as String,
        providerName: json['provider_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        cycle: json['cycle'] as String,
        nextChargeDate: json['next_charge_date'] as String,
        status: _SubStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => _SubStatus.active,
        ),
      );
}

// ── Widgets ────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _SummaryChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? kEmeraldLt : kFailBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: isActive ? kEmeraldDk : kFailText,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _SubCard extends StatelessWidget {
  final _Subscription sub;
  final VoidCallback onCancel;
  const _SubCard({required this.sub, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isFailed = sub.status == _SubStatus.failed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed ? const Color(0xFFF09595) : kBorderC,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: kEmeraldLt,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_long_outlined,
                    color: kEmeraldDk, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.planName,
                        style: const TextStyle(
                            color: kNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(sub.providerName,
                        style: const TextStyle(
                            color: kSubText, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'N${sub.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                        color: kNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(sub.cycle,
                      style: const TextStyle(color: kSubText, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: kBorderC, height: 1, thickness: 0.5),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isFailed ? Icons.error_outline : Icons.calendar_today_outlined,
                color: isFailed ? kFailText : kSubText,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isFailed
                      ? 'Payment failed — update your card'
                      : 'Next charge: ${sub.nextChargeDate}',
                  style: TextStyle(
                      color: isFailed ? kFailText : kSubText, fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                child: const Text('Cancel',
                    style: TextStyle(
                        color: kSubText,
                        fontSize: 12,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
          if (isFailed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // PLACEHOLDER — launch Nomba checkout to update card
                  // context.push('/pay/update-card/${sub.id}');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kFailText,
                  side: const BorderSide(color: Color(0xFFF09595), width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Update payment card',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}