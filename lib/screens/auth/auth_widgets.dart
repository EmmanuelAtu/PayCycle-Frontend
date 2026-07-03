import 'package:flutter/material.dart';
import '../../core/theme.dart';

// ── Hero band ──────────────────────────────────────────────────
/// Navy header used on both Login and Signup screens.
class HeroBand extends StatelessWidget {
  final String title;
  final String subtitle;
  const HeroBand({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kEmerald,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.currency_exchange,
                color: kWhite, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: kTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: kSubStyle),
        ],
      ),
    );
  }
}

// ── Trust badges ───────────────────────────────────────────────
/// "Nomba secured · Encrypted" pill row shown on both auth screens.
class TrustBadges extends StatelessWidget {
  const TrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustChip(icon: Icons.shield_outlined, label: 'Nomba secured'),
        SizedBox(width: 8),
        _TrustChip(icon: Icons.lock_outline, label: 'Encrypted'),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kEmeraldLt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kEmeraldDk, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00704A),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}