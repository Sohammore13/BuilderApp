import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import 'purchase_request_detail_screen.dart';

class PurchaseOrdersTab extends StatefulWidget {
  final String siteId;
  const PurchaseOrdersTab({super.key, required this.siteId});

  @override
  State<PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends State<PurchaseOrdersTab> {
  final FirestoreService _firestoreService = FirestoreService();
  int _refreshTick = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_refreshTick),
        stream: _firestoreService.streamMaterialRequests(widget.siteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
          }

          final allDocs = (snapshot.data?.docs ?? []).toList();
          allDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          // Split into pending actions and history
          final pendingAction = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending_quotation';
          }).toList();

          final history = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] != 'pending_quotation';
          }).toList();

          if (allDocs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    'No material requirements submitted by engineers yet.',
                    style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingAction.isNotEmpty) ...[
                Text('PENDING YOUR ACTION', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                const SizedBox(height: 12),
                ...pendingAction.map((doc) => _buildRequestCard(doc)),
                const SizedBox(height: 24),
              ],

              if (history.isNotEmpty) ...[
                Text('HISTORY', style: AppTextStyles.label),
                const SizedBox(height: 12),
                ...history.map((doc) => _buildRequestCard(doc, isHistory: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(DocumentSnapshot doc, {bool isHistory = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['requestImageURL'] as String?;
    final engineerName = data['uploadedByName'] ?? 'Unknown Engineer';
    final status = data['status'] as String? ?? 'pending';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PurchaseRequestDetailScreen(
                siteId: widget.siteId,
                requestId: doc.id,
                requestData: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                )
              else 
                const Icon(Icons.image_not_supported, size: 40),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Engineer: $engineerName', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    if (createdAt != null)
                      Text('Submitted: ${DateFormat('MMM dd, hh:mm a').format(createdAt)}', 
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending_quotation': color = Colors.blue; break;
      case 'pending_approval': color = Colors.orange; break;
      case 'approved': color = AppColors.success; break;
      case 'rejected': color = AppColors.error; break;
      default: color = AppColors.onSurfaceMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
