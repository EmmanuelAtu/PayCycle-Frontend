import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

/// Shared bottom nav bar — 4 tabs used across all main screens.
/// Pass [currentIndex] matching the tab position:
///   0 = Home, 1 = Subscribers, 2 = New Plan, 3 = My Subscriptions
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const _items = [
    (Icons.home_outlined,    Icons.home,           'Home'),
    (Icons.group_outlined,   Icons.group,          'Subscribers'),
    (Icons.add_circle_outline, Icons.add_circle,   'New plan'),
    (Icons.bookmarks_outlined, Icons.bookmarks,    'My subs'),
  ];

  static const _routes = [
    '/dashboard',
    '/dashboard/subscribers',
    '/dashboard/create-plan',
    '/my-subscriptions',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: kBorderC, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final (outlinedIcon, filledIcon, label) = _items[i];
            final isActive = currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (currentIndex != i) context.go(_routes[i]);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? filledIcon : outlinedIcon,
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
              ),
            );
          }),
        ),
      ),
    );
  }
}