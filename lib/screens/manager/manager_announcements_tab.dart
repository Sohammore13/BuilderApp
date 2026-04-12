import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';

class ManagerAnnouncementsTab extends StatefulWidget {
  final String siteId;
  const ManagerAnnouncementsTab({super.key, required this.siteId});

  @override
  State<ManagerAnnouncementsTab> createState() => _ManagerAnnouncementsTabState();
}

class _ManagerAnnouncementsTabState extends State<ManagerAnnouncementsTab> {
  final _controller = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _posting = false;

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _posting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _firestoreService.postAnnouncement(
        siteId: widget.siteId,
        message: text,
        postedBy: uid,
      );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _delete(String announcementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Announcement', style: TextStyle(color: AppColors.onSurface)),
        content: const Text('Are you sure you want to delete this announcement?',
            style: TextStyle(color: AppColors.onSurfaceMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteAnnouncement(
        siteId: widget.siteId,
        announcementId: announcementId,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compose area
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 2,
                  minLines: 1,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share an update...',
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              _posting
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    )
                  : PrimaryButton(
                      onPressed: _post,
                      icon: Icons.send,
                      label: '',
                      isFullWidth: false,
                      height: 44,
                    ),
            ],
          ),
        ),

        // Announcements list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.streamAnnouncements(widget.siteId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign_outlined, size: 48, color: AppColors.onSurfaceMuted),
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
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                                ),
                                child: const Icon(Icons.campaign_outlined, size: 16, color: AppColors.warning),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text(timeStr, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  onPressed: () => _delete(doc.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(message, style: AppTextStyles.body.copyWith(height: 1.4)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
