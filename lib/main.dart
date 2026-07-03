import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/api_client.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/provider/dashboard_screen.dart';
import 'screens/provider/subscribers_screen.dart';
import 'screens/provider/create_plan_screen.dart';
import 'screens/subscriptions/pay_screen.dart';
import 'screens/subscriptions/my_subscriptions_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.init(); // sets up Dio + JWT interceptor
  runApp(const PayCycleApp());
}

class PayCycleApp extends StatelessWidget {
  const PayCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PayCycle',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}

// ── Router ─────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/splash',

  // PLACEHOLDER: add redirect logic here on Day 2 when auth is wired
  // redirect: (context, state) async {
  //   final loggedIn = await ApiClient.hasToken();
  //   final onAuth = state.matchedLocation == '/login' ||
  //                  state.matchedLocation == '/signup';
  //   if (!loggedIn && !onAuth) return '/login';
  //   if (loggedIn && onAuth)  return '/dashboard';
  //   return null;
  // },

  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (_, __) => const SignupScreen(),
    ),

    // Provider routes
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'subscribers',
          builder: (_, __) => const SubscribersScreen(),
        ),
        GoRoute(
          path: 'create-plan',
          builder: (_, __) => const CreatePlanScreen(),
        ),
      ],
    ),

    // Subscriber routes
    // Deep link: paycycle.app/pay/:token → opens PayScreen
    GoRoute(
      path: '/pay/:token',
      builder: (_, state) =>
          PayScreen(token: state.pathParameters['token']!),
    ),
    // My subscriptions tab
    GoRoute(
      path: '/my-subscriptions',
      builder: (_, __) => const MySubscriptionsScreen(),
    ),
  ],
);