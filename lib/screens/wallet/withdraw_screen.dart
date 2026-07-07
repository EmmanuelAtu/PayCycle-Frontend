import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class WithdrawScreen extends StatefulWidget {
  final double availableBalance;
  final VoidCallback onSuccess;

  const WithdrawScreen({
    super.key,
    required this.availableBalance,
    required this.onSuccess,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankCtrl = TextEditingController();
  final _accountNumCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  bool _loading = false;
  bool _verifying = false;
  bool _accountVerified = false;

  // Nigerian banks list
  static const _banks = [
    'Access Bank',
    'Citibank Nigeria',
    'Ecobank Nigeria',
    'Fidelity Bank',
    'First Bank of Nigeria',
    'First City Monument Bank (FCMB)',
    'Globus Bank',
    'Guaranty Trust Bank (GTBank)',
    'Heritage Bank',
    'Keystone Bank',
    'Kuda Bank',
    'Moniepoint MFB',
    'OPay',
    'Palmpay',
    'Polaris Bank',
    'Providus Bank',
    'Stanbic IBTC Bank',
    'Standard Chartered Bank',
    'Sterling Bank',
    'SunTrust Bank',
    'Titan Bank',
    'Union Bank of Nigeria',
    'United Bank for Africa (UBA)',
    'Unity Bank',
    'Wema Bank',
    'Zenith Bank',
  ];

  String? _selectedBank;

  @override
  void dispose() {
    _bankCtrl.dispose();
    _accountNumCtrl.dispose();
    _accountNameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(double n) => '₦${n.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  /// Called when account number reaches 10 digits — verifies with backend
  Future<void> _verifyAccount() async {
    if (_accountNumCtrl.text.length != 10 || _selectedBank == null) return;
    setState(() { _verifying = true; _accountVerified = false; });

    try {
      // PLACEHOLDER — replace with:
      // await ApiClient.verifyAccount(
      //   accountNumber: _accountNumCtrl.text,
      //   bankName: _selectedBank!,
      // ).then((data) => _accountNameCtrl.text = data['account_name'] as String);
      await Future.delayed(const Duration(milliseconds: 900));
      _accountNameCtrl.text = 'Ezeugbana Prince Franklyn'; // stub
      setState(() { _accountVerified = true; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not verify account. Check the number and try again.'),
          backgroundColor: kFailText,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accountVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your account number first.')),
      );
      return;
    }

    final amount = double.parse(_amountCtrl.text.trim());
    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount exceeds available balance of ${_fmt(widget.availableBalance)}.'),
          backgroundColor: kFailText,
        ),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm withdrawal',
            style: TextStyle(
                color: kNavy, fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text(
          'Send ${_fmt(amount)} to ${_accountNameCtrl.text} (${_selectedBank ?? ''})?\n\nThis cannot be undone.',
          style: const TextStyle(color: kSubText, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: kSubText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw',
                style: TextStyle(
                    color: kEmerald, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _loading = true);

    try {
      // PLACEHOLDER — replace with:
      // await ApiClient.withdraw(
      //   amountKobo: amount.toInt(), // plain Naira — backend handles as-is
      //   bankName: _selectedBank!,
      //   accountNumber: _accountNumCtrl.text,
      //   accountName: _accountNameCtrl.text,
      // );
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;
      widget.onSuccess(); // refresh wallet balance
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_fmt(amount)} withdrawal initiated successfully.'),
          backgroundColor: kEmeraldDk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal failed. Please try again.'),
          backgroundColor: kFailText,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvailableBalance(),
                      const SizedBox(height: 20),

                      // Bank name dropdown
                      const Text('Bank name', style: kLabelStyle),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kWhite,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: kBorderC, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: kBorderC, width: 0.5),
                          ),
                        ),
                        hint: const Text('Select bank',
                            style: TextStyle(color: kSubText, fontSize: 14)),
                        items: _banks
                            .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBank = val;
                            _accountVerified = false;
                            _accountNameCtrl.clear();
                          });
                          _verifyAccount();
                        },
                        validator: (v) =>
                            v == null ? 'Select your bank' : null,
                      ),
                      const SizedBox(height: 14),

                      // Account number
                      const Text('Account number', style: kLabelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _accountNumCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: '0123456789',
                          counterText: '',
                          suffixIcon: _verifying
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: kEmerald),
                                  ),
                                )
                              : _accountVerified
                                  ? const Icon(Icons.check_circle_outline,
                                      color: kEmerald, size: 20)
                                  : null,
                        ),
                        onChanged: (v) {
                          setState(() {
                            _accountVerified = false;
                            _accountNameCtrl.clear();
                          });
                          if (v.length == 10) _verifyAccount();
                        },
                        validator: (v) {
                          if (v == null || v.length != 10) {
                            return 'Enter a 10-digit account number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Account name — auto-filled after verification
                      const Text('Account name', style: kLabelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _accountNameCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Auto-filled after verification',
                          filled: true,
                          fillColor: _accountVerified
                              ? kEmeraldLt
                              : kWhite,
                        ),
                        style: TextStyle(
                          color: _accountVerified ? kEmeraldDk : kSubText,
                          fontWeight: _accountVerified
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Account not verified yet'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Amount
                      const Text('Amount to withdraw', style: kLabelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
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
                          hintText: '50000',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter an amount';
                          }
                          final amt = double.tryParse(v) ?? 0;
                          if (amt <= 0) return 'Enter a valid amount';
                          if (amt > widget.availableBalance) {
                            return 'Exceeds available balance of ${_fmt(widget.availableBalance)}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Quick amount chips
                      _buildAmountChips(),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _loading ? null : _handleWithdraw,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: kWhite, strokeWidth: 2),
                              )
                            : const Text('Withdraw'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Withdrawals are processed within 24 hours. A transaction fee may apply.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kSubText, fontSize: 11, height: 1.5),
                      ),
                    ],
                  ),
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
          const Text('Withdraw to bank',
              style: TextStyle(
                  color: kWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAvailableBalance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available balance',
                    style: TextStyle(color: kSubText, fontSize: 11)),
                SizedBox(height: 4),
              ],
            ),
          ),
          Text(
            _fmt(widget.availableBalance),
            style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 20,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChips() {
    final suggestions = [5000, 10000, 50000, 100000]
        .where((v) => v <= widget.availableBalance)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: suggestions.map((v) {
        return GestureDetector(
          onTap: () => setState(() =>
              _amountCtrl.text = v.toString()),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderC, width: 0.5),
            ),
            child: Text(
              _fmt(v.toDouble()),
              style: const TextStyle(
                  color: kNavy,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }
}