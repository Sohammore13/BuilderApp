import 'package:cloud_firestore/cloud_firestore.dart';

class SiteModel {
  final String siteId;
  final String siteName;
  final String location;
  final double latitude;
  final double longitude;
  final double radius;
  final DateTime startDate;
  final String createdBy;
  final List<String> assignedEngineers;
  final List<String> assignedPurchaseTeam;
  final DateTime createdAt;

  const SiteModel({
    required this.siteId,
    required this.siteName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.radius,
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
      siteName: data['siteName'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      radius: (data['radius'] ?? 250).toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      assignedEngineers: List<String>.from(data['assignedEngineers'] ?? []),
      assignedPurchaseTeam: List<String>.from(
        data['assignedPurchaseTeam'] ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteName': siteName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'startDate': Timestamp.fromDate(startDate),
      'createdBy': createdBy,
      'assignedEngineers': assignedEngineers,
      'assignedPurchaseTeam': assignedPurchaseTeam,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
