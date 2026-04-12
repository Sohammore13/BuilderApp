import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../../constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'manager_site_detail.dart';
import 'location_picker_screen.dart'; // ✅ NEW

class ManagerCreateSiteScreen extends StatefulWidget {
  const ManagerCreateSiteScreen({super.key});

  @override
  State<ManagerCreateSiteScreen> createState() =>
      _ManagerCreateSiteScreenState();
}

class _ManagerCreateSiteScreenState extends State<ManagerCreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  LatLng? _selectedLocation; // ✅ NEW

  List<UserModel> _allEngineers = [];
  List<UserModel> _allPurchase = [];
  final Set<String> _selectedEngineers = {};
  final Set<String> _selectedPurchase = {};
  bool _loadingUsers = true;

  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final engineers = await _firestoreService.getUsersByRole(kRoleSiteEngineer);
    final purchase = await _firestoreService.getUsersByRole(kRolePurchaseTeam);
    if (mounted) {
      setState(() {
        _allEngineers = engineers
            .where((u) => u.uid != currentUid && u.role != kRoleOwner)
            .toList();
        _allPurchase = purchase
            .where((u) => u.uid != currentUid && u.role != kRoleOwner)
            .toList();
        _loadingUsers = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  // ✅ NEW: Open map
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select site location on map'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedEngineers.isEmpty && _selectedPurchase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign at least one team member'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final siteId = await _firestoreService.createSite(
        siteName: _nameController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate,
        createdBy: uid,
        assignedEngineers: _selectedEngineers.toList(),
        assignedPurchaseTeam: _selectedPurchase.toList(),

        // ✅ NEW DATA (only works if you add in service)
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ManagerSiteDetailScreen(
              siteId: siteId,
              siteName: _nameController.text.trim(),
            ),
          ),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BuilderAppBar(title: 'Create Site', showLogout: false),
      body: _loadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BuilderTextField(
                      controller: _nameController,
                      label: 'Site Name',
                      hint: 'e.g. Greenview Towers',
                      prefixIcon: Icons.location_city_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Site name is required'
                          : null,
                    ),

                    const SizedBox(height: AppSpacing.m),

                    BuilderTextField(
                      controller: _locationController,
                      label: 'Site Location',
                      hint: 'e.g. Baner, Pune',
                      prefixIcon: Icons.pin_drop_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location is required'
                          : null,
                    ),

                    const SizedBox(height: AppSpacing.m),

                    // ✅ MAP BUTTON
                    SecondaryButton(
                      label: "Select Site Coordinates",
                      icon: Icons.map_outlined,
                      onPressed: _pickLocation,
                    ),

                    // ✅ SHOW SELECTED LOCATION
                    if (_selectedLocation != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppSpacing.s, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              "Coordinates Selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}",
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Start Date Picker ──────────────────────────────
                    Text('Start Date',
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.s),
                    InkWell(
                      onTap: _pickStartDate,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadius),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.borderRadius),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.onSurfaceMuted),
                            const SizedBox(width: AppSpacing.m),
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Assign Engineers ───────────────────────────────
                    Text('Assign Site Engineers',
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.s),
                    if (_allEngineers.isEmpty)
                      Text(
                        'No site engineers registered yet.',
                        style: AppTextStyles.caption,
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: _allEngineers.map((user) {
                          final isSelected =
                              _selectedEngineers.contains(user.uid);
                          final name = user.name.isNotEmpty
                              ? user.name
                              : user.email;
                          return FilterChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedEngineers.add(user.uid);
                                } else {
                                  _selectedEngineers.remove(user.uid);
                                }
                              });
                            },
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            checkmarkColor: AppColors.primary,
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Assign Purchase Team ──────────────────────────
                    Text('Assign Purchase Team',
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.s),
                    if (_allPurchase.isEmpty)
                      Text(
                        'No purchase team members registered yet.',
                        style: AppTextStyles.caption,
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: _allPurchase.map((user) {
                          final isSelected =
                              _selectedPurchase.contains(user.uid);
                          final name = user.name.isNotEmpty
                              ? user.name
                              : user.email;
                          return FilterChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedPurchase.add(user.uid);
                                } else {
                                  _selectedPurchase.remove(user.uid);
                                }
                              });
                            },
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            selectedColor:
                                AppColors.success.withValues(alpha: 0.12),
                            checkmarkColor: AppColors.success,
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.success
                                  : AppColors.divider,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.success
                                  : AppColors.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: AppSpacing.xxl),

                    PrimaryButton(
                      label: 'Create Site',
                      icon: Icons.check_circle_outline,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
