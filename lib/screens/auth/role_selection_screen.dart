import 'package:flutter/material.dart';
import '../../constants.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Image.asset('assets/images/logo.jpg', width: 160),
                    const SizedBox(height: AppSpacing.m),
                    Text('Select Your Role', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Choose how you want to sign in',
                      style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Column(
                  children: [
                    _RoleCard(
                      icon: Icons.manage_accounts,
                      title: 'Owner',
                      subtitle: 'Approve quotations & view all sites',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(role: kRoleOwner),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _RoleCard(
                      icon: Icons.business_center,
                      title: 'Manager',
                      subtitle: 'Manage sites, team & announcements',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(role: kRoleManager),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _RoleCard(
                      icon: Icons.engineering,
                      title: 'Site Engineer',
                      subtitle: 'Mark attendance & submit requirements',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(role: kRoleSiteEngineer),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _RoleCard(
                      icon: Icons.receipt_long,
                      title: 'Purchase Team',
                      subtitle: 'Upload quotations & manage orders',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(role: kRolePurchaseTeam),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

