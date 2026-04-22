import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'auth/role_selection_screen.dart';
import 'owner/owner_dashboard.dart';
import 'manager/manager_dashboard.dart';
import 'site_engineer/engineer_dashboard.dart';
import 'purchase_team/purchase_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for at least 2 seconds so the logo is visible
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // No one is logged in → go to role selection / login
    if (user == null) {
      _goTo(const RoleSelectionScreen());
      return;
    }

    // Owner UID shortcut (no Firestore needed)
    if (user.uid == kOwnerUID) {
      _goTo(const OwnerDashboard());
      return;
    }

    // Manager UID shortcut
    if (user.uid == kManagerUID) {
      _goTo(const ManagerDashboard());
      return;
    }

    // All other roles — fetch role from Firestore
    String? role = await AuthService().getUserRole(user.uid);

    // Retry once if role not yet written (edge case during first registration)
    if (role == null || role.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      role = await AuthService().getUserRole(user.uid);
    }

    if (!mounted) return;

    switch (role) {
      case kRoleSiteEngineer:
        _goTo(const EngineerDashboard());
        break;
      case kRolePurchaseTeam:
        _goTo(const PurchaseDashboard());
        break;
      default:
        // Unknown / missing role → let them pick again
        _goTo(const RoleSelectionScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.jpg', width: 280),
            const SizedBox(height: 24),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
