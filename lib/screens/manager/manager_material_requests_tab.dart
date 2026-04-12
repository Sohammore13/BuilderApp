import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
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

  Future<void> _viewFile(String url) async {
    final uri = Uri.parse(url);
    if (url.toLowerCase().endsWith('.pdf') || url.contains('/raw/upload')) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF. Please check your browser.')),
          );
        }
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text('Failed to load image', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
    }
  }

  void _viewImage(String url) => _viewFile(url);


  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_quotation': return Colors.blue;
      case 'pending_approval': return Colors.orange;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamMaterialRequests(widget.siteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
        }

        final docs = (snapshot.data?.docs ?? []).toList();
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.onSurfaceMuted),
                const SizedBox(height: 12),
                Text('No material requests for this site', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final imageUrl = data['requestImageURL'] as String?;
            final pdfUrl = data['purchaseOrderPdfURL'] as String?;
            final engineerName = data['uploadedByName'] ?? 'Unknown Engineer';
            final status = data['status'] as String? ?? 'pending_quotation';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final statusColor = _getStatusColor(status);

<<<<<<< Updated upstream
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.divider),
=======
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
>>>>>>> Stashed changes
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      GestureDetector(
                        onTap: () => _viewImage(imageUrl),
                        child: ClipRRect(
<<<<<<< Updated upstream
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
=======
                          borderRadius:
                              BorderRadius.circular(AppSpacing.borderRadius),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.divider
                                      .withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadius),
                            ),
                            child: Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 80,
                                height: 80,
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.05),
                                child: const Icon(Icons.broken_image,
                                    color: AppColors.onSurfaceMuted),
                              ),
                            ),
                          ),
>>>>>>> Stashed changes
                        ),
                      )
                    else 
                      Container(
<<<<<<< Updated upstream
                        width: 80, height: 80, 
                        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.image_not_supported, color: AppColors.onSurfaceMuted),
=======
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.onSurface.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.borderRadius),
                          border: Border.all(
                              color:
                                  AppColors.divider.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.onSurfaceMuted,
                          size: 24,
                        ),
>>>>>>> Stashed changes
                      ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(engineerName,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.bold)),
                          if (createdAt != null)
<<<<<<< Updated upstream
                            Text(DateFormat('MMM dd, yyyy').format(createdAt), style: AppTextStyles.caption),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(status.replaceAll('_', ' ').toUpperCase(), 
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          if (data['quotationNote'] != null && (data['quotationNote'] as String).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Note: ${data['quotationNote']}', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
=======
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                DateFormat('MMM dd, yyyy • hh:mm a')
                                    .format(createdAt),
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.onSurfaceMuted),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _getStatusColor(status)
                                      .withValues(alpha: 0.2)),
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
                          ),
                          if (data['quotationNote'] != null &&
                              (data['quotationNote'] as String)
                                  .isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusSm),
                              ),
                              child: Text(
                                'Note: ${data['quotationNote']}',
                                style: AppTextStyles.caption.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color:
                                      AppColors.onSurface.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ),
>>>>>>> Stashed changes
                          ],
                          if (pdfUrl != null) ...[
                            const SizedBox(height: AppSpacing.s),
                            TextButton.icon(
                              onPressed: () => _viewFile(pdfUrl),
                              icon: const Icon(Icons.document_scanner_outlined,
                                  size: 16),
                              label: const Text('View Quotation'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.05),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.borderRadiusSm)),
                                textStyle: AppTextStyles.caption
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
