import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

/// Opened when a subscriber taps a PayCycle payment link.
/// Route: /pay/:token
///
/// Flow:
///   1. Fetch plan details from GET /pay/:token
///   2. Show plan summary to subscriber
///   3. On "Pay now" → load Nomba Checkout in a WebView
///   4. Detect checkout completion via URL redirect and close WebView
class PayScreen extends StatefulWidget {
  final String token;
  const PayScreen({super.key, required this.token});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  bool _loadingDetails = true;
  bool _showWebView = false;
  String? _error;

  // Populated from GET /pay/:token
  String _planName = '';
  String _providerName = '';
  double _amount = 0;
  String _cycle = '';
  String _checkoutUrl = ''; // returned by backend when checkout session is created

  @override
  void initState() {
    super.initState();
    _fetchPlanDetails();
  }

  Future<void> _fetchPlanDetails() async {
    try {
      // PLACEHOLDER — replace stub with:
      // final data = await ApiClient.getPaymentDetails(widget.token);
      await Future.delayed(const Duration(milliseconds: 600));
      final data = {
        'plan_name': 'Math lessons',
        'provider_name': 'Bola Adeyemi',
        'amount': 15000.0,
        'cycle': 'Monthly',
      };

      setState(() {
        _planName = data['plan_name'] as String;
        _providerName = data['provider_name'] as String;
        _amount = data['amount'] as double;
        _cycle = data['cycle'] as String;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load payment details. Check your link and try again.';
        _loadingDetails = false;
      });
    }
  }

  Future<void> _startCheckout() async {
    setState(() => _loadingDetails = true);
    try {
      // PLACEHOLDER — replace stub with:
      // final data = await ApiClient.post('/pay/${widget.token}/initiate');
      // _checkoutUrl = data['checkout_url'];
      await Future.delayed(const Duration(milliseconds: 500));
      _checkoutUrl = 'https://checkout.nomba.com/stub-session'; // stub

      setState(() {
        _loadingDetails = false;
        _showWebView = true;
      });
    } catch (e) {
      setState(() => _loadingDetails = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start checkout. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView) return _CheckoutWebView(
      checkoutUrl: _checkoutUrl,
      onSuccess: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! You are now subscribed.'),
            backgroundColor: kEmeraldDk,
          ),
        );
      },
      onClose: () => setState(() => _showWebView = false),
    );

    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: _loadingDetails
            ? const Center(child: CircularProgressIndicator(color: kEmerald))
            : _error != null
                ? _ErrorView(message: _error!)
                : _buildPayView(),
      ),
    );
  }

  Widget _buildPayView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // PayCycle logo mark
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.currency_exchange,
                  color: kWhite, size: 28),
            ),
          ),
          const SizedBox(height: 24),

          // Plan card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kNavy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_planName,
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_providerName,
                    style: const TextStyle(
                        color: kSubText, fontSize: 13)),
                const SizedBox(height: 16),
                Text(
                  '₦${_amount.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]},',
                      )}',
                  style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 28,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Billed $_cycle'.toLowerCase(),
                    style: const TextStyle(color: kWhite, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // How it works
          _InfoRow(
            icon: Icons.lock_outline,
            text: 'Your card details are encrypted and stored securely via Nomba.',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.refresh,
            text: 'You will be charged $_cycle automatically. Cancel anytime.',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.notifications_outlined,
            text: 'You will receive an SMS or WhatsApp alert before each charge.',
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: _startCheckout,
            child: const Text('Pay and subscribe'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Secured by Nomba · CBN licensed',
              style: TextStyle(color: kSubText, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checkout WebView ───────────────────────────────────────────

class _CheckoutWebView extends StatefulWidget {
  final String checkoutUrl;
  final VoidCallback onSuccess;
  final VoidCallback onClose;

  const _CheckoutWebView({
    required this.checkoutUrl,
    required this.onSuccess,
    required this.onClose,
  });

  @override
  State<_CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<_CheckoutWebView> {
  late final WebViewController _controller;
  bool _webLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _webLoading = false),
          onNavigationRequest: (req) {
            // PLACEHOLDER — detect Nomba's redirect URL on payment success
            // Update this URL to match what your backend sets as the return URL
            if (req.url.contains('paycycle.app/success')) {
              widget.onSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('Complete payment'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: kWhite),
          onPressed: widget.onClose,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_webLoading)
            const Center(
              child: CircularProgressIndicator(color: kEmerald),
            ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kEmerald, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: kSubText, fontSize: 12, height: 1.5)),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, color: kSubText, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kSubText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}