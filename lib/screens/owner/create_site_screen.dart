import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'owner_site_detail.dart';

class CreateSiteScreen extends StatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  State<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends State<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

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
        // Exclude the current user (owner) from assignment lists,
        // and also defensively exclude anyone with the owner role.
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      );

      if (mounted) {
        // Replace current screen with site detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerSiteDetailScreen(
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_location_alt, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('New Construction Site', style: AppTextStyles.h3),
                                SizedBox(height: 2),
                                Text('Fill in the details below to register a new site',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Site Name
                    BuilderTextField(
                      controller: _nameController,
                      label: 'Site Name',
                      hint: 'e.g. Greenview Towers',
                      prefixIcon: Icons.location_city_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Site name is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Location
                    BuilderTextField(
                      controller: _locationController,
                      label: 'Site Location',
                      hint: 'e.g. Baner, Pune',
                      prefixIcon: Icons.pin_drop_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Start Date
                    Text('Start Date', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickStartDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 20, color: AppColors.onSurfaceMuted),
                            const SizedBox(width: 12),
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: AppTextStyles.body,
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_outlined,
                                size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Assign Site Engineers
                    Text('Assign Site Engineers', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    _UserChipSelector(
                      users: _allEngineers,
                      selected: _selectedEngineers,
                      emptyText: 'No site engineers registered yet',
                      accentColor: AppColors.primary,
                      onChanged: () => setState(() {}),
                    ),

                    const SizedBox(height: 20),

                    // Assign Purchase Team
                    Text('Assign Purchase Team Members', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    _UserChipSelector(
                      users: _allPurchase,
                      selected: _selectedPurchase,
                      emptyText: 'No purchase team members registered yet',
                      accentColor: AppColors.success,
                      onChanged: () => setState(() {}),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    PrimaryButton(
                      label: 'Create Site',
                      icon: Icons.check_circle_outline,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-select chip widget for users
// ---------------------------------------------------------------------------
class _UserChipSelector extends StatelessWidget {
  final List<UserModel> users;
  final Set<String> selected;
  final String emptyText;
  final Color accentColor;
  final VoidCallback onChanged;

  const _UserChipSelector({
    required this.users,
    required this.selected,
    required this.emptyText,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceMuted),
            const SizedBox(width: 8),
            Text(emptyText, style: AppTextStyles.caption),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: users.map((user) {
          final isSelected = selected.contains(user.uid);
          return FilterChip(
            label: Text(user.name.isNotEmpty ? user.name : user.email),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                selected.add(user.uid);
              } else {
                selected.remove(user.uid);
              }
              onChanged();
            },
            selectedColor: accentColor.withValues(alpha: 0.2),
            checkmarkColor: accentColor,
            backgroundColor: AppColors.background,
            side: BorderSide(
              color: isSelected ? accentColor : AppColors.divider,
            ),
            labelStyle: TextStyle(
              color: isSelected ? accentColor : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          );
        }).toList(),
      ),
    );
  }
}
