import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/order_status_badge.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Orders'),
          automaticallyImplyLeading: false),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getMyOrders(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No orders yet',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Build your first PC to get started!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final order = OrderModel.fromFirestore(docs[i]);

              // Calculate subtotal and discount
              final subtotal = order.items.fold<double>(
                  0,
                  (s, item) =>
                      s + (item['price'] as num).toDouble());
              final discount = subtotal - order.total;
              final hasDiscount = discount > 0.5;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      OrderStatusBadge(status: order.status),
                      if (order.createdAt != null)
                        Text(
                          DateFormat('MMM d, y')
                              .format(order.createdAt!),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasDiscount)
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration:
                                  TextDecoration.lineThrough),
                        ),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                            fontSize: 15),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),

                          // Components
                          const Text('Components:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          ...order.items.map((item) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• ${item['emoji'] ?? ''} ${item['name']}',
                                        style: const TextStyle(
                                            fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      '\$${(item['price'] as num).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )),

                          const Divider(height: 20),

                          // Price breakdown
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal',
                                  style: TextStyle(
                                      color: Colors.grey)),
                              Text(
                                  '\$${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Colors.grey)),
                            ],
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount saved',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight:
                                            FontWeight.w500)),
                                Text(
                                    '-\$${discount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight:
                                            FontWeight.w500)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                '\$${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                    fontSize: 16),
                              ),
                            ],
                          ),

                          // Notes
                          if (order.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Your Notes:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue
                                        .withOpacity(0.2)),
                              ),
                              child: Text(order.description,
                                  style: const TextStyle(
                                      fontSize: 13)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}