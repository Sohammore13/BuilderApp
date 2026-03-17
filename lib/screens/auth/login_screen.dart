import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import 'register_screen.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, this.role = kRoleSiteEngineer});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  String get _roleLabel {
    switch (widget.role) {
      case kRoleOwner:
        return 'Owner';
      case kRoleManager:
        return 'Manager';
      case kRoleSiteEngineer:
        return 'Site Engineer';
      case kRolePurchaseTeam:
        return 'Purchase Team';
      default:
        return widget.role;
    }
  }

  bool get _canRegister =>
      widget.role == kRoleSiteEngineer || widget.role == kRolePurchaseTeam;

  Future<bool> _matchesSelectedRole(String uid) async {
    // Owner & Manager are enforced by UID shortcut (same logic as AuthWrapper).
    if (widget.role == kRoleOwner) return uid == kOwnerUID;
    if (widget.role == kRoleManager) return uid == kManagerUID;

    // Other roles are stored in Firestore user document.
    final role = await _authService.getUserRole(uid);
    return role == widget.role;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Sign in failed. Please try again.');
      }

      final ok = await _matchesSelectedRole(user.uid);
      if (!ok) {
        await _authService.signOut();
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'This account is not an ${_roleLabel.toLowerCase()} account. Please select the correct role.';
        });
        return;
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No account found with this email.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            _errorMessage = 'Incorrect email or password.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Too many attempts. Please try again later.';
            break;
          default:
            _errorMessage = e.message ?? 'Sign in failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                          ),
                          child: Text(
                            _roleLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ----------------------------------------------------------
                    // Logo + headline
                    // ----------------------------------------------------------
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.jpg',
                            width: 220,
                            fit: BoxFit.contain,  
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Construction Management Platform',
                            style: AppTextStyles.caption.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ----------------------------------------------------------
                    // Sign in label
                    // ----------------------------------------------------------
                    Text('Sign In', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back! Enter your credentials to continue.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 28),

                    // ----------------------------------------------------------
                    // Email field
                    // ----------------------------------------------------------
                    BuilderTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ----------------------------------------------------------
                    // Password field
                    // ----------------------------------------------------------
                    BuilderTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.onSurfaceMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // ----------------------------------------------------------
                    // Error message
                    // ----------------------------------------------------------
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // ----------------------------------------------------------
                    // Sign In button
                    // ----------------------------------------------------------
                    PrimaryButton(
                      label: 'Sign In',
                      onPressed: _signIn,
                      isLoading: _isLoading,
                      icon: Icons.login,
                    ),

                    const SizedBox(height: 32),

                    // ----------------------------------------------------------
                    // Register link
                    // ----------------------------------------------------------
                    if (_canRegister)
                      Center(
                        child: Column(
                          children: [
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 16),
                            Text(
                              "New to BuilderPro?",
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterScreen(role: widget.role),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text(
                                'Create an Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }
}
