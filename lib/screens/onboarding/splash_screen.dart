import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  late Animation<double> _barWidth;

  @override
  void initState() {
    super.initState();

    // Status bar transparent over navy
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Animated loading bar
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _barWidth = Tween<double>(begin: 48, end: 120).animate(
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut),
    );

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    // PLACEHOLDER — on Day 2 add shared prefs check:
    // final prefs = await SharedPreferences.getInstance();
    // final seen = prefs.getBool('onboarding_done') ?? false;
    // if (seen && await ApiClient.hasToken()) {
    //   context.go('/dashboard');
    // } else if (seen) {
    //   context.go('/login');
    // } else {
    //   context.go('/onboarding');
    // }

    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kEmerald,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.currency_exchange,
                  color: kWhite,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                'PayCycle',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Set it once. Get paid on your schedule.',
                style: TextStyle(color: kSubText, fontSize: 15),
              ),
              const SizedBox(height: 48),

              // Animated loading bar
              AnimatedBuilder(
                animation: _barWidth,
                builder: (_, __) => Container(
                  width: _barWidth.value,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kEmerald,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}