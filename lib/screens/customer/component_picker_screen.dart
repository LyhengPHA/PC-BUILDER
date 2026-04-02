import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/component_model.dart';
import '../../services/firestore_service.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

class ComponentPickerScreen extends StatelessWidget {
  final String type;
  const ComponentPickerScreen({super.key, required this.type});

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select ${type.toUpperCase()}',
                            style: GoogleFonts.syne(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        Text('Choose the best component for your build',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Component list ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getComponentsInStock(type: type),
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
                          child: Icon(Icons.inventory_2_outlined,
                              size: 32, color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 16),
                        Text('No ${type.toUpperCase()} available',
                            style: GoogleFonts.syne(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                            )),
                        const SizedBox(height: 6),
                        Text('Check back later!',
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
                    final c = ComponentModel.fromFirestore(docs[i]);
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, c),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [

                              // ── Image / Emoji ──
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: c.imageUrl != null &&
                                          c.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          c.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Center(
                                                child: Text(c.emoji,
                                                    style: const TextStyle(
                                                        fontSize: 28)),
                                              ),
                                        )
                                      : Center(
                                          child: Text(c.emoji,
                                              style: const TextStyle(
                                                  fontSize: 28)),
                                        ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // ── Info ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Type badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDDE8FF),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(type.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _primary,
                                            letterSpacing: 0.5,
                                          )),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(c.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Text(c.spec,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey[400],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // ── Price + Select ──
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '\$${c.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.syne(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _primary,
                                      )),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _primary,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text('Select',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        )),
                                  ),
                                ],
                              ),
                            ],
                          ),
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