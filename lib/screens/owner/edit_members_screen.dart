import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/site_model.dart';

class EditMembersScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const EditMembersScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<EditMembersScreen> createState() => _EditMembersScreenState();
}

class _EditMembersScreenState extends State<EditMembersScreen> {
  final _firestoreService = FirestoreService();

  bool _loadingUsers = true;

  // All users fetched from Firestore
  List<UserModel> _allEngineers = [];
  List<UserModel> _allPurchase = [];

  // Currently assigned UIDs (live from Firestore stream)
  Set<String> _assignedEngineers = {};
  Set<String> _assignedPurchase = {};

  // Newly selected UIDs to be added (not yet saved)
  final Set<String> _toAddEngineers = {};
  final Set<String> _toAddPurchase = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    final engineers = await _firestoreService.getUsersByRole(kRoleSiteEngineer);
    final purchase = await _firestoreService.getUsersByRole(kRolePurchaseTeam);
    if (mounted) {
      setState(() {
        // Exclude owners
        _allEngineers = engineers.where((u) => u.role != kRoleOwner).toList();
        _allPurchase = purchase.where((u) => u.role != kRoleOwner).toList();
        _loadingUsers = false;
      });
    }
  }

  Future<void> _removeEngineer(String uid) async {
    setState(() => _saving = true);
    try {
      await _firestoreService.removeMemberFromSite(
        siteId: widget.siteId,
        uid: uid,
        field: 'assignedEngineers',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removePurchase(String uid) async {
    setState(() => _saving = true);
    try {
      await _firestoreService.removeMemberFromSite(
        siteId: widget.siteId,
        uid: uid,
        field: 'assignedPurchaseTeam',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSelectedEngineers() async {
    if (_toAddEngineers.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _firestoreService.addMembersToSite(
        siteId: widget.siteId,
        engineerUids: _toAddEngineers.toList(),
      );
      setState(() => _toAddEngineers.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Engineers added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSelectedPurchase() async {
    if (_toAddPurchase.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _firestoreService.addMembersToSite(
        siteId: widget.siteId,
        purchaseUids: _toAddPurchase.toList(),
      );
      setState(() => _toAddPurchase.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase team members added!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Members', style: AppTextStyles.h3.copyWith(color: AppColors.onSurface)),
            Text(widget.siteName,
                style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: _loadingUsers
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : StreamBuilder<SiteModel?>(
              stream: _firestoreService.streamSite(widget.siteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                final site = snapshot.data;
                _assignedEngineers =
                    Set<String>.from(site?.assignedEngineers ?? []);
                _assignedPurchase =
                    Set<String>.from(site?.assignedPurchaseTeam ?? []);

                // Unassigned = all users NOT currently assigned
                final unassignedEngineers = _allEngineers
                    .where((u) => !_assignedEngineers.contains(u.uid))
                    .toList();
                final unassignedPurchase = _allPurchase
                    .where((u) => !_assignedPurchase.contains(u.uid))
                    .toList();

                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── SECTION 1: Site Engineers ────────────────────────
                        _SectionTitle(
                          icon: Icons.engineering_outlined,
                          label: 'Site Engineers',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),

                        // Currently assigned
                        if (_assignedEngineers.isEmpty)
                          _emptyAssigned('No engineers assigned yet')
                        else
                          ..._allEngineers
                              .where((u) => _assignedEngineers.contains(u.uid))
                              .map((u) => _AssignedMemberTile(
                                    user: u,
                                    onRemove: _saving ? null : () => _removeEngineer(u.uid),
                                    accentColor: AppColors.primary,
                                  )),

                        const SizedBox(height: 16),

                        // Add new engineers
                        if (unassignedEngineers.isNotEmpty) ...[
                          Text('Add Engineers', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          _MultiSelectChips(
                            users: unassignedEngineers,
                            selected: _toAddEngineers,
                            accentColor: AppColors.primary,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          if (_toAddEngineers.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.person_add_outlined, size: 18),
                                label: Text(
                                    'Add ${_toAddEngineers.length} Selected Engineer${_toAddEngineers.length > 1 ? 's' : ''}'),
                                onPressed: _saving ? null : _addSelectedEngineers,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 32),
                        const Divider(color: AppColors.divider, thickness: 1.5),
                        const SizedBox(height: 20),

                        // ── SECTION 2: Purchase Team ─────────────────────────
                        _SectionTitle(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Purchase Team',
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),

                        // Currently assigned
                        if (_assignedPurchase.isEmpty)
                          _emptyAssigned('No purchase team members assigned yet')
                        else
                          ..._allPurchase
                              .where((u) => _assignedPurchase.contains(u.uid))
                              .map((u) => _AssignedMemberTile(
                                    user: u,
                                    onRemove: _saving ? null : () => _removePurchase(u.uid),
                                    accentColor: AppColors.success,
                                  )),

                        const SizedBox(height: 16),

                        // Add new purchase team members
                        if (unassignedPurchase.isNotEmpty) ...[
                          Text('Add Purchase Team Members', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          _MultiSelectChips(
                            users: unassignedPurchase,
                            selected: _toAddPurchase,
                            accentColor: AppColors.success,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          if (_toAddPurchase.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.group_add_outlined, size: 18),
                                label: Text(
                                    'Add ${_toAddPurchase.length} Selected Member${_toAddPurchase.length > 1 ? 's' : ''}'),
                                onPressed: _saving ? null : _addSelectedPurchase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                    if (_saving)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          backgroundColor: AppColors.divider,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _emptyAssigned(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(msg, style: AppTextStyles.caption),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.h3),
      ],
    );
  }
}

class _AssignedMemberTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onRemove;
  final Color accentColor;

  const _AssignedMemberTile({
    required this.user,
    required this.onRemove,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name.isNotEmpty ? user.name : user.email;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                  Text(user.email, style: AppTextStyles.caption),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 22),
              tooltip: 'Remove',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectChips extends StatelessWidget {
  final List<UserModel> users;
  final Set<String> selected;
  final Color accentColor;
  final VoidCallback onChanged;

  const _MultiSelectChips({
    required this.users,
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          final name = user.name.isNotEmpty ? user.name : user.email;
          return FilterChip(
            label: Text(name),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                selected.add(user.uid);
              } else {
                selected.remove(user.uid);
              }
              onChanged();
            },
            selectedColor: accentColor.withValues(alpha: 0.18),
            checkmarkColor: accentColor,
            backgroundColor: AppColors.background,
            side: BorderSide(color: isSelected ? accentColor : AppColors.divider),
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
