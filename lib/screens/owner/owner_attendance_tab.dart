import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class OwnerAttendanceTab extends StatefulWidget {
  final String siteId;
  const OwnerAttendanceTab({super.key, required this.siteId});

  @override
  State<OwnerAttendanceTab> createState() => _OwnerAttendanceTabState();
}

class _OwnerAttendanceTabState extends State<OwnerAttendanceTab> {
  final _firestoreService = FirestoreService();
  bool _loading = true;

  List<String> _engineerUids = [];
  List<String> _purchaseUids = [];
  final Map<String, UserModel> _userCache = {};


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final site = await _firestoreService.getSite(widget.siteId);
      if (site == null) return;

      _engineerUids = site.assignedEngineers;
      _purchaseUids = site.assignedPurchaseTeam;

      // Load user names for all members
      final allUids = {..._engineerUids, ..._purchaseUids};
      for (final uid in allUids) {
        if (!_userCache.containsKey(uid)) {
          final user = await _firestoreService.getUser(uid);
          if (user != null) _userCache[uid] = user;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _loadData();
      },
      color: AppColors.primary,
      child: StreamBuilder<Map<String, List<String>>>(
        stream: _firestoreService.streamAttendanceForSite(widget.siteId),
        builder: (context, engineerSnap) {
          return StreamBuilder<Map<String, List<String>>>(
            stream: _firestoreService.streamPurchaseAttendanceForSite(widget.siteId),
            builder: (context, purchaseSnap) {
              final engAttendance = engineerSnap.data ?? {};
              final purAttendance = purchaseSnap.data ?? {};

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  // ── SECTION 1: Site Engineers ──────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.engineering_outlined,
                    label: 'Site Engineers',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),

                  if (_engineerUids.isEmpty)
                    _buildEmpty('No engineers assigned to this site')
                  else ...[
                    ..._engineerUids.map((uid) => _MemberSummaryCard(
                          uid: uid,
                          user: _userCache[uid],
                          attendanceData: engAttendance,
                          accentColor: AppColors.primary,
                        )),
                    const SizedBox(height: AppSpacing.m),
                    _AttendanceLog(
                      memberUids: _engineerUids,
                      attendanceData: engAttendance,
                      userCache: _userCache,
                      accentColor: AppColors.primary,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.xl),

                  // ── SECTION 2: Purchase Team ───────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Purchase Team',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),

                  if (_purchaseUids.isEmpty)
                    _buildEmpty('No purchase team members assigned to this site')
                  else ...[
                    ..._purchaseUids.map((uid) => _MemberSummaryCard(
                          uid: uid,
                          user: _userCache[uid],
                          attendanceData: purAttendance,
                          accentColor: AppColors.success,
                        )),
                    const SizedBox(height: 16),
                    _AttendanceLog(
                      memberUids: _purchaseUids,
                      attendanceData: purAttendance,
                      userCache: _userCache,
                      accentColor: AppColors.success,
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 40, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 8),
            Text(msg, style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  final String uid;
  final UserModel? user;
  final Map<String, List<String>> attendanceData;
  final Color accentColor;

  const _MemberSummaryCard({
    required this.uid,
    required this.user,
    required this.attendanceData,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user != null && user!.name.isNotEmpty) ? user!.name : uid;
    int presentDays = 0;
    for (final uids in attendanceData.values) {
      if (uids.contains(uid)) presentDays++;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(user?.email ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Text(
                '$presentDays days',
                style: AppTextStyles.caption.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceLog extends StatelessWidget {
  final List<String> memberUids;
  final Map<String, List<String>> attendanceData;
  final Map<String, UserModel> userCache;
  final Color accentColor;

  const _AttendanceLog({
    required this.memberUids,
    required this.attendanceData,
    required this.userCache,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dates = attendanceData.keys.toList()..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'No attendance records yet',
            style: AppTextStyles.caption,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('LOG HISTORY', style: AppTextStyles.label.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface.withValues(alpha: 0.4))),
        ),
        const SizedBox(height: AppSpacing.m),
        ...dates.map((date) {
          final presentUids = attendanceData[date] ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available_outlined, size: 16, color: accentColor),
                      const SizedBox(width: AppSpacing.s),
                      Text(date,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                        ),
                        child: Text(
                          '${presentUids.length}/${memberUids.length} Present',
                          style: AppTextStyles.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: memberUids.map((uid) {
                      final isPresent = presentUids.contains(uid);
                      final name = userCache[uid]?.name ?? uid;
                      return Chip(
                        avatar: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: isPresent ? accentColor : AppColors.error,
                        ),
                        label: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPresent ? accentColor : AppColors.error,
                          ),
                        ),
                        backgroundColor:
                            (isPresent ? accentColor : AppColors.error).withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
