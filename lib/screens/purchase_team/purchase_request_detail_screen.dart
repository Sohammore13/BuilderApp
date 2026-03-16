import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
                ),
              ),
            ),
          ),
        ),
      ));
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
        title: const Text('Requirement Details', style: TextStyle(fontSize: 18)),
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
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Add a remark (e.g. Dealer name)...',
                            hintStyle: AppTextStyles.caption,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          onPressed: _pickFile,
                          icon: Icons.upload_file,
                          label: 'Attach Quotation (Imge or PDF)',
                          color: AppColors.primaryLight,
                        ),
                        if (_selectedFilename != null) ...[
                          const SizedBox(height: 10),
                          Text('Selected: $_selectedFilename', 
                            style: AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          PrimaryButton(
                            onPressed: _uploadQuotation,
                            icon: Icons.send,
                            label: 'Send to Owner for Approval',
                          ),
                        ]
                      ] else ...[
                        if (_existingNote != null && _existingNote!.isNotEmpty) ...[
                          Text('Remark:', style: AppTextStyles.label),
                          Text(_existingNote!, style: AppTextStyles.body),
                          const SizedBox(height: 12),
                        ],
                        if (_quotationUrl != null)
                          PrimaryButton(
                            onPressed: () => _viewQuotation(_quotationUrl!),
                            icon: Icons.description,
                            label: 'View Quotation',
                            height: 56,
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
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
