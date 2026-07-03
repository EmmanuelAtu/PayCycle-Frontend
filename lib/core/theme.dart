import 'package:flutter/material.dart';

// ── Brand palette ──────────────────────────────────────────────
const kNavy      = Color(0xFF0B1F3A);
const kNavyMid   = Color(0xFF1A3358);
const kEmerald   = Color(0xFF00A86B);
const kEmeraldDk = Color(0xFF008055);
const kEmeraldLt = Color(0xFFE6F7F1);

const kPageBg    = Color(0xFFF4F7FA);
const kBorderC   = Color(0xFFE2E8F0);
const kSubText   = Color(0xFF8A9BB5);
const kWhite     = Color(0xFFFFFFFF);

// Status colors
const kFailBg    = Color(0xFFFDECEA);
const kFailText  = Color(0xFFA32D2D);
const kWarnBg    = Color(0xFFFFF8E6);
const kWarnText  = Color(0xFF92600A);

// ── App theme ──────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: kPageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kEmerald,
      primary: kNavy,
      secondary: kEmerald,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kNavy,
      foregroundColor: kWhite,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kWhite,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorderC, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorderC, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kEmerald, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kFailText, width: 1),
      ),
      hintStyle: const TextStyle(color: kSubText, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kEmerald,
        foregroundColor: kWhite,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        elevation: 0,
      ),
    ),
  );
}

// ── Shared text styles ─────────────────────────────────────────
const kTitleStyle = TextStyle(
  color: kWhite, fontSize: 20, fontWeight: FontWeight.w500,
);
const kSubStyle = TextStyle(
  color: kSubText, fontSize: 13,
);
const kLabelStyle = TextStyle(
  color: kNavy, fontSize: 12, fontWeight: FontWeight.w500,
);