import 'package:flutter/material.dart';
import '../../constants.dart';
import 'purchase_orders_tab.dart';
import 'purchase_announcements_tab.dart';
import 'purchase_attendance_tab.dart';

class PurchaseSiteDetailScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const PurchaseSiteDetailScreen({
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
                    colors: [AppColors.success, Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 18),
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
            labelColor: AppColors.success,
            unselectedLabelColor: AppColors.onSurfaceMuted,
            indicatorColor: AppColors.success,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTextStyles.caption.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Requirements'),
              Tab(text: 'Announcements'),
              Tab(text: 'Attendance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PurchaseOrdersTab(siteId: siteId),
            PurchaseAnnouncementsTab(siteId: siteId),
            PurchaseAttendanceTab(siteId: siteId),
          ],
        ),
      ),
    );
  }
}
