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
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              if (pendingAction.isNotEmpty) ...[
<<<<<<< Updated upstream
                Text('PENDING YOUR ACTION', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                const SizedBox(height: 12),
=======
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'PENDING ACTION',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
>>>>>>> Stashed changes
                ...pendingAction.map((doc) => _buildRequestCard(doc)),
                const SizedBox(height: AppSpacing.xxl),
              ],

              if (history.isNotEmpty) ...[
<<<<<<< Updated upstream
                Text('HISTORY', style: AppTextStyles.label),
                const SizedBox(height: 12),
                ...history.map((doc) => _buildRequestCard(doc, isHistory: true)),
=======
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('HISTORY',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface.withValues(alpha: 0.6))),
                ),
                const SizedBox(height: AppSpacing.m),
                ...history.map(
                  (doc) => _buildRequestCard(doc, isHistory: true),
                ),
>>>>>>> Stashed changes
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
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
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
<<<<<<< Updated upstream
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                )
              else 
                const Icon(Icons.image_not_supported, size: 40),
              
              const SizedBox(width: 12),
              
=======
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusSm),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withValues(alpha: 0.05),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusSm),
                  ),
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.onSurfaceMuted, size: 20),
                ),
              const SizedBox(width: AppSpacing.m),
>>>>>>> Stashed changes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(engineerName,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    if (createdAt != null)
<<<<<<< Updated upstream
                      Text('Submitted: ${DateFormat('MMM dd, hh:mm a').format(createdAt)}', 
                        style: AppTextStyles.caption),
=======
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(createdAt),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.onSurfaceMuted),
                      ),
>>>>>>> Stashed changes
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
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
<<<<<<< Updated upstream
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
=======
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _getStatusColor(status).withValues(alpha: 0.2)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending_quotation':
        return AppColors.warning;
      default:
        return AppColors.onSurfaceMuted;
    }
  }
>>>>>>> Stashed changes
}
