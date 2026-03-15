import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';

class ManagerMaterialRequestsTab extends StatefulWidget {
  final String siteId;
  const ManagerMaterialRequestsTab({super.key, required this.siteId});

  @override
  State<ManagerMaterialRequestsTab> createState() => _ManagerMaterialRequestsTabState();
}

class _ManagerMaterialRequestsTabState extends State<ManagerMaterialRequestsTab> {
  final _firestoreService = FirestoreService();
  final Map<String, String> _userNameCache = {};

  Future<String> _getUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    final user = await _firestoreService.getUser(uid);
    final name = user?.name ?? uid;
    _userNameCache[uid] = name;
    return name;
  }

  // Read-only view for Manager

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamPurchaseOrders(widget.siteId),
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
                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.onSurfaceMuted),
                const SizedBox(height: 12),
                Text('No purchase orders yet',
                    style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            final itemName = data['itemName'] as String? ?? '';
            final quantity = data['quantity'] ?? 0;
            final cost = data['estimatedCost'] ?? 0;
            final submittedBy = data['submittedBy'] as String? ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            Color statusColor;
            switch (status) {
              case 'approved':
                statusColor = AppColors.success;
                break;
              case 'rejected':
                statusColor = AppColors.error;
                break;
              default:
                statusColor = AppColors.warning;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoChip(Icons.inventory_2_outlined, 'Qty: $quantity'),
                        const SizedBox(width: 10),
                        _infoChip(Icons.currency_rupee, '₹$cost'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: _getUserName(submittedBy),
                      builder: (ctx, nameSnap) {
                        final name = nameSnap.data ?? '...';
                        return Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceMuted),
                            const SizedBox(width: 4),
                            Text('By: $name', style: AppTextStyles.caption),
                            const Spacer(),
                            if (createdAt != null)
                              Text(
                                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: AppTextStyles.caption,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
