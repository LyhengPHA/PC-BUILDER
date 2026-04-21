import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/discount_model.dart';
import '../../services/firestore_service.dart';

// ── Design tokens (mirrors AdminDashboard) ────────────────────
const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);
const _green = Color(0xFF4CAF50);

class DiscountScreen extends StatelessWidget {
  const DiscountScreen({super.key});

  // ── Add dialog ───────────────────────────────────────────────
  void _showAddDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final percentCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? expiresAt;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_offer_rounded,
                              color: _green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'New Promo Code',
                          style: GoogleFonts.syne(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _DialogField(
                      controller: codeCtrl,
                      label: 'Code (e.g. SAVE10)',
                      icon: Icons.confirmation_number_outlined,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    _DialogField(
                      controller: percentCtrl,
                      label: 'Discount %',
                      icon: Icons.percent_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _DialogField(
                      controller: descCtrl,
                      label: 'Description',
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 12),

                    // Expiry date picker
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setS(() => expiresAt = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              expiresAt == null
                                  ? 'Set Expiry Date'
                                  : DateFormat('MMM d, y').format(expiresAt!),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: expiresAt == null
                                    ? Colors.grey[500]
                                    : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            if (expiresAt != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Set',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (codeCtrl.text.isEmpty ||
                                  percentCtrl.text.isEmpty) return;
                              await FirestoreService().addDiscount({
                                'code': codeCtrl.text.toUpperCase(),
                                'percent':
                                    double.tryParse(percentCtrl.text) ?? 0,
                                'description': descCtrl.text,
                                'active': true,
                                'expiresAt': expiresAt,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Add Code',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          // ── Gradient Header ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryDark, _primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_offer_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Discount Codes',
                          style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Add button in header
                        GestureDetector(
                          onTap: () => _showAddDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Promo & Discounts',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage promo codes',
                      style: GoogleFonts.syne(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.getDiscounts(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _EmptyState(
                    onAdd: () => _showAddDialog(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: docs.length + 1, // +1 for section label
                  itemBuilder: (_, i) {
                    // Section label
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${docs.length} CODE${docs.length == 1 ? '' : 'S'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    }

                    final d = DiscountModel.fromFirestore(docs[i - 1]);
                    return _DiscountCard(
                      discount: d,
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
// Discount Card
// ════════════════════════════════════════════════════════════════
class _DiscountCard extends StatelessWidget {
  final DiscountModel discount;
  final FirestoreService fs;

  const _DiscountCard({required this.discount, required this.fs});

  bool get _isExpired =>
      discount.expiresAt != null &&
      discount.expiresAt!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final d = discount;
    final expired = _isExpired;
    final statusColor = expired
        ? Colors.red
        : d.active
            ? _green
            : Colors.orange;
    final statusLabel = expired ? 'Expired' : d.active ? 'Active' : 'Inactive';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            // Top row: percent badge + code + status badge
            Row(
              children: [
                // Percent badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${d.percent.toInt()}% OFF',
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Code
                Expanded(
                  child: Text(
                    d.code,
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Description
            if (d.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                d.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
            ],

            // Expiry
            if (d.expiresAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: expired ? Colors.red[400] : Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expired
                        ? 'Expired ${DateFormat('MMM d, y').format(d.expiresAt!)}'
                        : 'Expires ${DateFormat('MMM d, y').format(d.expiresAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: expired ? Colors.red[400] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Bottom row: toggle + delete
            Row(
              children: [
                Icon(
                  d.active && !expired
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  color: d.active && !expired ? _green : Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  d.active ? 'Enabled' : 'Disabled',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),

                // Toggle switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: d.active,
                    activeColor: _green,
                    onChanged: (v) => fs.updateDiscount(d.id, {'active': v}),
                  ),
                ),

                const SizedBox(width: 4),

                // Delete button
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Code?',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${discount.code}" permanently?',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              fs.deleteDiscount(discount.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Empty State
// ════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.local_offer_rounded,
                  size: 34, color: _green),
            ),
            const SizedBox(height: 16),
            Text(
              'No Promo Codes',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first discount code to\nattract more customers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add Code',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Dialog text field
// ════════════════════════════════════════════════════════════════
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}