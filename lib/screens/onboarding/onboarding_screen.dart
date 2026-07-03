import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const _slides = [
    _Slide(
      lottieAsset: 'assets/animations/finance.json',
      badgeText: 'Create a plan in 30 seconds',
      title: 'Create a recurring\npayment plan',
      body:
          'Set a name, amount, and billing cycle — daily, weekly, monthly, or quarterly. You\'re in control of the schedule.',
      illoColor: kNavy,
    ),
    _Slide(
      lottieAsset: 'assets/animations/links.json',
      badgeText: 'One link per subscriber',
      title: 'Share a link once,\nget paid forever',
      body:
          'Send your subscribers a payment link once. Their card is saved securely via Nomba — every cycle they\'re charged automatically.',
      illoColor: kNavy,
    ),
    _Slide(
      lottieAsset: 'assets/animations/analytics.json',
      badgeText: 'Live status board',
      title: 'See who paid\nand who didn\'t',
      body:
          'Track active, failed, and overdue subscribers in one screen. Retry failed charges or send a WhatsApp reminder in one tap.',
      illoColor: kNavyMid,
    ),
  ];

  void _next() {
    if (_current < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // PLACEHOLDER — Day 2: mark onboarding as seen
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('onboarding_done', true);

    context.go('/login');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Bottom area
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _current == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _current == i ? kEmerald : kBorderC,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  if (_current < _slides.length - 1)
                    Row(
                      children: [
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: kSubText,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Skip',
                              style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _next,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Next'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNavy,
                      ),
                      child: const Text('Get started'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide data ─────────────────────────────────────────────────

class _Slide {
  final String lottieAsset;
  final String badgeText;
  final String title;
  final String body;
  final Color illoColor;

  const _Slide({
    required this.lottieAsset,
    required this.badgeText,
    required this.title,
    required this.body,
    required this.illoColor,
  });
}

// ── Slide view ─────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration panel — Lottie animation on a colored backdrop
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: slide.illoColor,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Lottie.asset(
                      slide.lottieAsset,
                      fit: BoxFit.contain,
                      // PLACEHOLDER: if the file fails to load (wrong path,
                      // not declared in pubspec.yaml), show a fallback icon
                      // instead of crashing the screen.
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
                          color: kWhite,
                          size: 48,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slide.badgeText,
                      style: const TextStyle(
                          color: kWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            slide.title,
            style: const TextStyle(
              color: kNavy,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Body
          Text(
            slide.body,
            style: const TextStyle(
              color: kSubText,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}