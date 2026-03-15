import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/site_engineer/engineer_dashboard.dart';
import 'screens/purchase_team/purchase_dashboard.dart';

// Global navigator key — lets AuthWrapper navigate imperatively from the stream
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BuilderApp());
}

class BuilderApp extends StatelessWidget {
  const BuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuilderPro',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.onPrimary,
          onSurface: AppColors.onSurface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: TextTheme(
          displayLarge: AppTextStyles.h1,
          displayMedium: AppTextStyles.h2,
          displaySmall: AppTextStyles.h3,
          headlineMedium: AppTextStyles.h4,
          bodyLarge: AppTextStyles.bodyLg,
          bodyMedium: AppTextStyles.body,
          labelSmall: AppTextStyles.caption,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.onPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            textStyle: AppTextStyles.button,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shadowColor: AppColors.onSurface.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/owner': (context) => const OwnerDashboard(),
        '/manager': (context) => const ManagerDashboard(),
        '/engineer': (context) => const EngineerDashboard(),
        '/purchase': (context) => const PurchaseDashboard(),
      },
      home: const AuthWrapper(),
    );
  }
}

// ---------------------------------------------------------------------------
// AuthWrapper — all navigation is driven by the Firebase auth stream.
// Login / Register screens never navigate on success; this widget handles it.
// ---------------------------------------------------------------------------
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and imperatively navigate on each event
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    // Wait one frame so the navigator is mounted before we use it
    await Future.delayed(Duration.zero);
    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    // ── Signed out → Login (clear entire back stack) ────────────────────────
    if (user == null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // ── Owner (UID shortcut, no Firestore needed) ────────────────────────────
    if (user.uid == kOwnerUID) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OwnerDashboard()),
        (route) => false,
      );
      return;
    }

    // ── Manager (UID shortcut) ───────────────────────────────────────────────
    if (user.uid == kManagerUID) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ManagerDashboard()),
        (route) => false,
      );
      return;
    }

    // ── Other roles: fetch from Firestore ────────────────────────────────────
    String? role = await AuthService().getUserRole(user.uid);

    // Edge case: auth fires before the Firestore document is written
    // (can happen during registration). Retry once after a short delay.
    if (role == null || role.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      role = await AuthService().getUserRole(user.uid);
    }

    switch (role) {
      case kRoleSiteEngineer:
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EngineerDashboard()),
          (route) => false,
        );
        break;
      case kRolePurchaseTeam:
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PurchaseDashboard()),
          (route) => false,
        );
        break;
      default:
        // No valid role — show error screen
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => _UnknownRoleScreen(uid: user.uid)),
          (route) => false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash is shown on startup while the stream resolves
    return _SplashScreen();
  }
}

// ---------------------------------------------------------------------------
// Branded splash / loading screen
// ---------------------------------------------------------------------------
class _SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentLight, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.construction, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'BuilderPro',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unknown role fallback screen
// ---------------------------------------------------------------------------
class _UnknownRoleScreen extends StatelessWidget {
  final String uid;
  const _UnknownRoleScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 64),
              const SizedBox(height: 20),
              Text(
                'Account Not Configured',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account (UID: $uid) has no role assigned. '
                'Please contact your administrator.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  onPressed: () async => await AuthService().signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
