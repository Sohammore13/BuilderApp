import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';

class OwnerAnnouncementsTab extends StatefulWidget {
  final String siteId;
  const OwnerAnnouncementsTab({super.key, required this.siteId});

  @override
  State<OwnerAnnouncementsTab> createState() => _OwnerAnnouncementsTabState();
}

class _OwnerAnnouncementsTabState extends State<OwnerAnnouncementsTab> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamAnnouncements(widget.siteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load announcements',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign_outlined, size: 48, color: AppColors.onSurfaceMuted),
                const SizedBox(height: 12),
                Text('No announcements yet',
                    style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final message = data['message'] as String? ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final timeStr = createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                : 'Just now';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadiusSm),
                          ),
                          child: const Icon(Icons.campaign_outlined,
                              size: 16, color: AppColors.warning),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text('Owner Update',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Text(timeStr,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(message,
                        style: AppTextStyles.body.copyWith(height: 1.4)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
