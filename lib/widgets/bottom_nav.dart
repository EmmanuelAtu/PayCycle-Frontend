import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

/// Shared bottom nav bar — 5 tabs with a floating center FAB for New Plan.
/// Pass [currentIndex] matching the tab position:
///   0 = Home, 1 = Subscribers, 2 = New Plan (FAB), 3 = Wallet, 4 = My Subs
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    '/dashboard',
    '/dashboard/subscribers',
    '/dashboard/create-plan',
    '/wallet',
    '/my-subscriptions',
  ];

  void _onTap(BuildContext context, int index) {
    if (currentIndex == index) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: kBorderC, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
              _NavItem(
                icon: Icons.group_outlined,
                activeIcon: Icons.group,
                label: 'Subscribers',
                isActive: currentIndex == 1,
                onTap: () => _onTap(context, 1),
              ),

              // ── Center FAB ──────────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTap(context, 2),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: 8,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: kEmerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: kWhite, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: kEmerald.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: kWhite, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: 'Wallet',
                isActive: currentIndex == 3,
                onTap: () => _onTap(context, 3),
              ),
              _NavItem(
                icon: Icons.bookmarks_outlined,
                activeIcon: Icons.bookmarks,
                label: 'My subs',
                isActive: currentIndex == 4,
                onTap: () => _onTap(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kEmeraldDk : kSubText,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? kEmeraldDk : kSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}