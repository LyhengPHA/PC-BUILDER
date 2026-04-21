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
const _amber = Color(0xFFFFB800);

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

  // ── Rating dialog ─────────────────────────────────────────────
  void _showRatingDialog(BuildContext context) {
    int selectedRating = 0;
    final reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: _amber, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Rate Your Order',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),

                const SizedBox(height: 20),

                // Stars
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => setS(() => selectedRating = star),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40,
                            color: star <= selectedRating
                                ? _amber
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Star label
                if (selectedRating > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _ratingLabel(selectedRating),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _amber,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Review text field
                TextField(
                  controller: reviewCtrl,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Leave a comment (optional)...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: _surface,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedRating == 0
                            ? null
                            : () async {
                                await FirestoreService().rateOrder(
                                  widget.order.id,
                                  selectedRating,
                                  reviewCtrl.text.trim(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Thanks for your review!',
                                          style: GoogleFonts.inter()),
                                    ]),
                                    backgroundColor: Colors.amber[700],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    margin: const EdgeInsets.all(12),
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amber,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[200],
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Submit',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor 😞';
      case 2: return 'Fair 😐';
      case 3: return 'Good 🙂';
      case 4: return 'Great 😊';
      case 5: return 'Excellent! 🤩';
      default: return '';
    }
  }

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
                                DateFormat('MMM d, y')
                                    .format(order.createdAt!),
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

                  // ── Rating section ──────────────────────────────
                  if (order.isDelivered) ...[
                    const SizedBox(height: 14),
                    Divider(color: Colors.grey.shade100),
                    const SizedBox(height: 14),

                    if (order.isRated) ...[
                      // Already rated — show their rating
                      Text('Your Rating',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          )),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Stars display
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < order.rating!
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 22,
                                color: i < order.rating!
                                    ? _amber
                                    : Colors.grey[300],
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _ratingLabelStatic(order.rating!),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _amber,
                            ),
                          ),
                        ],
                      ),
                      if (order.review != null &&
                          order.review!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _amber.withOpacity(0.2)),
                          ),
                          child: Text(
                            '"${order.review}"',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      // Not rated yet — show rate button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showRatingDialog(context),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: Text('Rate this order',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _amber,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ratingLabelStatic(int rating) {
    switch (rating) {
      case 1: return 'Poor 😞';
      case 2: return 'Fair 😐';
      case 3: return 'Good 🙂';
      case 4: return 'Great 😊';
      case 5: return 'Excellent! 🤩';
      default: return '';
    }
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