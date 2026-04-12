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
// Color palette  (Deep Navy + Safety Orange for a commercial look)
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE53935);
  static const Color primaryLight = Color(0xFFEF5350);
  static const Color primaryDark = Color(0xFFC62828);
  static const Color primaryTint = Color(0xFFFFEBEE);
  static const Color accent = Color(0xFF1A1A1A);
  static const Color accentLight = Color(0xFF37474F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceMuted = Color(0xFF78909C);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color divider = Color(0xFFEEEEEE);
}

// ---------------------------------------------------------------------------
// Text styles
// ---------------------------------------------------------------------------
class AppTextStyles {
  AppTextStyles._();

  static TextStyle h1 = GoogleFonts.raleway(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -1.0,
  );

  static TextStyle h2 = GoogleFonts.raleway(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  static TextStyle h3 = GoogleFonts.raleway(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle h4 = GoogleFonts.raleway(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle bodyLg = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static TextStyle body = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceMuted,
  );

  static TextStyle label = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0.5,
  );
  
  static TextStyle button = GoogleFonts.raleway(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}
<<<<<<< Updated upstream
=======

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
>>>>>>> Stashed changes
