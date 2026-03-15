// App-wide constants for the Builder App.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Owner configuration
// ---------------------------------------------------------------------------
// IMPORTANT: Replace the placeholder below with the actual Firebase UID of
// the pre-created Owner account before releasing the app.
const String kOwnerUID = 'X7UjcFVXxLdfakc467oMDIxKmvM2';
const String kManagerUID = 'mIOUPGFWMNZf77nfc4LYRsprMEn2';

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

  static const Color primary = Color(0xFF0F2027);       // Deep Navy Blue
  static const Color primaryLight = Color(0xFF203A43);  // Lighter Navy
  static const Color primaryDark = Color(0xFF070F13);   // Darker Navy
  static const Color accent = Color(0xFFFF9800);        // Safety Orange / Gold
  static const Color accentLight = Color(0xFFFFB74D);
  static const Color surface = Color(0xFFFFFFFF);       // White surface
  static const Color background = Color(0xFFF8FAFC);    // Off-white / cool grey background
  static const Color card = Color(0xFFFFFFFF);          // White card surface
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF1E293B);     // Dark Slate for high readability
  static const Color onSurfaceMuted = Color(0xFF64748B); // Muted slate text
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color divider = Color(0xFFE2E8F0);
}

// ---------------------------------------------------------------------------
// Text styles
// ---------------------------------------------------------------------------
class AppTextStyles {
  AppTextStyles._();

  static TextStyle h1 = GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -1.0,
  );

  static TextStyle h2 = GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  static TextStyle h3 = GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle h4 = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
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
    letterSpacing: 0.5,
  );
  
  static TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}
