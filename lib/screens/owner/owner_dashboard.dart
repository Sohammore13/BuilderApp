import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/site_model.dart';
import '../../services/auth_service.dart';
import 'owner_site_detail.dart';
import 'owner_purchase_orders_tab.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = FirestoreService();

    final _pages = [
      // Tab 1: Purchase Approvals (Global)
      const OwnerPurchaseOrdersTab(), // No siteId needed, it's global now
      // Tab 2: View Sites (Read Only)
      _ViewSitesTab(firestoreService: firestoreService, uid: uid),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await AuthService().signOut(),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'View Sites',
          ),
        ],
      ),
    );
  }
}

class _ViewSitesTab extends StatelessWidget {
  final FirestoreService firestoreService;
  final String uid;

  const _ViewSitesTab({required this.firestoreService, required this.uid});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning.withValues(alpha: 0.1), AppColors.warning.withValues(alpha: 0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
<<<<<<< Updated upstream
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
=======
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.15),
              ),
>>>>>>> Stashed changes
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding - 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
<<<<<<< Updated upstream
                  child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.warning, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner View', style: AppTextStyles.h3.copyWith(color: AppColors.warning)),
                    const SizedBox(height: 2),
                    Text('Read-only access to all sites', style: AppTextStyles.caption),
                  ],
=======
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.warning,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owner View',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Read-only access to all sites',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
>>>>>>> Stashed changes
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'All Sites'),
          StreamBuilder<List<SiteModel>>(
            stream: firestoreService.streamSitesForOwner(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Error loading sites', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                      ],
                    ),
                  ),
                );
              }

              final sites = snapshot.data ?? [];
              if (sites.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.business_outlined, size: 48, color: AppColors.onSurfaceMuted),
                        const SizedBox(height: 12),
                        Text('No sites created by managers yet.', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: sites.map((site) => _SiteCard(site: site)).toList(),
              );
            },
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
              builder: (_) => OwnerSiteDetailScreen(siteId: site.siteId, siteName: site.siteName),
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
<<<<<<< Updated upstream
                child: const Icon(Icons.location_city, color: AppColors.primary, size: 24),
=======
                child: const Icon(
                  Icons.location_city,
                  color: AppColors.primary,
                  size: 22,
                ),
>>>>>>> Stashed changes
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
<<<<<<< Updated upstream
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Expanded(child: Text(site.location, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text('${site.assignedEngineers.length} engineers · ${site.assignedPurchaseTeam.length} purchase', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.onSurfaceMuted),
=======
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.onSurfaceMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            site.location,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.onSurfaceMuted.withValues(alpha: 0.7),
              ),
>>>>>>> Stashed changes
            ],
          ),
        ),
      ),
    );
  }
}
