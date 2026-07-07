import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'package:pay_cycle/widgets/bottom_nav.dart';

/// "My subscriptions" — shows plans this user has subscribed to as a
/// customer (as opposed to plans they created as a provider).
///
/// STATUS: not wired to the backend yet. The backend can look up
/// subscriptions by phone (`GET /customers/{phone}/subscriptions`), but
/// that response (`SubscriberOut`) only has { id, customer, plan_id,
/// status, next_billing_date } — no plan name, amount, cycle, or
/// provider name. Fetching those details via `GET /plans/{plan_id}`
/// doesn't work either, since that route is locked to the plan's own
/// owner (`provider_id == current_user.id`) — so a subscriber can't
/// look up details of a plan they don't own.
///
/// Once the backend adds an endpoint that returns full plan + provider
/// details alongside subscription status (e.g. a richer
/// `/customers/{phone}/subscriptions` response, or a dedicated
/// `/my-subscriptions` route for the logged-in user), swap the
/// `_ComingSoon` widget below for a real fetch + list.
class MySubscriptionsScreen extends StatelessWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Expanded(child: _ComingSoon()),
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
          Text(
            'My subscriptions',
            style: TextStyle(
              color: kWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kEmeraldLt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.hourglass_top_outlined,
                color: kEmeraldDk,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coming soon',
              style: TextStyle(
                color: kNavy,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We're still building support for tracking plans you've "
              'subscribed to as a customer. Check back soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kSubText, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}