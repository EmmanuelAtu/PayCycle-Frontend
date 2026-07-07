import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/bottom_nav.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  String? _error;

  double _availableBalance = 0;
  double _totalEarned = 0;
  double _pendingClearance = 0;
  List<_Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Wallet summary and transaction history now live on separate
      // endpoints, so fetch them independently.
      final walletData = await ApiClient.getWallet();
      debugPrint('Wallet response: $walletData');
      final txList = await ApiClient.getWalletLedger();
      debugPrint('Ledger response: $txList');

      // Backend only returns `balance` (in kobo) on the wallet — there's
      // no total_earned / pending_clearance field yet. Derive what we can
      // from the ledger; pending clearance isn't tracked server-side yet,
      // so it stays 0 until that's added.
      final balanceKobo = (walletData['balance'] as num).toInt();
      _availableBalance = balanceKobo / 100;

      _transactions = (txList as List)
          .map((e) => _Transaction.fromJson(e as Map<String, dynamic>))
          .toList();

      _totalEarned = _transactions
          .where((t) => t.type == _TxType.credit)
          .fold(0.0, (sum, t) => sum + t.amount);
      _pendingClearance = 0;

      setState(() {
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Wallet load failed: $e');
      debugPrint('$st');
      setState(() {
        _loading = false;
        _error = 'Could not load wallet. Pull down to retry.';
      });
    }
  }

  String _fmt(double n) =>
      '₦${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kEmerald))
            : RefreshIndicator(
                onRefresh: _loadWallet,
                color: kEmerald,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildTopBar()),
                    SliverToBoxAdapter(child: _buildBalanceCard()),
                    SliverToBoxAdapter(child: _buildStatsRow()),
                    if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: _ErrorBanner(
                            message: _error!,
                            onRetry: _loadWallet,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Recent transactions',
                                style: TextStyle(
                                  color: kNavy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_pendingClearance > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: kWarnBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_fmt(_pendingClearance)} pending',
                                  style: const TextStyle(
                                    color: kWarnText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _transactions.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  8,
                                ),
                                child: _TxRow(tx: _transactions[i], fmt: _fmt),
                              ),
                              childCount: _transactions.length,
                            ),
                          ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Wallet',
              style: TextStyle(
                color: kWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: kSubText, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kNavyMid,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available balance',
              style: TextStyle(color: kSubText, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _fmt(_availableBalance),
              style: const TextStyle(
                color: kWhite,
                fontSize: 34,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _availableBalance > 0
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WithdrawScreen(
                            availableBalance: _availableBalance,
                            onSuccess: _loadWallet,
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Withdraw to bank'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kEmerald,
                  disabledBackgroundColor: kEmerald.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Total earned',
                value: _fmt(_totalEarned),
                color: const Color(0xFF4ADE80),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'Pending clearance',
                value: _fmt(_pendingClearance),
                color: const Color(0xFFFBBF24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: kSubText, size: 48),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(color: kSubText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────

enum _TxType { credit, debit }

class _Transaction {
  final String id;
  final String description;
  final double amount;
  final String date;
  final _TxType type;

  const _Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  factory _Transaction.fromJson(Map<String, dynamic> json) {
    final amountKobo = (json['amount'] as num).toDouble();
    final createdAt = DateTime.parse(json['created_at'] as String);
    return _Transaction(
      id: json['id'].toString(),
      description: (json['description'] as String?) ??
          (json['reference'] as String?) ??
          'Wallet transaction',
      amount: amountKobo / 100, // kobo → naira
      date: _formatDate(createdAt),
      type: json['type'] == 'credit' ? _TxType.credit : _TxType.debit,
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kSubText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final _Transaction tx;
  final String Function(double) fmt;
  const _TxRow({required this.tx, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == _TxType.credit;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderC, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCredit ? kEmeraldLt : kFailBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? kEmeraldDk : kFailText,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    color: kNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.date,
                  style: const TextStyle(color: kSubText, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}${fmt(tx.amount)}',
            style: TextStyle(
              color: isCredit ? kEmeraldDk : kFailText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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