import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/order_status_badge.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  static const _statuses = ['pending', 'building', 'shipped', 'delivered'];

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [

          // ── Gradient Header ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryDark, _primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Management',
                            style: GoogleFonts.syne(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        Text('View and update order status',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Order list ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.getAllOrders(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primary));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Icon(Icons.receipt_long_outlined,
                              size: 32, color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 16),
                        Text('No orders yet',
                            style: GoogleFonts.syne(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                            )),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final order = OrderModel.fromFirestore(docs[i]);
                    final subtotal = order.items.fold<double>(
                        0, (s, item) => s + (item['price'] as num).toDouble());
                    final discount = subtotal - order.total;
                    final hasDiscount = discount > 0.5;

                    return _AdminOrderCard(
                      order: order,
                      subtotal: subtotal,
                      discount: discount,
                      hasDiscount: hasDiscount,
                      fs: fs,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _AdminOrderCard extends StatefulWidget {
  final OrderModel order;
  final double subtotal;
  final double discount;
  final bool hasDiscount;
  final FirestoreService fs;

  const _AdminOrderCard({
    required this.order,
    required this.subtotal,
    required this.discount,
    required this.hasDiscount,
    required this.fs,
  });

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _expanded = false;

  static const _statuses = ['pending', 'building', 'shipped', 'delivered'];

  Color _statusColor(String s) => switch (s) {
        'pending'   => const Color(0xFFFF9800),
        'building'  => _primary,
        'shipped'   => const Color(0xFF9C27B0),
        'delivered' => const Color(0xFF4CAF50),
        _           => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── Card header ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            OrderStatusBadge(status: order.status),
                            if (order.createdAt != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, y').format(order.createdAt!),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.hasDiscount)
                        Text(
                          '\$${widget.subtotal.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        '\$${order.total.toStringAsFixed(0)}',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[400], size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ──
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Customer ID
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Customer: ${order.userId.substring(0, 12)}...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Components
                  Text('Components',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      )),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(item['emoji'] ?? '🔧',
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item['name'],
                                  style: GoogleFonts.inter(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              '\$${(item['price'] as num).toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),

                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 4),

                  // Price breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[500])),
                      Text('\$${widget.subtotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                  if (widget.hasDiscount) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            )),
                        Text('-\$${widget.discount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            )),
                        Text('\$${order.total.toStringAsFixed(2)}',
                            style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            )),
                      ],
                    ),
                  ),

                  // Customer notes
                  if (order.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Customer Notes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notes_rounded,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(order.description,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Status update
                  Text('Update Status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      )),
                  const SizedBox(height: 10),
                  Row(
                    children: _statuses.map((s) {
                      final isCurrent = order.status == s;
                      final color = _statusColor(s);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: isCurrent
                                ? null
                                : () => widget.fs.updateOrderStatus(order.id, s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? color.withOpacity(0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrent
                                      ? color.withOpacity(0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                s[0].toUpperCase() + s.substring(1),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent ? color : Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}