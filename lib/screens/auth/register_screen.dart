import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;
  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Role options — owner and manager are intentionally excluded
  late String _selectedRole;
  late bool _allowRoleChange;

  String get _roleLabel {
    switch (_selectedRole) {
      case kRoleSiteEngineer:
        return 'Site Engineer';
      case kRolePurchaseTeam:
        return 'Purchase Team';
      case kRoleOwner:
        return 'Owner';
      case kRoleManager:
        return 'Manager';
      default:
        return _selectedRole;
    }
  }

  @override
  void initState() {
    super.initState();
    _allowRoleChange = widget.role == null;
    _selectedRole = widget.role ?? kRoleSiteEngineer;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'An account already exists with this email.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'weak-password':
            _errorMessage = 'Password is too weak. Use at least 6 characters.';
            break;
          case 'invalid-role':
            _errorMessage = e.message;
            break;
          default:
            _errorMessage = e.message ?? 'Registration failed. Please try again.';
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
            Column(
              children: [
                // Back button row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Header
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.accentLight, AppColors.accent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create Account', style: AppTextStyles.h2),
                                  Text('Join BuilderPro', style: AppTextStyles.caption),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Name
                          BuilderTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'John Smith',
                            prefixIcon: Icons.badge_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Name is required';
                              if (v.trim().length < 2) return 'Name is too short';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Email
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

                          // Password
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
                              if (v.length < 6) return 'Must be at least 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          if (_allowRoleChange)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                                prefixIcon: const Icon(Icons.work_outline, color: AppColors.onSurfaceMuted, size: 20),
                                filled: true,
                                fillColor: AppColors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                              ),
                              dropdownColor: AppColors.card,
                              style: const TextStyle(color: AppColors.onSurface),
                              items: const [
                                DropdownMenuItem(
                                  value: kRoleOwner,
                                  enabled: false,
                                  child: Text('Owner (admin only)'),
                                ),
                                DropdownMenuItem(
                                  value: kRoleManager,
                                  enabled: false,
                                  child: Text('Manager (admin only)'),
                                ),
                                DropdownMenuItem(
                                  value: kRoleSiteEngineer,
                                  child: Text('Site Engineer'),
                                ),
                                DropdownMenuItem(
                                  value: kRolePurchaseTeam,
                                  child: Text('Purchase Team'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
                            )
                          else
                            Row(
                              children: [
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

                          const SizedBox(height: 12),

                          // Role info banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _allowRoleChange
                                        ? 'Owner and Manager accounts are created by the developer only.'
                                        : 'Owner accounts are created by the developer only.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
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

                          // Register button
                          PrimaryButton(
                            label: 'Create Account',
                            onPressed: _register,
                            isLoading: _isLoading,
                            icon: Icons.person_add_outlined,
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceMuted),
                              child: const Text('Already have an account? Sign In'),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }
}
