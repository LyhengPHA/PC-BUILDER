import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountModel {
  final String id;
  final String code;
  final double percent;
  final bool active;
  final DateTime? expiresAt;
  final String description;

  DiscountModel({
    required this.id,
    required this.code,
    required this.percent,
    required this.active,
    this.expiresAt,
    required this.description,
  });

  factory DiscountModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DiscountModel(
      id: doc.id,
      code: d['code'] ?? '',
      percent: (d['percent'] ?? 0).toDouble(),
      active: d['active'] ?? false,
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      description: d['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'percent': percent,
        'active': active,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'description': description,
      };
}
