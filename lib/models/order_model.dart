import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final String description;
  final DateTime? createdAt;
  final int? rating;        // ← added (1-5 stars)
  final String? review;     // ← added (optional comment)
  final DateTime? ratedAt;  // ← added

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.description,
    this.createdAt,
    this.rating,
    this.review,
    this.ratedAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(d['items'] ?? []),
      total: (d['total'] ?? 0).toDouble(),
      status: d['status'] ?? 'pending',
      description: d['description'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      rating: d['rating'] as int?,
      review: d['review'] as String?,
      ratedAt: (d['ratedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items,
        'total': total,
        'status': status,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };

  bool get isDelivered => status == 'delivered';
  bool get isRated => rating != null;
}