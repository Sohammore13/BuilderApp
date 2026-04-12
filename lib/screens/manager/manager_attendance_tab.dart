import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class ManagerAttendanceTab extends StatefulWidget {
  final String siteId;
  const ManagerAttendanceTab({super.key, required this.siteId});

  @override
  State<ManagerAttendanceTab> createState() => _ManagerAttendanceTabState();
}

class _ManagerAttendanceTabState extends State<ManagerAttendanceTab> {
  final _firestoreService = FirestoreService();
  bool _loading = true;

  List<String> _engineerUids = [];
  List<String> _purchaseUids = [];
  final Map<String, UserModel> _userCache = {};

  // date → list of present engineer UIDs
  Map<String, List<String>> _engineerAttendance = {};
  // date → list of present purchase UIDs
  Map<String, List<String>> _purchaseAttendance = {};

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

      // Load user names for all members (one-time fetch or could be cached)
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
                  const _SectionHeader(
                    icon: Icons.engineering_outlined,
                    label: 'Site Engineers',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  if (_engineerUids.isEmpty)
                    _buildEmpty('No engineers assigned to this site')
                  else ...[
                    ..._engineerUids.map((uid) => _MemberSummaryCard(
                          uid: uid,
                          user: _userCache[uid],
                          attendanceData: engAttendance,
                          accentColor: AppColors.primary,
                        )),
                    const SizedBox(height: 16),
                    _AttendanceLog(
                      memberUids: _engineerUids,
                      attendanceData: engAttendance,
                      userCache: _userCache,
                      accentColor: AppColors.primary,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppSpacing.xl),

                  // ── SECTION 2: Purchase Team ───────────────────────────────────────
                  const _SectionHeader(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Purchase Team',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.m),

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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(label, style: AppTextStyles.h3.copyWith(color: AppColors.onSurface.withValues(alpha: 0.9))),
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
              radius: 18,
              backgroundColor: accentColor.withValues(alpha: 0.15),
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
                  Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Text(
                '$presentDays days',
                style: AppTextStyles.caption.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s),
          child: Text('Recent History', style: AppTextStyles.label.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        ),
        ...dates.map((date) {
          final presentUids = attendanceData[date] ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
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
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.onSurfaceMuted.withValues(alpha: 0.7)),
                      const SizedBox(width: AppSpacing.s),
                      Text(date,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                        ),
                        child: Text(
                          '${presentUids.length}/${memberUids.length} present',
                          style: AppTextStyles.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: memberUids.map((uid) {
                      final isPresent = presentUids.contains(uid);
                      final name = userCache[uid]?.name ?? uid;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPresent ? accentColor : AppColors.error).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                          border: Border.all(
                            color: (isPresent ? accentColor : AppColors.error).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPresent ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: isPresent ? accentColor : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isPresent ? accentColor : AppColors.error.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
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
