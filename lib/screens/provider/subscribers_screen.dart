import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../models/plan.dart';
import '../../widgets/bottom_nav.dart';
import 'package:pay_cycle/core/api_client.dart';

class SubscribersScreen extends StatefulWidget {
  final Plan? plan;
  const SubscribersScreen({super.key, this.plan});

  @override
  State<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends State<SubscribersScreen> {
  SubscriberStatus? _filter; // null = all
  bool _loading = true;
  String? _error;
  List<Subscriber> _all = [];

  // Maps subscriber id -> plan name, so each row can show which plan
  // they belong to. Populated differently depending on mode:
  //  - single-plan mode: every subscriber maps to widget.plan!.name
  //  - all-subscribers mode: filled in per-plan while aggregating
  final Map<String, String> _planNameById = {};

  // NOTE: the backend's /plans/{id}/subscriptions endpoint doesn't return
  // collected/outstanding totals (that data doesn't exist anywhere yet —
  // it would need to come from a join against Transaction amounts).
  // Left at 0 rather than faking numbers; ask backend to add if needed.
  double _collected = 0;
  double _outstanding = 0;

  @override
  void initState() {
    super.initState();
    _loadSubscribers();
  }

  Future<void> _loadSubscribers() async {
    final planId = widget.plan?.id;

    setState(() {
      _loading = true;
      _error = null;
    });

    if (planId != null) {
      // Single-plan mode: just this plan's subscribers.
      try {
        final raw = await ApiClient.getList('/plans/$planId/subscriptions');
        _planNameById.clear();
        _all = raw.map((e) {
          final sub = _subscriberFromApi(e as Map<String, dynamic>);
          _planNameById[sub.id] = widget.plan!.name;
          return sub;
        }).toList();
        setState(() => _loading = false);
      } catch (e) {
        debugPrint('Subscribers load failed: $e');
        setState(() {
          _loading = false;
          _error = 'Could not load subscribers. Pull down to retry.';
        });
      }
      return;
    }

    // All-subscribers mode: fetch every plan, then fetch each plan's
    // subscribers in parallel and merge, tagging each with its plan name.
    try {
      final plansRaw = await ApiClient.getPlans();
      final plans = plansRaw.map((e) => e as Map<String, dynamic>).toList();

      final results = await Future.wait(plans.map((p) async {
        final id = p['id'].toString();
        final name = p['name'] as String? ?? 'Unknown plan';
        try {
          final raw = await ApiClient.getList('/plans/$id/subscriptions');
          return raw
              .map((e) => MapEntry(
                    _subscriberFromApi(e as Map<String, dynamic>),
                    name,
                  ))
              .toList();
        } catch (e) {
          debugPrint('Subscriptions for plan $id failed: $e');
          return <MapEntry<Subscriber, String>>[];
        }
      }));

      _planNameById.clear();
      _all = [];
      for (final planResults in results) {
        for (final entry in planResults) {
          _all.add(entry.key);
          _planNameById[entry.key.id] = entry.value;
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('All-subscribers load failed: $e');
      setState(() {
        _loading = false;
        _error = 'Could not load subscribers. Pull down to retry.';
      });
    }
  }

  /// Maps the backend's SubscriberOut shape onto the app's Subscriber model.
  ///
  /// Backend status enum is pending|active|paused|cancelled|past_due, but
  /// the app model only knows active|failed|overdue. There's currently no
  /// "failed" signal available here (that lives on Transaction.failure_reason,
  /// which this endpoint doesn't join in) — so failed subscribers will show
  /// as active until the backend exposes that. past_due maps to overdue.
  Subscriber _subscriberFromApi(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    final rawStatus = json['status'] as String?;

    SubscriberStatus status;
    switch (rawStatus) {
      case 'past_due':
        status = SubscriberStatus.overdue;
        break;
      case 'active':
      case 'pending':
      case 'paused':
      case 'cancelled':
      default:
        status = SubscriberStatus.active;
    }

    final nextBilling = json['next_billing_date'] as String?;

    return Subscriber(
      id: json['id'].toString(),
      name: customer['name'] as String? ?? 'Unknown',
      email: (customer['email'] as String?) ?? '',
      status: status,
      // Backend has no "last paid" date, only next_billing_date — shown
      // here as a stand-in until the backend adds real payment history.
      lastPaidDate: nextBilling != null ? _formatDate(nextBilling) : null,
      failureReason: null,
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  List<Subscriber> get _filtered =>
      _filter == null ? _all : _all.where((s) => s.status == _filter).toList();

  int _countOf(SubscriberStatus s) =>
      _all.where((sub) => sub.status == s).length;

  Future<void> _retryCharge(Subscriber sub) async {
    try {
      await ApiClient.retryCharge(sub.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retrying charge for ${sub.name}…'),
          backgroundColor: kNavy,
        ),
      );
      _loadSubscribers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not retry charge for ${sub.name}'),
          backgroundColor: kFailText,
        ),
      );
    }
  }

  Future<void> _sendLink(Subscriber sub) async {
    // TODO: no backend endpoint yet for triggering WhatsApp/SMS payment
    // link delivery — wire this up once that route exists.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment link sent to ${sub.name}'),
        backgroundColor: kEmeraldDk,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      backgroundColor: kPageBg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(plan),
            _buildFilterRow(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kEmerald),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSubscribers,
                      color: kEmerald,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          if (_error != null) ...[
                            _ErrorBanner(
                              message: _error!,
                              onRetry: _loadSubscribers,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildSummaryRow(),
                          const SizedBox(height: 12),
                          ..._filtered.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _SubscriberRow(
                                subscriber: s,
                                planName:
                                    widget.plan == null ? _planNameById[s.id] : null,
                                onRetry: () => _retryCharge(s),
                                onSendLink: () => _sendLink(s),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Plan? plan) {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: kWhite, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan?.name ?? 'All subscribers',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (plan != null)
                  Text(
                    '${plan.totalSubscribers} subscribers · ₦${plan.amount.toStringAsFixed(0)} · ${plan.cycle.label}',
                    style: const TextStyle(color: kSubText, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (plan != null)
            GestureDetector(
              onTap: () => _showShareSheet(plan),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kEmerald,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, color: kWhite, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Share link',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterPill(
              label: 'All (${_all.length})',
              isActive: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            const SizedBox(width: 6),
            _FilterPill(
              label: 'Active (${_countOf(SubscriberStatus.active)})',
              isActive: _filter == SubscriberStatus.active,
              onTap: () => setState(() => _filter = SubscriberStatus.active),
            ),
            const SizedBox(width: 6),
            _FilterPill(
              label: 'Failed (${_countOf(SubscriberStatus.failed)})',
              isActive: _filter == SubscriberStatus.failed,
              onTap: () => setState(() => _filter = SubscriberStatus.failed),
              isFail: true,
            ),
            const SizedBox(width: 6),
            _FilterPill(
              label: 'Overdue (${_countOf(SubscriberStatus.overdue)})',
              isActive: _filter == SubscriberStatus.overdue,
              onTap: () => setState(() => _filter = SubscriberStatus.overdue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Collected this cycle',
            value: '₦${_formatNum(_collected)}',
            valueColor: const Color(0xFF00704A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Outstanding',
            value: '₦${_formatNum(_outstanding)}',
            valueColor: kFailText,
          ),
        ),
      ],
    );
  }

  String _formatNum(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  void _showShareSheet(Plan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ShareSheet(plan: plan),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isFail;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isFail = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    if (isActive) {
      bg = kNavy;
      text = kWhite;
    } else if (isFail) {
      bg = kFailBg;
      text = kFailText;
    } else {
      bg = kWhite;
      text = kSubText;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFail && !isActive ? const Color(0xFFF09595) : kBorderC,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderC, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kSubText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriberRow extends StatelessWidget {
  final Subscriber subscriber;
  final String? planName;
  final VoidCallback onRetry;
  final VoidCallback onSendLink;
  const _SubscriberRow({
    required this.subscriber,
    this.planName,
    required this.onRetry,
    required this.onSendLink,
  });

  @override
  Widget build(BuildContext context) {
    final s = subscriber;
    final isFailed = s.status == SubscriberStatus.failed;
    final isOverdue = s.status == SubscriberStatus.overdue;
    final showActions = isFailed || isOverdue;

    Color borderColor = kBorderC;
    Color bgColor = kWhite;
    if (isFailed) {
      borderColor = const Color(0xFFF09595);
      bgColor = const Color(0xFFFFFAFA);
    } else if (isOverdue) {
      borderColor = const Color(0xFFF6D78A);
      bgColor = const Color(0xFFFFFCF0);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(initials: s.initials, status: s.status),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: kNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFailed
                          ? 'Last attempted ${s.lastPaidDate ?? '—'} · ${s.failureReason ?? 'Failed'}'
                          : isOverdue
                          ? 'Next billing ${s.lastPaidDate ?? '—'} · Payment due'
                          : 'Next billing ${s.lastPaidDate ?? '—'}',
                      style: const TextStyle(color: kSubText, fontSize: 11),
                    ),
                    if (planName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        planName!,
                        style: const TextStyle(
                          color: kEmeraldDk,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(status: s.status),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Retry charge',
                    icon: const Icon(Icons.refresh, size: 14),
                    isPrimary: isFailed,
                    isDanger: isOverdue,
                    onTap: onRetry,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionBtn(
                    label: isFailed ? 'Send link' : 'Remind',
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 14),
                    onTap: onSendLink,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final SubscriberStatus status;
  const _Avatar({required this.initials, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case SubscriberStatus.active:
        bg = kEmeraldLt;
        text = const Color(0xFF00704A);
        break;
      case SubscriberStatus.failed:
        bg = kFailBg;
        text = kFailText;
        break;
      case SubscriberStatus.overdue:
        bg = kWarnBg;
        text = kWarnText;
        break;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      child: Text(
        initials,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SubscriberStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData icon;
    switch (status) {
      case SubscriberStatus.active:
        bg = kEmeraldLt;
        text = const Color(0xFF00704A);
        icon = Icons.check_circle_outline;
        break;
      case SubscriberStatus.failed:
        bg = kFailBg;
        text = kFailText;
        icon = Icons.error_outline;
        break;
      case SubscriberStatus.overdue:
        bg = kWarnBg;
        text = kWarnText;
        icon = Icons.access_time_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 12),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isPrimary;
  final bool isDanger;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    if (isPrimary) {
      bg = kEmerald;
      text = kWhite;
      border = kEmerald;
    } else if (isDanger) {
      bg = kFailBg;
      text = kFailText;
      border = const Color(0xFFF09595);
    } else {
      bg = kWhite;
      text = kNavy;
      border = kBorderC;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: text, size: 14),
              child: icon,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
        children: [
          const Icon(Icons.wifi_off, color: kFailText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: kFailText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: kFailText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final Plan plan;
  const _ShareSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kBorderC,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share payment link',
            style: TextStyle(
              color: kNavy,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Send this link once. Subscribers pay and get charged automatically.',
            style: TextStyle(color: kSubText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kPageBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderC, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.paymentLink,
                    style: const TextStyle(color: kSubText, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: plan.paymentLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  },
                  child: const Icon(
                    Icons.copy_outlined,
                    color: kEmeraldDk,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShareOption(
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366),
                    size: 24,
                  ),
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    // TODO: launch whatsapp deep link
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareOption(
                  icon: const Icon(Icons.sms_outlined, color: kNavy, size: 24),
                  label: 'SMS',
                  color: kNavy,
                  onTap: () {
                    // TODO: launch SMS intent
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareOption(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: kSubText,
                    size: 24,
                  ),
                  label: 'More',
                  color: kSubText,
                  onTap: () {
                    // TODO: system share sheet
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: kSubText, fontSize: 12)),
        ],
      ),
    );
  }
}