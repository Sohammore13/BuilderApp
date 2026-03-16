import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';

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

  bool _isUploading = false;
  Uint8List? _selectedPdfBytes;
  String? _selectedFilename;

  String get _status => widget.requestData['status'] as String? ?? 'pending_quotation';
  String get _imageUrl => widget.requestData['requestImageURL'] as String? ?? '';
  String? get _pdfUrl => widget.requestData['purchaseOrderPdfURL'] as String?;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Necessary for Web
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedPdfBytes = result.files.single.bytes;
        _selectedFilename = result.files.single.name;
      });
    }
  }

  Future<void> _uploadPdf() async {
    if (_selectedPdfBytes == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final String? pdfUrl = await _cloudinaryService.uploadPDF(
        _selectedPdfBytes!,
        _selectedFilename ?? 'quotation_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      if (pdfUrl == null) {
        throw Exception("Failed to upload PDF to Cloudinary.");
      }

      await _firestoreService.uploadPurchaseOrderPdf(
        siteId: widget.siteId,
        requestId: widget.requestId,
        pdfUrl: pdfUrl,
        uploadedBy: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase Order PDF uploaded successfully!'),
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

  Future<void> _launchPdfUrl() async {
    if (_pdfUrl == null) return;
    final Uri url = Uri.parse(_pdfUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not open PDF.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_quotation': return Colors.blue;
      case 'pending_approval': return AppColors.warning;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.onSurfaceMuted;
    }
  }

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
        title: const Text('Material Request Detail', style: TextStyle(fontSize: 18)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Zoomable Image
              Expanded(
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: InteractiveViewer(
                    child: _imageUrl.isNotEmpty
                      ? Image.network(_imageUrl, fit: BoxFit.contain)
                      : const Center(child: Icon(Icons.image_not_supported, color: Colors.white, size: 50)),
                  ),
                ),
              ),

              // Bottom Control Panel
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(20.0),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_status == 'pending_quotation') ...[
                        ElevatedButton.icon(
                          onPressed: _pickPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Upload Purchase Order PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        if (_selectedFilename != null) ...[
                          const SizedBox(height: 10),
                          Text('Selected: $_selectedFilename', 
                            style: AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _uploadPdf,
                            icon: const Icon(Icons.send),
                            label: const Text('Submit to Owner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ]
                      ] else ...[
                        if (_pdfUrl != null)
                          ElevatedButton.icon(
                            onPressed: _launchPdfUrl,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('View Purchase Order PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        if (_pdfUrl == null)
                          Text('No PDF attached.', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted), textAlign: TextAlign.center),
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
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
