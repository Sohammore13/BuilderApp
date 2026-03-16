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

  void _viewImage(String url) {
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
        body: Center(child: InteractiveViewer(child: Image.network(url))),
      ),
    ));
  }

  Future<void> _viewPdf(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF'), backgroundColor: AppColors.error),
        );
      }
    }
  }

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

        final docs = snapshot.data?.docs ?? [];

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
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final imageUrl = data['requestImageURL'] as String?;
            final pdfUrl = data['purchaseOrderPdfURL'] as String?;
            final engineerName = data['uploadedByName'] ?? 'Unknown Engineer';
            final status = data['status'] as String? ?? 'pending_quotation';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final statusColor = _getStatusColor(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      GestureDetector(
                        onTap: () => _viewImage(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                      )
                    else 
                      Container(
                        width: 80, height: 80, 
                        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.image_not_supported, color: AppColors.onSurfaceMuted),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(engineerName, style: AppTextStyles.h4),
                          if (createdAt != null)
                            Text(DateFormat('MMM dd, yyyy').format(createdAt), style: AppTextStyles.caption),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(status.replaceAll('_', ' ').toUpperCase(), 
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          if (pdfUrl != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _viewPdf(pdfUrl),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('View PDF'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
