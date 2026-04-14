import 'package:flutter/material.dart';
import '../../constants.dart';
import 'manager_attendance_tab.dart';
import 'manager_announcements_tab.dart';
import 'manager_material_requests_tab.dart';
import 'manager_edit_members_tab.dart';

class ManagerSiteDetailScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const ManagerSiteDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          centerTitle: true,
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
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  siteName,
                  style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            Tooltip(
              message: 'Edit Members',
              child: IconButton(
                icon: const Icon(Icons.group_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManagerEditMembersScreen(
                        siteId: siteId,
                        siteName: siteName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceMuted,
            labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTextStyles.caption.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Attendance'),
              Tab(text: 'Announcements'),
              Tab(text: 'Materials'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ManagerAttendanceTab(siteId: siteId),
            ManagerAnnouncementsTab(siteId: siteId),
            ManagerMaterialRequestsTab(siteId: siteId),
          ],
        ),
      ),
    );
  }
}
