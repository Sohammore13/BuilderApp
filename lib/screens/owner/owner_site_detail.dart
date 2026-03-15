import 'package:flutter/material.dart';
import '../../constants.dart';
import 'owner_attendance_tab.dart';
import 'owner_announcements_tab.dart';
import 'owner_purchase_orders_tab.dart';
import 'edit_members_screen.dart';

class OwnerSiteDetailScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const OwnerSiteDetailScreen({
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
          title: Row(
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                      builder: (_) => EditMembersScreen(
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
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.how_to_reg_outlined, size: 20), text: 'Attendance'),
              Tab(icon: Icon(Icons.campaign_outlined, size: 20), text: 'Announcements'),
              Tab(icon: Icon(Icons.receipt_long_outlined, size: 20), text: 'Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OwnerAttendanceTab(siteId: siteId),
            OwnerAnnouncementsTab(siteId: siteId),
            OwnerPurchaseOrdersTab(siteId: siteId),
          ],
        ),
      ),
    );
  }
}
