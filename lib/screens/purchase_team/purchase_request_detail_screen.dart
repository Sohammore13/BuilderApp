import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common_widgets.dart';

class PurchaseRequestDetailScreen extends StatefulWidget {
  final String siteId;
  final String requestId;
  final Map<String, dynamic> requestData;

  const PurchaseRequestDetailScreen({
    super.key,
    required this.siteId,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<PurchaseRequestDetailScreen> createState() => _PurchaseRequestDetailScreenState();
}

class _PurchaseRequestDetailScreenState extends State<PurchaseRequestDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _noteController = TextEditingController();

  bool _isUploading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedFilename;

  String get _status => widget.requestData['status'] as String? ?? 'pending_quotation';
  String get _imageUrl => widget.requestData['requestImageURL'] as String? ?? '';
  String? get _quotationUrl => widget.requestData['purchaseOrderPdfURL'] as String?;
  String? get _existingNote => widget.requestData['quotationNote'] as String?;

  void _clearSelectedAttachment() {
    setState(() {
      _selectedImageBytes = null;
      _selectedFilename = null;
    });
  }

  bool get _canDeleteRequest =>
      _status == 'pending_quotation' || _status == 'pending_approval' || _status == 'rejected';

  Future<void> _deleteRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Request', style: TextStyle(color: AppColors.onSurface)),
        content: const Text(
          'Are you sure you want to delete this request? This cannot be undone.',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
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

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('materialRequests')
          .doc(widget.siteId)
          .collection('requests')
          .doc(widget.requestId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request deleted'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Necessary for Web
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes;
        _selectedFilename = result.files.single.name;
      });
    }
  }

  Future<void> _uploadQuotation() async {
    if (_selectedImageBytes == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      String? fileUrl;
      final bool isPdf = _selectedFilename?.toLowerCase().endsWith('.pdf') ?? false;

      if (isPdf) {
        fileUrl = await _cloudinaryService.uploadPDF(
          _selectedImageBytes!,
          _selectedFilename!,
        );
      } else {
        fileUrl = await _cloudinaryService.uploadImage(
          _selectedImageBytes!,
          _selectedFilename ?? 'quotation_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      
      if (fileUrl == null) {
        throw Exception("Failed to upload file to Cloudinary.");
      }

      await _firestoreService.uploadPurchaseOrderPdf(
        siteId: widget.siteId,
        requestId: widget.requestId,
        pdfUrl: fileUrl,
        uploadedBy: user.uid,
        quotationNote: _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quotation submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _viewQuotation(String url) async {
    final uri = Uri.parse(url);
    final bool isPdf = url.toLowerCase().endsWith('.pdf') || url.contains('/raw/upload');

    if (isPdf) {
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
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
<<<<<<< Updated upstream
            title: const Text('Quotation Preview', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    Text('Failed to load quotation image', style: TextStyle(color: Colors.white)),
                  ],
=======
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load quotation image',
                        style: AppTextStyles.body.copyWith(color: Colors.white),
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

<<<<<<< Updated upstream
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_quotation': return Colors.blue;
      case 'pending_approval': return AppColors.warning;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.onSurfaceMuted;
    }
  }
=======

>>>>>>> Stashed changes

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
<<<<<<< Updated upstream
        title: const Text('Requirement Details', style: TextStyle(fontSize: 18)),
=======
        title: Text('Material Requirement', style: AppTextStyles.appBarTitle),
        centerTitle: true,
>>>>>>> Stashed changes
        actions: [
          if (_canDeleteRequest)
            IconButton(
              tooltip: 'Delete',
              onPressed: _deleteRequest,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Zoomable Image
              Expanded(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.95),
                  width: double.infinity,
                  child: InteractiveViewer(
                    child: _imageUrl.isNotEmpty
<<<<<<< Updated upstream
                      ? Image.network(_imageUrl, fit: BoxFit.contain)
                      : const Center(child: Icon(Icons.image_not_supported, color: Colors.white, size: 50)),
=======
                        ? Image.network(_imageUrl, fit: BoxFit.contain)
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white24,
                              size: 50,
                            ),
                          ),
>>>>>>> Stashed changes
                  ),
                ),
              ),

              // Bottom Control Panel
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
<<<<<<< Updated upstream
                          Text('Status:', style: AppTextStyles.h4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatStatus(_status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
=======
                          Text('Current Status',
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.bold)),
                          AppStatusBadge(
                            label: _formatStatus(_status),
                            tone: statusTone,
>>>>>>> Stashed changes
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_status == 'pending_quotation') ...[
                        TextField(
                          controller: _noteController,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            hintText: 'Add dealer info or remarks...',
                            hintStyle: AppTextStyles.caption
                                .copyWith(color: AppColors.onSurfaceMuted),
                            filled: true,
                            fillColor: AppColors.background,
<<<<<<< Updated upstream
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
=======
                            contentPadding: const EdgeInsets.all(AppSpacing.m),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadius),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadius),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadius),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
>>>>>>> Stashed changes
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        SecondaryButton(
                          onPressed: _pickFile,
<<<<<<< Updated upstream
                          icon: Icons.upload_file,
                          label: 'Attach Quotation (Imge or PDF)',
                          color: AppColors.primaryLight,
=======
                          icon: Icons.attach_file_rounded,
                          label: 'Attach Quotation (Ref. Image/PDF)',
                          color: AppColors.primary,
                          height: 44,
>>>>>>> Stashed changes
                        ),
                        if (_selectedFilename != null) ...[
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadiusSm),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(
<<<<<<< Updated upstream
                                  (_selectedFilename?.toLowerCase().endsWith('.pdf') ?? false)
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.image_outlined,
=======
                                  (_selectedFilename?.toLowerCase().endsWith(
                                            '.pdf',
                                          ) ??
                                          false)
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
>>>>>>> Stashed changes
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: Text(
                                    _selectedFilename!,
<<<<<<< Updated upstream
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _pickFile,
                                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                  child: const Text('Change'),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: _clearSelectedAttachment,
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
=======
                                    style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: _clearSelectedAttachment,
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.error, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
>>>>>>> Stashed changes
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          PrimaryButton(
                            onPressed: _uploadQuotation,
                            icon: Icons.cloud_upload_outlined,
                            label: 'Submit for Approval',
                            color: AppColors.success,
                            height: 52,
                          ),
                        ]
                      ] else ...[
<<<<<<< Updated upstream
                        if (_existingNote != null && _existingNote!.isNotEmpty) ...[
                          Text('Remark:', style: AppTextStyles.label),
=======
                        if (_existingNote != null &&
                            _existingNote!.isNotEmpty) ...[
                          Text('PURCHASE REMARK',
                              style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurfaceMuted)),
                          const SizedBox(height: 4),
>>>>>>> Stashed changes
                          Text(_existingNote!, style: AppTextStyles.body),
                          const SizedBox(height: AppSpacing.l),
                        ],
                        if (_quotationUrl != null)
                          PrimaryButton(
                            onPressed: () => _viewQuotation(_quotationUrl!),
                            icon: Icons.file_present_rounded,
                            label: 'View Submitted Quotation',
                            height: 52,
                            color: AppColors.primary,
                          ),
                        if (_quotationUrl == null)
                          Text('No Quotation attached.', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted), textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
