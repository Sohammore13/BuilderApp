import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/expenditure_model.dart';

/// Full-screen chart bottom sheet shown when the user taps a category row.
class CategoryChartSheet extends StatefulWidget {
  final String category;
  final List<ExpenditureModel> allEntries; // all entries for this site
  final Color color;

  const CategoryChartSheet({
    super.key,
    required this.category,
    required this.allEntries,
    required this.color,
  });

  @override
  State<CategoryChartSheet> createState() => _CategoryChartSheetState();
}

class _CategoryChartSheetState extends State<CategoryChartSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  /// Only entries for this category
  late final List<ExpenditureModel> _catEntries;

  /// month-label  →  total cost
  late final Map<String, double> _monthlyTotals;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    _catEntries = widget.allEntries
        .where((e) => e.category == widget.category)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Aggregate by yyyy-MM
    final Map<String, double> costs = {};
    for (final e in _catEntries) {
      final month = e.date.substring(0, 7); // yyyy-MM
      costs[month] = (costs[month] ?? 0) + e.cost;
    }
    _monthlyTotals = costs;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCost =
        _catEntries.fold<double>(0, (acc, e) => acc + e.cost);
    final totalQty =
        _catEntries.fold<double>(0, (acc, e) => acc + e.quantity);
    final avgCost = _catEntries.isEmpty ? 0.0 : totalCost / _catEntries.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    ),
                    child: Text(
                      kCategoryIcons[widget.category] ?? '📦',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.category,
                            style: AppTextStyles.h3
                                .copyWith(color: widget.color)),
                        Text('${_catEntries.length} entries · all time',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // KPI row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _Kpi(
                    label: 'Total Cost',
                    value: '₹${_fmt(totalCost)}',
                    color: widget.color,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  _Kpi(
                    label: 'Total Qty',
                    value: _fmtQty(totalQty),
                    color: widget.color,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  _Kpi(
                    label: 'Avg / Entry',
                    value: '₹${_fmt(avgCost)}',
                    color: widget.color,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: TabBar(
                controller: _tabs,
                labelColor: widget.color,
                unselectedLabelColor: AppColors.onSurfaceMuted,
                indicator: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '📊  Monthly Cost'),
                  Tab(text: '📋  All Entries'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  // ── Bar chart ──────────────────────────────────────────
                  _monthlyTotals.isEmpty
                      ? _emptyState()
                      : _BarChartView(
                          monthlyTotals: _monthlyTotals,
                          color: widget.color,
                          scrollCtrl: scrollCtrl,
                        ),

                  // ── Entries list ───────────────────────────────────────
                  _catEntries.isEmpty
                      ? _emptyState()
                      : _EntriesListView(
                          entries: _catEntries,
                          color: widget.color,
                          scrollCtrl: scrollCtrl,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 52, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 12),
            Text('No data yet', style: AppTextStyles.body),
          ],
        ),
      );

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtQty(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────
class _BarChartView extends StatelessWidget {
  final Map<String, double> monthlyTotals;
  final Color color;
  final ScrollController scrollCtrl;

  const _BarChartView({
    required this.monthlyTotals,
    required this.color,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final months = monthlyTotals.keys.toList()..sort();
    final values = months.map((m) => monthlyTotals[m]!).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    final bars = List.generate(months.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            color: color,
            width: months.length <= 4 ? 28 : 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.1,
              color: color.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });

    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          Container(
            height: 260,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: BarChart(
              BarChartData(
                barGroups: bars,
                maxY: maxVal * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          _fmtAxis(val),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = months[i].split('-');
                        final label = DateFormat('MMM yy').format(
                          DateTime(int.parse(parts[0]), int.parse(parts[1])),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      final m = months[group.x];
                      final parts = m.split('-');
                      final label = DateFormat('MMM yyyy').format(
                        DateTime(int.parse(parts[0]), int.parse(parts[1])),
                      );
                      return BarTooltipItem(
                        '$label\n₹${_fmtFull(rod.toY)}',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Monthly breakdown list
          Text('Monthly Breakdown',
              style: AppTextStyles.h3.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.m),
          ...List.generate(months.length, (i) {
            final m = months[months.length - 1 - i]; // newest first
            final parts = m.split('-');
            final label = DateFormat('MMMM yyyy').format(
              DateTime(int.parse(parts[0]), int.parse(parts[1])),
            );
            final cost = monthlyTotals[m]!;
            final pct = maxVal > 0 ? cost / maxVal : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('₹${_fmtFull(cost)}',
                          style: AppTextStyles.body.copyWith(
                              color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _fmtAxis(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(0)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtFull(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Entries list view ────────────────────────────────────────────────
class _EntriesListView extends StatelessWidget {
  final List<ExpenditureModel> entries;
  final Color color;
  final ScrollController scrollCtrl;

  const _EntriesListView({
    required this.entries,
    required this.color,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    // newest first
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (_, i) {
        final e = sorted[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Text(kCategoryIcons[e.category] ?? '📦',
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.date,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text('${e.quantity} ${e.unit}',
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
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        );
      },
    );
  }
}

// ─── KPI chip ─────────────────────────────────────────────────────────
class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Kpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.h3.copyWith(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
