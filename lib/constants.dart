// App-wide constants for the Builder App.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Owner configuration
// ---------------------------------------------------------------------------
// IMPORTANT: Replace the placeholder below with the actual Firebase UID of
// the pre-created Owner account before releasing the app.
const String kOwnerUID = 'BXn7yDKDixMiGrDhwXHjYDrcMcz2';
const String kManagerUID = 'kMCReLyAE8fEqIrG1MUq3S6gnlu1';

// ---------------------------------------------------------------------------
// Firestore collection / field names
// ---------------------------------------------------------------------------
const String kUsersCollection = 'users';

const String kRoleOwner = 'owner';
const String kRoleSiteEngineer = 'site_engineer';
const String kRolePurchaseTeam = 'purchase_team';
const String kRoleManager = 'manager';

// ---------------------------------------------------------------------------
// Color palette (Slate + Green Professional Palette)
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF2F3E46); // Dark Blue-Grey (Slate)
  static const Color primaryLight = Color(0xFF52796F);
  static const Color primaryDark = Color(0xFF252F35);
  static const Color primaryTint = Color(0xFFE9ECEF);
  
  // Action/Functional Colors
  static const Color success = Color(0xFF1F8F5F); // Deep Green
  static const Color successSurface = Color(0xFFE6F4EA); // Light Green Tint
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  
  static const Color error = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFEE2E2);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Surface & Text Colors
  static const Color background = Color(0xFFF5F6F7); // Light Grey
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB); // Light Grey Border

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937); // Dark Grey
  static const Color onSurfaceMuted = Color(0xFF6B7280); // Muted Grey
}

// ---------------------------------------------------------------------------
// Text styles (Inter for a modern, professional look)
// ---------------------------------------------------------------------------
class AppTextStyles {
  AppTextStyles._();

  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle appBarTitle = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceMuted,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0.2,
  );
  
  static TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// ---------------------------------------------------------------------------
// Spacing & Layout
// ---------------------------------------------------------------------------
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadius = 12.0;
  static const double borderRadiusLg = 16.0;
}

class AppTone {
  final Color foreground;
  final Color background;

  const AppTone({required this.foreground, required this.background});

  Color border([double alpha = 0.18]) => foreground.withValues(alpha: alpha);
}

class AppTones {
  AppTones._();

  static const AppTone primary = AppTone(
    foreground: AppColors.primary,
    background: AppColors.primaryTint,
  );
  static const AppTone success = AppTone(
    foreground: AppColors.success,
    background: AppColors.successSurface,
  );
  static const AppTone warning = AppTone(
    foreground: AppColors.warning,
    background: AppColors.warningSurface,
  );
  static const AppTone info = AppTone(
    foreground: AppColors.info,
    background: AppColors.infoSurface,
  );
  static const AppTone danger = AppTone(
    foreground: AppColors.error,
    background: AppColors.errorSurface,
  );
}

AppTone requestStatusTone(String status) {
  switch (status) {
    case 'approved':
      return AppTones.success;
    case 'rejected':
      return AppTones.danger;
    case 'pending_approval':
      return AppTones.warning;
    case 'pending_quotation':
      return AppTones.info;
    default:
      return AppTones.primary;
  }
}

AppTone roleTone(String role) {
  switch (role) {
    case kRoleOwner:
      return AppTones.warning;
    case kRoleManager:
      return AppTones.primary;
    case kRolePurchaseTeam:
      return AppTones.success;
    case kRoleSiteEngineer:
      return AppTones.info;
    default:
      return AppTones.primary;
  }
}
