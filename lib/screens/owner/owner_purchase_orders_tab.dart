import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';

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
    final name = user?.name ?? 'Unknown';
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

  Future<void> _updateStatus(String siteId, String requestId, String status, {String? reason}) async {
    try {
      await _firestoreService.updateMaterialRequestStatus(
        siteId: siteId,
        requestId: requestId,
        status: status,
        reviewedBy: kOwnerUID,
        rejectionReason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status == 'approved' ? 'approved' : 'rejected'}'),
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

  void _showRejectionDialog(String siteId, String requestId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          const SizedBox(width: 8),
          PrimaryButton(
            label: 'Reject',
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _updateStatus(siteId, requestId, 'rejected', reason: controller.text.trim());
            },
            color: AppColors.error,
            isFullWidth: false,
            height: 40,
          ),
        ],
      ),
    );
  }

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
      // It's an image, use the internal viewer
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
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

  void _viewImage(String url) => _viewFile(url); // Keep for compatibility if needed elsewhere


  // _viewPdf is removed because we now use images

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamAllMaterialRequests(),
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
        final pendingDocs = allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'pending_approval').toList();
        final historyDocs = allDocs.where((d) => ['approved', 'rejected'].contains((d.data() as Map<String, dynamic>)['status'])).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pendingDocs.isNotEmpty) ...[
              Text('PENDING APPROVAL', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              ...pendingDocs.map((doc) => _buildRequestCard(doc, isPending: true)),
              const SizedBox(height: 24),
            ],
            if (historyDocs.isNotEmpty) ...[
              Text('HISTORY', style: AppTextStyles.label),
              const SizedBox(height: 12),
              ...historyDocs.map((doc) => _buildRequestCard(doc, isPending: false)),
            ],
            if (allDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(child: Text('No material requests found.', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted))),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(DocumentSnapshot doc, {required bool isPending}) {
    final data = doc.data() as Map<String, dynamic>;
    final siteId = data['siteId'] ?? '';
    final imageUrl = data['requestImageURL'] as String?;
    final pdfUrl = data['purchaseOrderPdfURL'] as String?;
    final engineerName = data['uploadedByName'] ?? 'Unknown Engineer';
    final purchaseUid = data['pdfUploadedBy'] as String?;
    final status = data['status'] as String? ?? 'pending';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final rejectionReason = data['rejectionReason'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  GestureDetector(
                    onTap: () => _viewImage(imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getSiteName(siteId),
                        builder: (context, snap) => Text(snap.data ?? 'Loading...', style: AppTextStyles.h4),
                      ),
                      const SizedBox(height: 4),
                      Text('By Engineer: $engineerName', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      if (purchaseUid != null)
                        FutureBuilder<String>(
                          future: _getUserName(purchaseUid),
                          builder: (context, snap) => Text('Purchase: ${snap.data ?? '...'}', style: AppTextStyles.caption),
                        ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            if (data['quotationNote'] != null && (data['quotationNote'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Remark:', style: AppTextStyles.label.copyWith(fontSize: 11)),
                    Text(data['quotationNote'], style: AppTextStyles.body.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
            if (status == 'rejected' && rejectionReason != null) ...[
              const SizedBox(height: 10),
              Text('Rejection Reason: $rejectionReason', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (imageUrl != null)
                  Expanded(
                    child: SecondaryButton(
                      onPressed: () => _viewFile(imageUrl),
                      icon: Icons.image,
                      label: 'View Requirement',
                      isFullWidth: false,
                    ),
                  ),
                if (pdfUrl != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondaryButton(
                      onPressed: () => _viewFile(pdfUrl),
                      icon: Icons.description,
                      label: 'View Quotation',
                      isFullWidth: false,
                    ),
                  ),
                ],
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () => _updateStatus(siteId, doc.id, 'approved'),
                      label: 'Approve',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () => _showRejectionDialog(siteId, doc.id),
                      label: 'Reject',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Submitted: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved': color = AppColors.success; break;
      case 'rejected': color = AppColors.error; break;
      case 'pending_approval': color = Colors.orange; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
