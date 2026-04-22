import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/site_model.dart';
import '../../models/expenditure_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/category_chart_sheet.dart';

class ManagerAnalysisTab extends StatefulWidget {
  const ManagerAnalysisTab({super.key});

  @override
  State<ManagerAnalysisTab> createState() => _ManagerAnalysisTabState();
}

class _ManagerAnalysisTabState extends State<ManagerAnalysisTab> {
  final _firestoreService = FirestoreService();
  bool _loading = true;
  List<SiteModel> _allSites = [];
  SiteModel? _selectedSite;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final sites = await _firestoreService.streamSitesForManager(uid).first;
      _allSites = sites;
    } catch (e) {
      debugPrint('Error loading sites: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_selectedSite != null) {
      return SiteAnalyticsDetail(
        site: _selectedSite!,
        firestoreService: _firestoreService,
        onBack: () => setState(() => _selectedSite = null),
      );
    }
    return SiteSelectionView(
      sites: _allSites,
      onRefresh: _loadSites,
      onSiteSelected: (site) => setState(() => _selectedSite = site),
      heading: 'Your Sites',
    );
  }
}

// ─── Shared: Site Selection View ──────────────────────────────────────
class SiteSelectionView extends StatelessWidget {
  final List<SiteModel> sites;
  final Future<void> Function() onRefresh;
  final void Function(SiteModel) onSiteSelected;
  final String heading;

  const SiteSelectionView({
    super.key,
    required this.sites,
    required this.onRefresh,
    required this.onSiteSelected,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analytics',
                          style: AppTextStyles.h3.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Select a site to view analytics',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              const Icon(Icons.location_city, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(heading, style: AppTextStyles.h3.copyWith(fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Text('${sites.length} sites',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (sites.isEmpty)
            _buildEmptyState()
          else
            ...sites.map((site) => _SitePickerCard(
                  site: site,
                  onTap: () => onSiteSelected(site),
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined,
                  size: 52, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            Text('No sites found',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('No sites available', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _SitePickerCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback onTap;
  const _SitePickerCard({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalStaff =
        site.assignedEngineers.length + site.assignedPurchaseTeam.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: const Icon(Icons.location_city,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(site.siteName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(site.location,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 13, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 3),
                        Text(
                          '$totalStaff staff · ${site.assignedEngineers.length} eng · ${site.assignedPurchaseTeam.length} purchase',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared: Site Analytics Detail (Attendance + Expenditure) ────────
class SiteAnalyticsDetail extends StatelessWidget {
  final SiteModel site;
  final FirestoreService firestoreService;
  final VoidCallback onBack;

  const SiteAnalyticsDetail({
    super.key,
    required this.site,
    required this.firestoreService,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: onBack,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.siteName,
                                style: AppTextStyles.h4
                                    .copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                site.location,
                                style: AppTextStyles.caption
                                    .copyWith(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: AppTextStyles.label
                        .copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    unselectedLabelStyle:
                        AppTextStyles.caption.copyWith(color: Colors.white54),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.people_outline, size: 18),
                        text: 'Attendance',
                      ),
                      Tab(
                        icon: Icon(Icons.receipt_long_outlined, size: 18),
                        text: 'Expenditure',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _AttendanceAnalysis(
                  site: site,
                  firestoreService: firestoreService,
                ),
                _ExpenditureAnalysis(
                  site: site,
                  firestoreService: firestoreService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendance Analysis Tab ──────────────────────────────────────────
class _AttendanceAnalysis extends StatefulWidget {
  final SiteModel site;
  final FirestoreService firestoreService;

  const _AttendanceAnalysis({
    required this.site,
    required this.firestoreService,
  });

  @override
  State<_AttendanceAnalysis> createState() => _AttendanceAnalysisState();
}

class _AttendanceAnalysisState extends State<_AttendanceAnalysis>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();
  List<UserModel> _siteUsers = [];
  final Map<String, Set<String>> _siteAttendance = {};
  final Map<String, Map<String, Set<String>>> _userSiteAttendance = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _siteAttendance.clear();
      _userSiteAttendance.clear();

      final engAtt =
          await widget.firestoreService.getAttendanceForSite(widget.site.siteId);
      final purAtt = await widget.firestoreService
          .getPurchaseAttendanceForSite(widget.site.siteId);

      _mergeAttendance(engAtt);
      _mergeAttendance(purAtt);

      final Set<String> relevantUids = {
        ...widget.site.assignedEngineers,
        ...widget.site.assignedPurchaseTeam,
        ...engAtt.values.expand((u) => u),
        ...purAtt.values.expand((u) => u),
      };

      final List<UserModel> fetched = [];
      for (final uid in relevantUids) {
        final user = await widget.firestoreService.getUser(uid);
        if (user != null) fetched.add(user);
      }
      final seen = <String>{};
      _siteUsers = fetched.where((u) => seen.add(u.uid)).toList();
    } catch (e) {
      debugPrint('Attendance load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _mergeAttendance(Map<String, List<String>> map) {
    map.forEach((date, uids) {
      _siteAttendance.putIfAbsent(date, () => {}).addAll(uids);
      for (final uid in uids) {
        _userSiteAttendance
            .putIfAbsent(uid, () => {})
            .putIfAbsent(date, () => {})
            .add(widget.site.siteName);
      }
    });
  }

  int _getPresentDays(String uid, DateTime month) {
    int count = 0;
    final prefix = DateFormat('yyyy-MM').format(month);
    _siteAttendance.forEach((date, uids) {
      if (date.startsWith(prefix) && uids.contains(uid)) count++;
    });
    return count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildMonthSelector(monthStr),
          const SizedBox(height: AppSpacing.xl),
          _buildSummaryCards(daysInMonth),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Staff Attendance',
                  style: AppTextStyles.h3.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (_siteUsers.isEmpty)
            _buildEmptyState('No staff found for this site')
          else
            ..._siteUsers
                .map((user) => _buildUserCard(user, daysInMonth)),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(String monthStr) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
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
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            }),
          ),
          Column(
            children: [
              Text(monthStr,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
              Text('Select Month', style: AppTextStyles.caption),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int daysInMonth) {
    int totalPresentDays = 0;
    final prefix = DateFormat('yyyy-MM').format(_selectedMonth);
    _siteAttendance.forEach((date, uids) {
      if (date.startsWith(prefix)) totalPresentDays += uids.length;
    });
    final avg = _siteUsers.isEmpty
        ? 0.0
        : (totalPresentDays / (_siteUsers.length * daysInMonth) * 100)
            .clamp(0, 100);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Staff',
            value: _siteUsers.length.toString(),
            icon: Icons.groups,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: _SummaryCard(
            label: 'Avg Attendance',
            value: '${avg.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, int daysInMonth) {
    final presentCount = _getPresentDays(user.uid, _selectedMonth);
    final pct = daysInMonth > 0 ? (presentCount / daysInMonth) : 0.0;

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
                backgroundColor:
                    (user.role == 'site_engineer'
                            ? AppColors.primary
                            : AppColors.success)
                        .withValues(alpha: 0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: user.role == 'site_engineer'
                        ? AppColors.primary
                        : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      user.role.replaceAll('_', ' ').toUpperCase(),
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 10, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius),
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
              value: pct.toDouble(),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct > 0.8
                    ? AppColors.success
                    : (pct > 0.5 ? AppColors.warning : AppColors.error),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(pct * 100).toInt()}% Attendance',
                  style: AppTextStyles.caption),
              if (presentCount > 0)
                TextButton(
                  onPressed: () => _showDates(user),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 20)),
                  child:
                      const Text('View Dates', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDates(UserModel user) {
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attendance Dates', style: AppTextStyles.h3),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text(user.name,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: dates.length,
                itemBuilder: (_, i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle,
                      color: AppColors.success),
                  title: Text(dates[i],
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.people_outline,
                size: 64, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 16),
            Text(msg,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Expenditure Analysis Tab ─────────────────────────────────────────
class _ExpenditureAnalysis extends StatefulWidget {
  final SiteModel site;
  final FirestoreService firestoreService;

  const _ExpenditureAnalysis({
    required this.site,
    required this.firestoreService,
  });

  @override
  State<_ExpenditureAnalysis> createState() => _ExpenditureAnalysisState();
}

class _ExpenditureAnalysisState extends State<_ExpenditureAnalysis>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  List<ExpenditureModel> _entries = [];
  String _filterMonth = ''; // '' means all time

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _filterMonth = DateFormat('yyyy-MM').format(_selectedMonth);
    _loadData();
  }

  late DateTime _selectedMonth;

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final snap =
          await widget.firestoreService.getExpendituresForSite(widget.site.siteId);
      _entries = snap.docs
          .map((d) => ExpenditureModel.fromDocument(d))
          .toList();
    } catch (e) {
      debugPrint('Expenditure load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<ExpenditureModel> get _filtered {
    if (_filterMonth.isEmpty) return _entries;
    return _entries.where((e) => e.date.startsWith(_filterMonth)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final filtered = _filtered;
    final totalCost =
        filtered.fold<double>(0, (sum, e) => sum + e.cost);

    // Category totals
    final Map<String, double> catTotals = {};
    for (final e in filtered) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.cost;
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: AppSpacing.xl),

          // Summary cards
          _buildSummaryRow(totalCost, filtered.length),
          const SizedBox(height: AppSpacing.xxl),

          if (filtered.isEmpty)
            _buildEmptyState()
          else ...[
            // Category breakdown
            Row(
              children: [
                const Icon(Icons.pie_chart_outline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Category Breakdown',
                    style: AppTextStyles.h3.copyWith(fontSize: 16)),
                const Spacer(),
                Text('Tap to view chart',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            _buildCategoryBreakdown(sorted, totalCost, _entries),
            const SizedBox(height: AppSpacing.xxl),

            // Recent entries
            Row(
              children: [
                const Icon(Icons.receipt_long,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Entries',
                    style: AppTextStyles.h3.copyWith(fontSize: 16)),
                const Spacer(),
                Text('${filtered.length} records',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            ...filtered.map((e) => _buildEntryTile(e)),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthStr = _filterMonth.isEmpty
        ? 'All Time'
        : DateFormat('MMMM yyyy').format(_selectedMonth);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
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
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              _filterMonth = DateFormat('yyyy-MM').format(_selectedMonth);
            }),
          ),
          GestureDetector(
            onLongPress: () => setState(() => _filterMonth = ''),
            child: Column(
              children: [
                Text(monthStr,
                    style:
                        AppTextStyles.h3.copyWith(color: AppColors.primary)),
                Text(
                  _filterMonth.isEmpty
                      ? 'Showing all time'
                      : 'Long-press for all time',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              _filterMonth = DateFormat('yyyy-MM').format(_selectedMonth);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double totalCost, int count) {
    final categories = _filtered.map((e) => e.category).toSet().length;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Spend',
            value: '₹${_fmt(totalCost)}',
            icon: Icons.currency_rupee,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: _SummaryCard(
            label: 'Entries',
            value: count.toString(),
            icon: Icons.receipt_long,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: _SummaryCard(
            label: 'Categories',
            value: categories.toString(),
            icon: Icons.category_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
      List<MapEntry<String, double>> sorted, double total,
      List<ExpenditureModel> allEntries) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: sorted.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = _catColor(entry.key);
          return GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CategoryChartSheet(
                category: entry.key,
                allEntries: allEntries,
                color: color,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(kCategoryIcons[entry.key] ?? '📦',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.key,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text('₹${_fmt(entry.value)}',
                          style: AppTextStyles.body.copyWith(
                              color: color, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${(pct * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.caption),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios,
                          size: 11, color: color.withValues(alpha: 0.7)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntryTile(ExpenditureModel e) {
    final color = _catColor(e.category);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            child: Text(kCategoryIcons[e.category] ?? '📦',
                style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.category,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('${e.quantity} ${e.unit}  •  ${e.date}',
                    style: AppTextStyles.caption),
                if (e.notes.isNotEmpty)
                  Text(e.notes,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('₹${e.cost.toStringAsFixed(0)}',
              style: AppTextStyles.body.copyWith(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 52, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            Text('No expenditures recorded',
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Engineers log costs from the site detail screen',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Color _catColor(String category) {
    const colors = {
      'Cement': Color(0xFF6B7280),
      'Steel': Color(0xFF3B82F6),
      'Paint': Color(0xFF8B5CF6),
      'Plumbing': Color(0xFF06B6D4),
      'Sanitary': Color(0xFF10B981),
      'Hardware': Color(0xFFF59E0B),
      'Electricals': Color(0xFFEF4444),
    };
    return colors[category] ?? AppColors.primary;
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Shared Summary Card ──────────────────────────────────────────────
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.m),
          Text(value,
              style: AppTextStyles.h2.copyWith(color: color, fontSize: 18)),
          Text(label,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
