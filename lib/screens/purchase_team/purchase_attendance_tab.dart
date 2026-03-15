import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';

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
  bool _checkingToday = true;
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
        padding: const EdgeInsets.all(16),
        children: [
          // ── Today's Attendance ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.12),
                  AppColors.success.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.today, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Attendance", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        Text(_todayKey, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_markedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Attendance marked for today',
                          style: AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _marking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.how_to_reg_outlined, size: 20),
                      label: Text(_marking ? 'Marking...' : 'Mark Present'),
                      onPressed: _marking ? null : _markAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Attendance History ─────────────────────────────────────────────
          Text('Attendance History', style: AppTextStyles.h3),
          const SizedBox(height: 12),

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
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (isPresent ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 18,
                          color: isPresent ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(date,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPresent ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPresent ? 'PRESENT' : 'ABSENT',
                          style: AppTextStyles.caption.copyWith(
                            color: isPresent ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
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
