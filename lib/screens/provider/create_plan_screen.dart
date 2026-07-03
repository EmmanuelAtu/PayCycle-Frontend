import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../models/plan.dart';
import '../../core/api_client.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  BillingCycle _cycle = BillingCycle.monthly;
  int _billingDay = 1;
  bool _loading = false;

  // Generated after save — populated from backend response
  String? _generatedLink;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String get _previewName =>
      _nameCtrl.text.trim().isEmpty ? 'Your plan name' : _nameCtrl.text.trim();

  String get _previewAmount {
    final raw = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (raw == 0) return '₦0';
    return '₦${raw.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }

  String get _billingDayLabel {
    switch (_cycle) {
      case BillingCycle.daily:
        return 'Charge every day';
      case BillingCycle.weekly:
        return 'Charge every Monday';
      case BillingCycle.monthly:
      case BillingCycle.quarterly:
        final suffixes = {1: 'st', 2: 'nd', 3: 'rd'};
        final suffix = suffixes[_billingDay] ?? 'th';
        return 'Charge on the $_billingDay$suffix of each period';
    }
  }

  Future<void> _savePlan({bool shareAfter = true}) async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _loading = true);

  try {
    final result = await ApiClient.createPlan(
      name: _nameCtrl.text,
      amount: int.parse(_amountCtrl.text),
      cycle: _cycle.name,
      billingDay: _billingDay,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _generatedLink = result['payment_link'] as String? ?? '';
    });

    if (shareAfter) _showShareSheet();
  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not create plan: $e')),
    );
  }
}

  void _showShareSheet() {
    if (_generatedLink == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ShareSheet(link: _generatedLink!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildField(
                      label: 'Plan name',
                      hint: 'Something your subscribers will recognise',
                      child: TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                            hintText: 'e.g. Piano lessons – beginners'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a plan name'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Amount per cycle',
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          prefixText: '₦  ',
                          prefixStyle: TextStyle(
                              color: kSubText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          hintText: '15000',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter an amount';
                          if ((double.tryParse(v) ?? 0) <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Billing cycle',
                      child: _CycleSelector(
                        selected: _cycle,
                        onChanged: (c) => setState(() => _cycle = c),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Billing day',
                      child: _BillingDayRow(
                        cycle: _cycle,
                        billingDay: _billingDay,
                        label: _billingDayLabel,
                        onDayChanged: (d) => setState(() => _billingDay = d),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPreviewCard(),
                    const SizedBox(height: 16),
                    if (_generatedLink != null) ...[
                      _buildField(
                        label: 'Payment link',
                        hint:
                            'Share this once with each subscriber — they\'ll be charged automatically after.',
                        child: _LinkRow(link: _generatedLink!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildCTAs(),
                    const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: kWhite, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Create a plan',
              style: TextStyle(
                  color: kWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildField(
      {required String label, String? hint, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kLabelStyle),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint,
              style: const TextStyle(color: kSubText, fontSize: 11)),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Plan preview', style: kLabelStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What subscribers will see',
                  style: TextStyle(color: kSubText, fontSize: 11)),
              const SizedBox(height: 10),
              Text(_previewName,
                  style: const TextStyle(
                      color: kWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              const Text('Your business · Provider',
                  style: TextStyle(color: kSubText, fontSize: 12)),
              const SizedBox(height: 8),
              Text(_previewAmount,
                  style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 22,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _cycle.billedLabel,
                  style: const TextStyle(color: kWhite, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCTAs() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _loading ? null : () => _savePlan(shareAfter: true),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: kWhite, strokeWidth: 2),
                )
              : const Text('Save plan and share link'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _loading ? null : () => _savePlan(shareAfter: false),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            foregroundColor: kNavy,
            side: const BorderSide(color: kBorderC, width: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save plan only'),
        ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _CycleSelector extends StatelessWidget {
  final BillingCycle selected;
  final ValueChanged<BillingCycle> onChanged;
  const _CycleSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.5,
      children: BillingCycle.values.map((c) {
        final isSelected = selected == c;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? kNavy : kWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? kNavy : kBorderC, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              c.label,
              style: TextStyle(
                color: isSelected ? kWhite : kSubText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BillingDayRow extends StatelessWidget {
  final BillingCycle cycle;
  final int billingDay;
  final String label;
  final ValueChanged<int> onDayChanged;

  const _BillingDayRow({
    required this.cycle,
    required this.billingDay,
    required this.label,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showPicker =
        cycle == BillingCycle.monthly || cycle == BillingCycle.quarterly;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderC, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: kNavy, fontSize: 13)),
          ),
          if (showPicker)
            DropdownButton<int>(
              value: billingDay,
              underline: const SizedBox(),
              isDense: true,
              style: const TextStyle(
                  color: kNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              items: [1, 5, 10, 15, 20, 25, 28].map((d) {
                final suffixes = {1: 'st', 2: 'nd', 3: 'rd'};
                final suffix = suffixes[d] ?? 'th';
                return DropdownMenuItem(
                    value: d, child: Text('$d$suffix'));
              }).toList(),
              onChanged: (v) {
                if (v != null) onDayChanged(v);
              },
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String link;
  const _LinkRow({required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderC, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(link,
                style:
                    const TextStyle(color: kSubText, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied')),
              );
            },
            child: const Icon(Icons.copy_outlined,
                color: kEmeraldDk, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String link;
  const _ShareSheet({required this.link});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Plan created',
              style: TextStyle(
                  color: kNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text(
            'Share this link once with each subscriber. They pay once and get charged automatically every cycle.',
            style: TextStyle(color: kSubText, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          _LinkRow(link: link),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShareBtn(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366), size: 24),
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    // TODO: Uri.launch whatsapp://send?text=link
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareBtn(
                  icon: const Icon(Icons.sms_outlined, color: kNavy, size: 24),
                  label: 'SMS',
                  color: kNavy,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareBtn(
                  icon: const Icon(Icons.share_outlined, color: kSubText, size: 24),
                  label: 'More',
                  color: kSubText,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn(
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