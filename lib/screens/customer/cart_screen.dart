import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/component_model.dart';
import '../../services/firestore_service.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

class CartScreen extends StatefulWidget {
  final Map<String, ComponentModel?> selectedBuild;
  const CartScreen({super.key, required this.selectedBuild});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  double _discountPercent = 0;
  bool _applyingPromo = false;
  bool _placing = false;
  String? _promoMessage;
  bool _promoSuccess = false;

  List<MapEntry<String, ComponentModel>> get _items =>
      widget.selectedBuild.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!))
          .toList();

  double get _subtotal => _items.fold(0.0, (s, e) => s + e.value.price);
  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _total => _subtotal - _discountAmount;

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _applyingPromo = true; _promoMessage = null; });
    try {
      final doc = await FirestoreService().validateDiscount(code);
      if (doc != null) {
        final data = doc.data() as Map<String, dynamic>;
        final percent = (data['percent'] ?? 0).toDouble();
        setState(() {
          _discountPercent = percent;
          _promoSuccess = true;
          _promoMessage = '${percent.toStringAsFixed(0)}% discount applied!';
        });
      } else {
        setState(() {
          _discountPercent = 0;
          _promoSuccess = false;
          _promoMessage = 'Invalid or expired code';
        });
      }
    } catch (e) {
      setState(() {
        _discountPercent = 0;
        _promoSuccess = false;
        _promoMessage = 'Could not validate code';
      });
    } finally {
      setState(() => _applyingPromo = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) return;
    setState(() => _placing = true);
    try {
      await FirestoreService().placeOrder(
        widget.selectedBuild,
        _total,
        description: _noteCtrl.text.trim(),
        discount: _discountAmount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Order placed successfully! 🎉', style: GoogleFonts.inter()),
          ]),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review Order',
                              style: GoogleFonts.syne(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                          Text('${_items.length} component${_items.length != 1 ? 's' : ''} selected',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              )),
                        ],
                      ),
                    ),
                    // Total badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('\$${_total.toStringAsFixed(0)}',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [

                // ── Components ──
                _SectionCard(
                  title: 'Selected Components',
                  icon: Icons.build_rounded,
                  child: Column(
                    children: _items.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(e.value.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.value.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(e.value.spec,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Text('\$${e.value.price.toStringAsFixed(0)}',
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              )),
                        ],
                      ),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Promo Code ──
                _SectionCard(
                  title: 'Promo Code',
                  icon: Icons.local_offer_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Enter code e.g. SAVE20',
                                hintStyle: GoogleFonts.inter(
                                    color: Colors.grey[400], fontSize: 13),
                                filled: true,
                                fillColor: _surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _primary, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _applyingPromo ? null : _applyPromo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _applyingPromo
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text('Apply',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      if (_promoMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _promoSuccess
                                ? Colors.green.withOpacity(0.08)
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _promoSuccess
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined,
                                size: 16,
                                color: _promoSuccess
                                    ? Colors.green[600]
                                    : Colors.red[600],
                              ),
                              const SizedBox(width: 8),
                              Text(_promoMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: _promoSuccess
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Notes ──
                _SectionCard(
                  title: 'Order Notes (optional)',
                  icon: Icons.note_alt_rounded,
                  child: TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Any special requests...',
                      hintStyle: GoogleFonts.inter(
                          color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: _surface,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primary, width: 1.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Summary + Place Order ────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[500])),
                      Text('\$${_subtotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),

                  // Discount
                  if (_discountPercent > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Discount (${_discountPercent.toStringAsFixed(0)}%)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            )),
                        Text('-\$${_discountAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Total
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            )),
                        Text('\$${_total.toStringAsFixed(2)}',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Place Order button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _placing ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[200],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _placing
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text('Place Order',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: _primary),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}