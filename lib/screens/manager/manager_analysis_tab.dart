import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/site_model.dart';

class ManagerAnalysisTab extends StatefulWidget {
  const ManagerAnalysisTab({super.key});

  @override
  State<ManagerAnalysisTab> createState() => _ManagerAnalysisTabState();
}

class _ManagerAnalysisTabState extends State<ManagerAnalysisTab> {
  final _firestoreService = FirestoreService();
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();

  List<UserModel> _allUsers = [];
  List<SiteModel> _allSites = [];
  // date -> list of UIDs present on that date (across ALL sites)
  Map<String, Set<String>> _globalAttendance = {};
  // uid -> list of site names present on a specific date (for detail view if needed)
  Map<String, Map<String, Set<String>>> _userSiteAttendance = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // 1. Fetch relevant users
      final engineers = await _firestoreService.getUsersByRole('site_engineer');
      final purchaseTeam = await _firestoreService.getUsersByRole('purchase_team');
      _allUsers = [...engineers, ...purchaseTeam];

      // 2. Fetch all sites
      // We use a simplified stream-to-future for loading
      final sitesSnapshot = await _firestoreService.streamSitesForOwner('').first;
      _allSites = sitesSnapshot;

      // 3. Fetch attendance for all sites
      _globalAttendance.clear();
      _userSiteAttendance.clear();

      for (final site in _allSites) {
        final engAtt = await _firestoreService.getAttendanceForSite(site.siteId);
        final purAtt = await _firestoreService.getPurchaseAttendanceForSite(site.siteId);

        _mergeAttendance(engAtt, site.siteName);
        _mergeAttendance(purAtt, site.siteName);
      }
    } catch (e) {
      debugPrint('Error loading analysis data: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _mergeAttendance(Map<String, List<String>> attendanceMap, String siteName) {
    attendanceMap.forEach((date, uids) {
      _globalAttendance.putIfAbsent(date, () => {}).addAll(uids);

      for (final uid in uids) {
        _userSiteAttendance
            .putIfAbsent(uid, () => {})
            .putIfAbsent(date, () => {})
            .add(siteName);
      }
    });
  }

  List<UserModel> get _filteredUsers {
    return _allUsers;
  }

  int _getPresentDays(String uid, DateTime month) {
    int count = 0;
    final prefix = DateFormat('yyyy-MM').format(month);
    
    _globalAttendance.forEach((date, uids) {
      if (date.startsWith(prefix) && uids.contains(uid)) {
        count++;
      }
    });
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildMonthSelector(monthStr),
          const SizedBox(height: AppSpacing.xl),
          _buildSummaryCards(),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Employee Attendance Report',
                  style: AppTextStyles.h3.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (_allUsers.isEmpty)
            _buildEmptyState('No employees found')
          else
            ..._allUsers.map((user) => _buildUserReportCard(user, daysInMonth)),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(String monthStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          Column(
            children: [
              Text(monthStr, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
              Text('Select Month', style: AppTextStyles.caption),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    int totalPresentDays = 0;
    final prefix = DateFormat('yyyy-MM').format(_selectedMonth);
    _globalAttendance.forEach((date, uids) {
      if (date.startsWith(prefix)) {
        totalPresentDays += uids.length;
      }
    });

    final avgAttendance = _allUsers.isEmpty 
        ? 0.0 
        : (totalPresentDays / (_allUsers.length * 30) * 100).clamp(0, 100);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Staff',
            value: _allUsers.length.toString(),
            icon: Icons.groups,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: _SummaryCard(
            label: 'Avg Attendance',
            value: '${avgAttendance.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildUserReportCard(UserModel user, int daysInMonth) {
    final presentCount = _getPresentDays(user.uid, _selectedMonth);
    final percentage = (presentCount / daysInMonth);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: (user.role == 'site_engineer' ? AppColors.primary : AppColors.success).withValues(alpha: 0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: user.role == 'site_engineer' ? AppColors.primary : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      user.role.replaceAll('_', ' ').toUpperCase(),
                      style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Text(
                  '$presentCount / $daysInMonth Days',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.8 ? AppColors.success : (percentage > 0.5 ? AppColors.warning : AppColors.error),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(percentage * 100).toInt()}% Attendance', style: AppTextStyles.caption),
              if (presentCount > 0)
                TextButton(
                  onPressed: () => _showAttendanceDetails(user),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 20)),
                  child: const Text('View Dates', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(UserModel user) {
    final prefix = DateFormat('yyyy-MM').format(_selectedMonth);
    final dates = (_userSiteAttendance[user.uid] ?? {})
        .keys
        .where((d) => d.startsWith(prefix))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Attendance Details', style: AppTextStyles.h3),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(user.name, style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final sites = _userSiteAttendance[user.uid]![date]!.toList();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle, color: AppColors.success),
                      title: Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Sites: ${sites.join(", ")}'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 16),
            Text(msg, style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.m),
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
