import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common_widgets.dart';

class EngineerMaterialRequestsTab extends StatefulWidget {
  final String siteId;
  const EngineerMaterialRequestsTab({super.key, required this.siteId});

  @override
  State<EngineerMaterialRequestsTab> createState() => _EngineerMaterialRequestsTabState();
}

class _EngineerMaterialRequestsTabState extends State<EngineerMaterialRequestsTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _currentUid;
  String? _currentUserName;

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      _currentUid = user.uid;
      final userModel = await _authService.getUserModel(user.uid);
      if (mounted) {
        setState(() {
          _currentUserName = userModel?.name ?? 'Unknown Engineer';
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedImageBytes == null || _currentUid == null || _currentUserName == null) return;

    setState(() => _isUploading = true);

    try {
      final String? imageUrl = await _cloudinaryService.uploadImage(
        _selectedImageBytes!,
        _selectedImageName ?? 'requirement_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (imageUrl == null) {
        throw Exception("Failed to upload image to Cloudinary.");
      }

      await FirebaseFirestore.instance
          .collection('materialRequests')
          .doc(widget.siteId)
          .collection('requests')
          .add({
        'requestImageURL': imageUrl,
        'uploadedBy': _currentUid,
        'uploadedByName': _currentUserName,
        'siteId': widget.siteId,
        'status': 'pending_quotation',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material request submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
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

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (_selectedImageBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remove selected image', style: AppTextStyles.bodyLg),
                onTap: () {
                  Navigator.pop(ctx);
                  _clearSelectedImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take Photo', style: AppTextStyles.bodyLg),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from Gallery', style: AppTextStyles.bodyLg),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
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
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Request Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  if (_selectedImageBytes == null)
                    PrimaryButton(
                      icon: Icons.add_photo_alternate,
                      label: 'New Request',
                      onPressed: _showImagePickerOptions,
                    )
                  else ...[
                    // Preview
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_selectedImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: _showImagePickerOptions,
                            icon: Icons.edit_outlined,
                            label: 'Change',
                            color: AppColors.primary,
                            height: 48,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 52,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _clearSelectedImage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isUploading)
                      const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                    else
                      PrimaryButton(
                        onPressed: _submitRequest,
                        label: 'Submit Request',
                        color: AppColors.success,
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            
            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.streamMyMaterialRequests(
                  siteId: widget.siteId,
                  uid: _currentUid ?? '',
                ),
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
                    return Center(child: Text('No material requests submitted yet.', style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final imageUrl = data['requestImageURL'] as String?;
                      final status = data['status'] as String? ?? 'pending';
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                      final rejectionReason = data['rejectionReason'] as String?;
                      final canDelete = status == 'pending_quotation' || status == 'rejected';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.divider),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: imageUrl != null ? () => _viewFullScreenImage(imageUrl) : null,
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
                                  const Icon(Icons.image_not_supported),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Request #${doc.id.substring(0, 6).toUpperCase()}', style: AppTextStyles.h4),
                                      if (createdAt != null)
                                        Text(DateFormat('MMM dd, hh:mm a').format(createdAt), style: AppTextStyles.caption),
                                      if (status == 'rejected' && rejectionReason != null)
                                        Text('Rejected: $rejectionReason', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                                    ],
                                  ),
                                ),
                                if (canDelete)
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _deleteRequest(doc.id),
                                  ),
                                _statusBadge(status),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
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
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _deleteRequest(String requestId) async {
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
          .doc(requestId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
