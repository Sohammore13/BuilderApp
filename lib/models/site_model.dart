import 'package:cloud_firestore/cloud_firestore.dart';

class SiteModel {
  final String siteId;
  final String siteName;
  final String location;
  final DateTime startDate;
  final String createdBy;
  final List<String> assignedEngineers;
  final List<String> assignedPurchaseTeam;
  final DateTime createdAt;

  const SiteModel({
    required this.siteId,
    required this.siteName,
    required this.location,
    required this.startDate,
    required this.createdBy,
    required this.assignedEngineers,
    required this.assignedPurchaseTeam,
    required this.createdAt,
  });

  factory SiteModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SiteModel(
      siteId: doc.id,
      siteName: data['siteName'] as String? ?? '',
      location: data['location'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      assignedEngineers: List<String>.from(data['assignedEngineers'] ?? []),
      assignedPurchaseTeam: List<String>.from(data['assignedPurchaseTeam'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteName': siteName,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'createdBy': createdBy,
      'assignedEngineers': assignedEngineers,
      'assignedPurchaseTeam': assignedPurchaseTeam,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
