import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/firestore_service.dart';
import '../../models/site_model.dart';
import '../manager/manager_analysis_tab.dart'
    show SiteSelectionView, SiteAnalyticsDetail;

class OwnerAnalyticsTab extends StatefulWidget {
  const OwnerAnalyticsTab({super.key});

  @override
  State<OwnerAnalyticsTab> createState() => _OwnerAnalyticsTabState();
}

class _OwnerAnalyticsTabState extends State<OwnerAnalyticsTab> {
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
      final sites = await _firestoreService.streamSitesForOwner('').first;
      _allSites = sites;
    } catch (e) {
      debugPrint('Error loading sites for owner analytics: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
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
      heading: 'All Sites',
    );
  }
}
