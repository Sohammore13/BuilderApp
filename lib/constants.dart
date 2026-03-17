// App-wide constants for the Builder App.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Owner configuration
// ---------------------------------------------------------------------------
// IMPORTANT: Replace the placeholder below with the actual Firebase UID of
// the pre-created Owner account before releasing the app.
const String kOwnerUID = 'X7UjcFVXxLdfakc467oMDIxKmvM2';
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
