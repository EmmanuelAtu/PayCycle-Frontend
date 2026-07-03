import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../models/plan.dart';
import '../../widgets/bottom_nav.dart';

class SubscribersScreen extends StatefulWidget {
  final Plan? plan;
  const SubscribersScreen({super.key, this.plan});

  @override
  State<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends State<SubscribersScreen> {
  SubscriberStatus? _filter; // null = all
  bool _loading = true;
  List<Subscriber> _all = [];

  double _collected = 0;
  double _outstanding = 0;

  @override
  void initState() {
    super.initState();
    _loadSubscribers();
  }

  Future<void> _loadSubscribers() async {
    // TODO: replace with ApiClient.get('/plans/${widget.plan?.id}/subscribers')
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _collected = 180000;
      _outstanding = 30000;
      _all = const [
        Subscriber(
          id: 's1',
          name: 'Amara Eze',
          email: 'amara@example.com',
          status: SubscriberStatus.failed,
          lastPaidDate: 'Jun 1',
          failureReason: 'Card declined',
        ),
        Subscriber(
          id: 's2',
          name: 'Temi Adeyemi',
          email: 'temi@example.com',
          status: SubscriberStatus.overdue,
          lastPaidDate: 'May 1',
        ),
        Subscriber(
          id: 's3',
          name: 'Chidi Obi',
          email: 'chidi@example.com',
          status: SubscriberStatus.active,
          lastPaidDate: 'Jun 1',
        ),
        Subscriber(
          id: 's4',
          name: 'Ngozi Kalu',
          email: 'ngozi@example.com',
          status: SubscriberStatus.active,
          lastPaidDate: 'Jun 1',
        ),
        Subscriber(
          id: 's5',
          name: 'Babatunde Ige',
          email: 'babs@example.com',
          status: SubscriberStatus.active,
          lastPaidDate: 'Jun 1',
        ),
      ];
      _loading = false;
    });
  }

  List<Subscriber> get _filtered =>
      _filter == null ? _all : _all.where((s) => s.status == _filter).toList();

  int _countOf(SubscriberStatus s) =>
      _all.where((sub) => sub.status == s).length;

  Future<void> _retryCharge(Subscriber sub) async {
    // TODO: POST /charge/:subscriber_id
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying charge for ${sub.name}…'),
        backgroundColor: kNavy,
      ),
    );
  }

  Future<void> _sendLink(Subscriber sub) async {
    // TODO: trigger WhatsApp deep link or Termii SMS via backend
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
                      child: CircularProgressIndicator(color: kEmerald))
                  : RefreshIndicator(
                      onRefresh: _loadSubscribers,
                      color: kEmerald,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          _buildSummaryRow(),
                          const SizedBox(height: 12),
                          ..._filtered.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SubscriberRow(
                                  subscriber: s,
                                  onRetry: () => _retryCharge(s),
                                  onSendLink: () => _sendLink(s),
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
                      fontWeight: FontWeight.w500),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kEmerald,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, color: kWhite, size: 14),
                    SizedBox(width: 4),
                    Text('Share link',
                        style: TextStyle(
                            color: kWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
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
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _showShareSheet(Plan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
            color: isFail && !isActive
                ? const Color(0xFFF09595)
                : kBorderC,
            width: 0.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: text, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.valueColor});

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
          Text(label,
              style: const TextStyle(color: kSubText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SubscriberRow extends StatelessWidget {
  final Subscriber subscriber;
  final VoidCallback onRetry;
  final VoidCallback onSendLink;
  const _SubscriberRow({
    required this.subscriber,
    required this.onRetry,
    required this.onSendLink,
  });

  @override
  Widget build(BuildContext context) {
    final s = subscriber;
    final isFailed = s.status == SubscriberStatus.failed;
    final isOverdue = s.status == SubscriberStatus.overdue;
    final isActive = s.status == SubscriberStatus.active;
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
                    Text(s.name,
                        style: const TextStyle(
                            color: kNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      isFailed
                          ? 'Last attempted ${s.lastPaidDate} · ${s.failureReason ?? 'Failed'}'
                          : isOverdue
                              ? 'Last paid ${s.lastPaidDate} · Payment due'
                              : 'Paid ${s.lastPaidDate}',
                      style:
                          const TextStyle(color: kSubText, fontSize: 11),
                    ),
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
      child: Text(initials,
          style: TextStyle(
              color: text, fontSize: 12, fontWeight: FontWeight.w500)),
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
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 12),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
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
            Text(label,
                style: TextStyle(
                    color: text,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
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
          const Text('Share payment link',
              style: TextStyle(
                  color: kNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Send this link once. Subscribers pay and get charged automatically.',
              style: const TextStyle(color: kSubText, fontSize: 13)),
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
                    Clipboard.setData(
                        ClipboardData(text: plan.paymentLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  },
                  child: const Icon(Icons.copy_outlined,
                      color: kEmeraldDk, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShareOption(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366), size: 24),
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
                  icon: const Icon(Icons.share_outlined, color: kSubText, size: 24),
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
  const _ShareOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
          Text(label,
              style: const TextStyle(color: kSubText, fontSize: 12)),
        ],
      ),
    );
  }
}