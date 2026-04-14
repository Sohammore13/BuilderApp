import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/site_model.dart';
import 'engineer_site_detail.dart';

class EngineerDashboard extends StatefulWidget {
  const EngineerDashboard({super.key});

  @override
  State<EngineerDashboard> createState() => _EngineerDashboardState();
}

class _EngineerDashboardState extends State<EngineerDashboard> {
  int _refreshTick = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BuilderAppBar(title: 'Site Engineer'),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              const _EngineerBanner(),

              const SizedBox(height: AppSpacing.xxl),

              // My Sites (real-time)
              const SectionHeader(title: 'My Sites'),
              StreamBuilder<List<SiteModel>>(
                key: ValueKey(_refreshTick),
                stream: firestoreService.streamSitesForEngineer(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.error_outline,
                      message: 'Error loading sites',
                      color: AppColors.error,
                    );
                  }

                  final sites = snapshot.data ?? [];

                  if (sites.isEmpty) {
                    return _EmptyState(
                      icon: Icons.location_off_outlined,
                      message: 'No sites assigned yet.\nThe owner will assign you to a site.',
                      color: AppColors.onSurfaceMuted,
                    );
                  }

                  return Column(
                    children: sites.map((site) => _SiteCard(site: site)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _EngineerBanner extends StatelessWidget {
  const _EngineerBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding - 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            child: const Icon(Icons.engineering_outlined,
                color: AppColors.info, size: 24),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Site Engineer',
                    style: AppTextStyles.h3.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text('Manage your assigned construction sites',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final SiteModel site;
  const _SiteCard({required this.site});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EngineerSiteDetailScreen(
                siteId: site.siteId,
                siteName: site.siteName,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: const Icon(Icons.location_city,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(site.siteName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(site.location,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Assigned Engineer',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.onSurfaceMuted.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _EmptyState({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.body.copyWith(color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
