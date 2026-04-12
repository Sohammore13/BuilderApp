import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
<<<<<<< Updated upstream
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
=======
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.onSurface,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load image',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
>>>>>>> Stashed changes
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
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            if (pendingDocs.isNotEmpty) ...[
<<<<<<< Updated upstream
              Text('PENDING APPROVAL', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              ...pendingDocs.map((doc) => _buildRequestCard(doc, isPending: true)),
              const SizedBox(height: 24),
            ],
            if (historyDocs.isNotEmpty) ...[
              Text('HISTORY', style: AppTextStyles.label),
              const SizedBox(height: 12),
              ...historyDocs.map((doc) => _buildRequestCard(doc, isPending: false)),
=======
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'PENDING APPROVAL',
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              ...pendingDocs.map(
                (doc) => _buildRequestCard(doc, isPending: true),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
            if (historyDocs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('HISTORY',
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface.withValues(alpha: 0.6))),
              ),
              const SizedBox(height: AppSpacing.m),
              ...historyDocs.map(
                (doc) => _buildRequestCard(doc, isPending: false),
              ),
>>>>>>> Stashed changes
            ],
            if (allDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 100),
<<<<<<< Updated upstream
                child: Center(child: Text('No material requests found.', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted))),
=======
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 48, color: AppColors.onSurfaceMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No requests found.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
>>>>>>> Stashed changes
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  GestureDetector(
                    onTap: () => _viewImage(imageUrl),
<<<<<<< Updated upstream
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
=======
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusSm),
                        border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusSm),
                        child: Image.network(
                          imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
>>>>>>> Stashed changes
                    ),
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.onSurface.withValues(alpha: 0.05),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusSm),
                    ),
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.onSurfaceMuted, size: 20),
                  ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getSiteName(siteId),
<<<<<<< Updated upstream
                        builder: (context, snap) => Text(snap.data ?? 'Loading...', style: AppTextStyles.h4),
                      ),
                      const SizedBox(height: 4),
                      Text('By Engineer: $engineerName', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      if (purchaseUid != null)
                        FutureBuilder<String>(
                          future: _getUserName(purchaseUid),
                          builder: (context, snap) => Text('Purchase: ${snap.data ?? '...'}', style: AppTextStyles.caption),
=======
                        builder: (context, snap) => Text(
                          snap.data ?? '...',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Engineer: $engineerName',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (purchaseUid != null)
                        FutureBuilder<String>(
                          future: _getUserName(purchaseUid),
                          builder: (context, snap) => Text(
                            'Purchase: ${snap.data ?? '...'}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.onSurfaceMuted, fontSize: 10),
                          ),
>>>>>>> Stashed changes
                        ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
<<<<<<< Updated upstream
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
=======
            if (data['quotationNote'] != null &&
                (data['quotationNote'] as String).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusSm),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PURCHASE REMARK:',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['quotationNote'],
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                    ),
>>>>>>> Stashed changes
                  ],
                ),
              ),
            ],
            if (status == 'rejected' && rejectionReason != null) ...[
<<<<<<< Updated upstream
              const SizedBox(height: 10),
              Text('Rejection Reason: $rejectionReason', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
=======
              const SizedBox(height: AppSpacing.s),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusSm),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                ),
                child: Text(
                  'Rejection Reason: $rejectionReason',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.error, fontSize: 11),
                ),
              ),
>>>>>>> Stashed changes
            ],
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                if (imageUrl != null)
                  Expanded(
                    child: SecondaryButton(
                      onPressed: () => _viewFile(imageUrl),
                      icon: Icons.assignment_outlined,
                      label: 'Requirement',
                      isFullWidth: false,
                      height: 40,
                    ),
                  ),
                if (pdfUrl != null) ...[
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: SecondaryButton(
                      onPressed: () => _viewFile(pdfUrl),
                      icon: Icons.receipt_long_outlined,
                      label: 'Quotation',
                      isFullWidth: false,
                      height: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
<<<<<<< Updated upstream
                      onPressed: () => _updateStatus(siteId, doc.id, 'approved'),
=======
                      onPressed: () =>
                          _updateStatus(siteId, doc.id, 'approved'),
                      icon: Icons.check_circle_outline,
>>>>>>> Stashed changes
                      label: 'Approve',
                      color: AppColors.success,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () => _showRejectionDialog(siteId, doc.id),
                      icon: Icons.cancel_outlined,
                      label: 'Reject',
                      color: AppColors.error,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: AppSpacing.s),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Submitted: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 9, color: AppColors.onSurfaceMuted),
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

