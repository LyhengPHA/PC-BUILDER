import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/component_model.dart';
import '../../services/firestore_service.dart';
import 'add_edit_product_screen.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';

  final _types = ['all', 'cpu', 'gpu', 'ram', 'ssd', 'motherboard', 'psu', 'case'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, ComponentModel c, FirestoreService fs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Component',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: Colors.red[700])),
        content: Text('Delete "${c.name}"? This cannot be undone.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok == true) await fs.deleteComponent(c.id);
  }

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
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inventory',
                                  style: GoogleFonts.syne(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                              Text('Manage your components',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  )),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const AddEditProductScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 5),
                                Text('Add',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search components...',
                          hintStyle: GoogleFonts.inter(
                              color: Colors.grey[400], fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.grey, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _types.length,
              itemBuilder: (_, i) {
                final t = _types[i];
                final selected = _filterType == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _primary : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        t == 'all' ? 'All' : t.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Component list ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.getComponents(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primary));
                }

                final allDocs = snap.data?.docs ?? [];
                final docs = allDocs.where((d) {
                  final c = ComponentModel.fromFirestore(d);
                  final matchType = _filterType == 'all' || c.type == _filterType;
                  final matchSearch = _searchQuery.isEmpty ||
                      c.name.toLowerCase().contains(_searchQuery) ||
                      c.spec.toLowerCase().contains(_searchQuery);
                  return matchType && matchSearch;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No components found',
                            style: GoogleFonts.inter(color: Colors.grey[400])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final c = ComponentModel.fromFirestore(docs[i]);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [

                           // After
Container(
  width: 50,
  height: 50,
  decoration: BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(10),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: c.imageUrl != null && c.imageUrl!.isNotEmpty
        ? Image.network(
            c.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(c.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          )
        : Center(
            child: Text(c.emoji,
                style: const TextStyle(fontSize: 24)),
          ),
  ),
),

                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDDE8FF),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(c.type.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: _primary,
                                            )),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: c.inStock
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          c.inStock ? 'In Stock' : 'Out',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: c.inStock
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(c.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(c.spec,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Price + actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${c.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.syne(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    )),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.edit_rounded,
                                      color: _primary,
                                      onTap: () => Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  AddEditProductScreen(
                                                      component: c))),
                                    ),
                                    const SizedBox(width: 6),
                                    _ActionBtn(
                                      icon: Icons.delete_rounded,
                                      color: Colors.red[400]!,
                                      onTap: () =>
                                          _confirmDelete(context, c, fs),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}