import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';

class OwnerPurchaseOrdersTab extends StatefulWidget {
  const OwnerPurchaseOrdersTab({super.key});

  @override
  State<OwnerPurchaseOrdersTab> createState() => _OwnerPurchaseOrdersTabState();
}

class _OwnerPurchaseOrdersTabState extends State<OwnerPurchaseOrdersTab> {
  final _firestoreService = FirestoreService();
  final Map<String, String> _userNameCache = {};
  final Map<String, String> _siteNameCache = {};

  Future<String> _getUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    final user = await _firestoreService.getUser(uid);
    final name = user?.name ?? uid;
    _userNameCache[uid] = name;
    return name;
  }

  Future<String> _getSiteName(String siteId) async {
    if (_siteNameCache.containsKey(siteId)) return _siteNameCache[siteId]!;
    final site = await _firestoreService.getSite(siteId);
    final name = site?.siteName ?? 'Unknown Site';
    _siteNameCache[siteId] = name;
    return name;
  }

  Future<void> _updateStatus(String siteId, String orderId, String status) async {
    try {
      await _firestoreService.updateOrderStatus(
        siteId: siteId,
        orderId: orderId,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${status == 'approved' ? 'approved' : 'rejected'}'),
            backgroundColor: status == 'approved' ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showActionDialog(String siteId, String orderId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(data['itemName'] ?? 'Purchase Order',
            style: const TextStyle(color: AppColors.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Quantity', '${data['quantity']}'),
            _detailRow('Est. Cost', '₹${data['estimatedCost']}'),
            if ((data['notes'] as String?)?.isNotEmpty == true)
              _detailRow('Notes', data['notes']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateStatus(siteId, orderId, 'rejected');
            },
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateStatus(siteId, orderId, 'approved');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

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
      stream: _firestoreService.streamAllPendingPurchaseOrders(),
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
                const Icon(Icons.fact_check_outlined, size: 48, color: AppColors.onSurfaceMuted),
                const SizedBox(height: 12),
                Text('No pending approvals across any sites',
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
            final siteId = doc.reference.parent.parent!.id;
            
            final status = data['status'] as String? ?? 'pending';
            final itemName = data['itemName'] as String? ?? '';
            final quantity = data['quantity'] ?? 0;
            final cost = data['estimatedCost'] ?? 0;
            final submittedBy = data['submittedBy'] as String? ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: status == 'pending'
                    ? () => _showActionDialog(siteId, doc.id, data)
                    : null,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getSiteName(siteId),
                              builder: (ctx, siteSnap) {
                                final sName = siteSnap.data ?? 'Loading...';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      sName,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PENDING APPROVAL',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      if (status == 'pending')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Tap to approve or reject',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
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
