import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported raw material categories
const List<String> kExpenditureCategories = [
  'Cement',
  'Steel',
  'Paint',
  'Plumbing',
  'Sanitary',
  'Hardware',
  'Electricals',
];

const Map<String, String> kCategoryIcons = {
  'Cement': '🏗️',
  'Steel': '⚙️',
  'Paint': '🎨',
  'Plumbing': '🔧',
  'Sanitary': '🚿',
  'Hardware': '🔩',
  'Electricals': '⚡',
};

class ExpenditureModel {
  final String id;
  final String siteId;
  final String category;     // one of kExpenditureCategories
  final double quantity;     // e.g. 50 (bags, meters, units…)
  final String unit;         // e.g. 'bags', 'kg', 'units'
  final double cost;         // total cost in ₹
  final String date;         // yyyy-MM-dd
  final String addedBy;      // UID of the site engineer
  final String notes;        // optional
  final DateTime createdAt;

  const ExpenditureModel({
    required this.id,
    required this.siteId,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.date,
    required this.addedBy,
    required this.notes,
    required this.createdAt,
  });

  factory ExpenditureModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenditureModel(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'units',
      cost: (data['cost'] ?? 0).toDouble(),
      date: data['date'] ?? '',
      addedBy: data['addedBy'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'siteId': siteId,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'cost': cost,
        'date': date,
        'addedBy': addedBy,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
