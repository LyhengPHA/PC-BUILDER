import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/component_model.dart';
import '../../services/firestore_service.dart';

class ComponentPickerScreen extends StatelessWidget {
  final String type;
  const ComponentPickerScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select ${type.toUpperCase()}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getComponentsInStock(type: type),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
                child: Text('No ${type.toUpperCase()} available'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final c = ComponentModel.fromFirestore(docs[i]);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(c.emoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(c.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c.spec),
                  trailing: Text(
                    '\$${c.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0)),
                  ),
                  onTap: () => Navigator.pop(context, c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
