import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const primary = Color(0xFF3D5CFF); // Sign Up / Action Blue
  static const background = Color(0xFFFFFFFF); // Default white bg

  // Text Colors
  static const textHeading = Color(0xFF1F1F39); // Headings (e.g. titles)
  static const textBody = Color(0xFF858597); // Body / Subtext
  static const textGray = Color(0xFF6B6B6B); // Generic gray

  // Component Colors
  static const sectionHeaderBg = Color(0xFFF0F0F2); // "Sign Up" / "Log In" header bg
  static const navInactive = Color(0xFFF4F3FD); // Inactive nav icons
  static const chipInactiveBg = Color(0xFFF5F5F5); // Inactive filter chips
  static const border = Color(0xFFE5E7EB); // Input border gray
}

class AppTextStyles {
  static const heading = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
  );

  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
  );

  static const button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
}