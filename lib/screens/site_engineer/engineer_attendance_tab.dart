import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';

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
      await _firestoreService.markAttendance(
        siteId: widget.siteId,
        date: _todayStr,
        engineerUid: _uid,
      );
      setState(() {
        _markedToday = true;
        // Add to history if not already
        if (!_history.any((h) => h['date'] == _todayStr)) {
          _history.insert(0, {'date': _todayStr, 'status': 'present'});
        }
      });
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
        padding: const EdgeInsets.all(16),
        children: [
          // Today's attendance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _markedToday
                    ? [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.05)]
                    : [AppColors.warning.withValues(alpha: 0.15), AppColors.warning.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (_markedToday ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _markedToday ? Icons.check_circle : Icons.access_time,
                  size: 48,
                  color: _markedToday ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(height: 12),
                Text(
                  _markedToday ? 'Attendance marked for today' : 'Mark your attendance',
                  style: AppTextStyles.h3.copyWith(
                    color: _markedToday ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_todayStr, style: AppTextStyles.caption),
                if (!_markedToday) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _marking ? null : _markPresent,
                      icon: _marking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_marking ? 'Marking...' : 'Mark Present'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Attendance history
          Text('Attendance History', style: AppTextStyles.h3),
          const SizedBox(height: 12),

          if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 40, color: AppColors.onSurfaceMuted),
                    const SizedBox(height: 8),
                    Text('No attendance records yet',
                        style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
                  ],
                ),
              ),
            ),

          ..._history.map((record) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Text(record['date'] ?? '', style: AppTextStyles.body),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Present',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
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
