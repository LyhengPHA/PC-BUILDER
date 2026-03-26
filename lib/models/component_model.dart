import 'package:cloud_firestore/cloud_firestore.dart';

class ComponentModel {
  final String id;
  final String type;
  final String name;
  final String spec;
  final double price;
  final String emoji;
  final bool inStock;
  final String? imageUrl;

  ComponentModel({
    required this.id,
    required this.type,
    required this.name,
    required this.spec,
    required this.price,
    required this.emoji,
    required this.inStock,
    this.imageUrl,
  });

  factory ComponentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComponentModel(
      id: doc.id,
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      spec: data['spec'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      emoji: data['emoji'] ?? '🖥️',
      inStock: data['inStock'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'name': name,
        'spec': spec,
        'price': price,
        'emoji': emoji,
        'inStock': inStock,
        'imageUrl': imageUrl,
      };
}