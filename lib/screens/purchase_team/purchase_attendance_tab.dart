import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../services/geofence_service.dart';
import '../../widgets/common_widgets.dart';

class PurchaseAttendanceTab extends StatefulWidget {
  final String siteId;
  const PurchaseAttendanceTab({super.key, required this.siteId});

  @override
  State<PurchaseAttendanceTab> createState() => _PurchaseAttendanceTabState();
}

class _PurchaseAttendanceTabState extends State<PurchaseAttendanceTab> {
  final _firestoreService = FirestoreService();
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  bool _loading = true;
  bool _markedToday = false;
  bool _marking = false;

  List<Map<String, dynamic>> _history = [];

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _checkTodayAttendance(),
      _loadHistory(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkTodayAttendance() async {
    final marked = await _firestoreService.hasMarkedPurchaseAttendance(
      siteId: widget.siteId,
      date: _todayKey,
      memberUid: _uid,
    );
    if (mounted) setState(() => _markedToday = marked);
  }

  Future<void> _loadHistory() async {
    final records = await _firestoreService.getAttendanceForPurchaseMember(
      siteId: widget.siteId,
      memberUid: _uid,
    );
    if (mounted) setState(() => _history = records);
  }

  Future<void> _markAttendance() async {
    setState(() => _marking = true);
    try {
      // 1. Get site location
      final siteDoc = await FirebaseFirestore.instance
          .collection('sites')
          .doc(widget.siteId)
          .get();

      if (!siteDoc.exists) throw Exception("Site not found");
      final siteData = siteDoc.data()!;

      final double siteLat = (siteData['latitude'] ?? 0).toDouble();
      final double siteLng = (siteData['longitude'] ?? 0).toDouble();
      final double radius = (siteData['radius'] ?? 250).toDouble();

      // 2. Geofence check
      final isInside = await GeofenceService.isWithinRadius(
        siteLat: siteLat,
        siteLng: siteLng,
        radiusInMeters: radius,
      );

      if (!isInside) {
        throw Exception("You are not within the site geofence (250m)");
      }

      await _firestoreService.markPurchaseAttendance(
        siteId: widget.siteId,
        date: _todayKey,
        memberUid: _uid,
      );
      await _init();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked for today!'),
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
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _init();
      },
      color: AppColors.success,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ── Today's Attendance ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _markedToday
                    ? [
                        AppColors.success.withValues(alpha: 0.1),
                        AppColors.success.withValues(alpha: 0.02),
                      ]
                    : [
                        AppColors.warning.withValues(alpha: 0.11),
                        AppColors.warning.withValues(alpha: 0.02),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(
                color: (_markedToday ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _markedToday ? Icons.check_circle_outline : Icons.schedule_outlined,
                  size: 44,
                  color: _markedToday ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  _markedToday
                      ? 'Attendance Marked'
                      : 'Mark Attendance',
                  style: AppTextStyles.h3.copyWith(
                    color: _markedToday ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_todayKey, style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted)),
                if (!_markedToday) ...[
                  const SizedBox(height: AppSpacing.l),
                  PrimaryButton(
                    onPressed: _markAttendance,
                    isLoading: _marking,
                    icon: Icons.check,
                    label: 'Mark Present',
                    color: AppColors.success,
                    height: 48,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Attendance History ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('Attendance History', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: AppSpacing.m),

          if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 44, color: AppColors.onSurfaceMuted),
                    const SizedBox(height: 10),
                    Text('No attendance records yet',
                        style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
                  ],
                ),
              ),
            )
          else
            ..._history.map((record) {
              final date = record['date'] as String;
              final status = record['status'] as String? ?? 'present';
              final isPresent = status == 'present';
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (isPresent ? AppColors.success : AppColors.error)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                        ),
                        child: Icon(
                          isPresent
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          size: 16,
                          color: isPresent
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          date,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              (isPresent ? AppColors.success : AppColors.error)
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                        ),
                        child: Text(
                          isPresent ? 'PRESENT' : 'ABSENT',
                          style: AppTextStyles.caption.copyWith(
                            color: isPresent
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
