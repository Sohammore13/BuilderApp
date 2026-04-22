import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/site_engineer/engineer_dashboard.dart';
import 'screens/purchase_team/purchase_dashboard.dart';
import 'screens/splash_screen.dart';

// Global navigator key — lets AuthWrapper navigate imperatively from the stream
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Persist auth across browser tab closes on web
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  runApp(const BuilderApp());
}

class BuilderApp extends StatelessWidget {
  const BuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSS developers',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.success,
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
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          indicatorColor: AppColors.primary,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryTint,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.onSurfaceMuted);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              );
            }
            return AppTextStyles.label.copyWith(color: AppColors.onSurfaceMuted);
          }),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTextStyles.button,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
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
      home: const SplashScreen(),
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

    // ── Signed out → Role selection (clear entire back stack) ──────────────
    if (user == null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
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
            Image.asset(
              'assets/images/logo.jpg',
              width: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
