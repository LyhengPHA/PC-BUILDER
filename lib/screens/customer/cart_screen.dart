import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../services/firestore_service.dart';

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

  List<MapEntry<String, ComponentModel>> get _items =>
      widget.selectedBuild.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!))
          .toList();

  double get _subtotal =>
      _items.fold(0.0, (s, e) => s + e.value.price);

  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _total => _subtotal - _discountAmount;

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _applyingPromo = true;
      _promoMessage = null;
    });
    try {
      final doc = await FirestoreService().validateDiscount(code);
      if (doc != null) {
        final data = doc.data() as Map<String, dynamic>;
        final percent = (data['percent'] ?? 0).toDouble();
        setState(() {
          _discountPercent = percent;
          _promoMessage =
              '✅ ${percent.toStringAsFixed(0)}% discount applied!';
        });
      } else {
        setState(() {
          _discountPercent = 0;
          _promoMessage = '❌ Invalid or expired code';
        });
      }
    } catch (e) {
      setState(() {
        _discountPercent = 0;
        _promoMessage = '❌ Could not validate code';
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
          const SnackBar(
              content: Text('Order placed successfully! 🎉'),
              backgroundColor: Colors.green));
      // Pop back with true to signal builder to clear
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to place order: $e'),
              backgroundColor: Colors.red));
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Components list ──────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Selected Components',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      ..._items.map((e) => ListTile(
                            dense: true,
                            leading: Text(e.value.emoji,
                                style: const TextStyle(fontSize: 22)),
                            title: Text(e.value.name),
                            subtitle: Text(e.value.spec,
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12)),
                            trailing: Text(
                              '\$${e.value.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Promo code ───────────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Promo Code',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Enter code e.g. SAVE20',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed:
                                  _applyingPromo ? null : _applyPromo,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF1565C0),
                                  foregroundColor: Colors.white),
                              child: _applyingPromo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Apply'),
                            ),
                          ],
                        ),
                        if (_promoMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(_promoMessage!,
                              style: TextStyle(
                                  color: _discountPercent > 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Notes ────────────────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Notes (optional)',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Any special requests...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Summary + Place Order ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('\$${_subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (_discountPercent > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Discount (${_discountPercent.toStringAsFixed(0)}%)',
                            style:
                                const TextStyle(color: Colors.green)),
                        Text(
                            '-\$${_discountAmount.toStringAsFixed(2)}',
                            style:
                                const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text('\$${_total.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: cs.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _placing ? null : _placeOrder,
                      icon: const Icon(Icons.check_circle),
                      label: _placing
                          ? const Text('Placing Order...')
                          : const Text('Place Order'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}