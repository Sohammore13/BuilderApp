import 'package:flutter/material.dart';
import '../../constants.dart';
import 'engineer_attendance_tab.dart';
import 'engineer_announcements_tab.dart';
import 'engineer_material_requests_tab.dart'; // [ADDED]

class EngineerSiteDetailScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const EngineerSiteDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // [CHANGED] 2 to 3
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
<<<<<<< Updated upstream
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 18),
=======
                  color: AppColors.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: const Icon(Icons.location_on_outlined, color: AppColors.onPrimary, size: 18),
>>>>>>> Stashed changes
              ),
              const SizedBox(width: AppSpacing.s),
              Flexible(
                child: Text(
                  siteName,
                  style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
<<<<<<< Updated upstream
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
=======
            labelStyle: AppTextStyles.label.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTextStyles.caption.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.6),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
>>>>>>> Stashed changes
            tabs: const [
              Tab(text: 'Attendance'),
              Tab(text: 'Announcements'),
              Tab(text: 'Materials'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EngineerAttendanceTab(siteId: siteId),
            EngineerAnnouncementsTab(siteId: siteId),
            EngineerMaterialRequestsTab(siteId: siteId), // [ADDED]
          ],
        ),
      ),
    );
  }
}
