import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../services/geofence_service.dart';
import '../../widgets/common_widgets.dart';

class EngineerAttendanceTab extends StatefulWidget {
  final String siteId;
  const EngineerAttendanceTab({super.key, required this.siteId});

  @override
  State<EngineerAttendanceTab> createState() => _EngineerAttendanceTabState();
}

class _EngineerAttendanceTabState extends State<EngineerAttendanceTab> {
  final _firestoreService = FirestoreService();
  bool _loading = true;
  bool _marking = false;
  bool _markedToday = false;
  List<Map<String, dynamic>> _history = [];

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _markedToday = await _firestoreService.hasMarkedAttendance(
        siteId: widget.siteId,
        date: _todayStr,
        engineerUid: _uid,
      );

      _history = await _firestoreService.getAttendanceForEngineer(
        siteId: widget.siteId,
        engineerUid: _uid,
      );
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markPresent() async {
    setState(() => _marking = true);

    try {
      // TODO: Fetch site data (you may already have this)
      final siteDoc = await FirebaseFirestore.instance
          .collection('sites')
          .doc(widget.siteId)
          .get();

      final siteData = siteDoc.data()!;

      final double siteLat = (siteData['latitude'] ?? 0).toDouble();
      final double siteLng = (siteData['longitude'] ?? 0).toDouble();
      final double radius = (siteData['radius'] ?? 250).toDouble();

      // ✅ Geofence check
      final isInside = await GeofenceService.isWithinRadius(
        siteLat: siteLat,
        siteLng: siteLng,
        radiusInMeters: radius,
      );

      if (!isInside) {
        throw Exception("You are not at the site location");
      }

      // ✅ If inside → mark attendance
      await _firestoreService.markAttendance(
        siteId: widget.siteId,
        date: _todayStr,
        engineerUid: _uid,
      );

      setState(() {
        _markedToday = true;
        if (!_history.any((h) => h['date'] == _todayStr)) {
          _history.insert(0, {'date': _todayStr, 'status': 'present'});
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully (within site area)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
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
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Today's attendance card
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
                        AppColors.warning.withValues(alpha: 0.1),
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
                Text(_todayStr, style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted)),
                if (!_markedToday) ...[
                  const SizedBox(height: AppSpacing.l),
                  PrimaryButton(
                    onPressed: _markPresent,
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

          // Attendance history
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('Attendance History',
                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: AppSpacing.m),

          if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance records yet',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ..._history.map((record) {
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
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Text(record['date'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                      ),
                      child: Text(
                        'Present',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
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
