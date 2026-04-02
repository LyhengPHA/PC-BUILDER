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

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Orders',
                            style: GoogleFonts.syne(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        Text('Track your builds',
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
              stream: FirestoreService().getMyOrders(),
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Icon(Icons.receipt_long_outlined,
                              size: 36, color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 16),
                        Text('No orders yet',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            )),
                        const SizedBox(height: 6),
                        Text('Build your first PC to get started!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
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

                    return _OrderCard(
                      order: order,
                      subtotal: subtotal,
                      discount: discount,
                      hasDiscount: hasDiscount,
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
class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final double subtotal;
  final double discount;
  final bool hasDiscount;

  const _OrderCard({
    required this.order,
    required this.subtotal,
    required this.discount,
    required this.hasDiscount,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [

                  // Order icon
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

                  // Order info
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

                  // Price + expand
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

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
                                child: Text(
                                  item['emoji'] ?? '🔧',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['name'],
                                style: GoogleFonts.inter(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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

                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 8),

                  // Price breakdown
                  _PriceRow(
                    label: 'Subtotal',
                    value: '\$${widget.subtotal.toStringAsFixed(2)}',
                    labelColor: Colors.grey[500]!,
                    valueColor: Colors.grey[500]!,
                  ),
                  if (widget.hasDiscount) ...[
                    const SizedBox(height: 6),
                    _PriceRow(
                      label: '🏷️ Discount saved',
                      value: '-\$${widget.discount.toStringAsFixed(2)}',
                      labelColor: Colors.green[600]!,
                      valueColor: Colors.green[600]!,
                      isBold: true,
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

                  // Notes
                  if (order.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Your Notes',
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
                        color: _surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        order.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: labelColor,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            )),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: valueColor,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            )),
      ],
    );
  }
}