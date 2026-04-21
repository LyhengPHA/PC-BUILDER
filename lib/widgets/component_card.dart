import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/component_model.dart';

const _primary = Color(0xFF1A6BFF);
const _surface = Color(0xFFF5F7FF);

class ComponentCard extends StatelessWidget {
  final ComponentModel component;
  const ComponentCard({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Image / Emoji ──────────────────────────────────
            SizedBox(
              height: 100,
              width: double.infinity,
              child: component.imageUrl != null &&
                      component.imageUrl!.isNotEmpty
                  ? Image.network(
                      component.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: _surface,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => _emojiPlaceholder(),
                    )
                  : _emojiPlaceholder(),
            ),

            // ── Details ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE8FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        component.type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Name
                    Text(
                      component.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Spec
                    Text(
                      component.spec,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price + stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${component.price.toStringAsFixed(0)}',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        _StockDot(inStock: component.inStock),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPlaceholder() {
    return Container(
      color: _surface,
      child: Center(
        child: Text(
          component.emoji,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

// ── Stock indicator dot ───────────────────────────────────────────
class _StockDot extends StatelessWidget {
  final bool inStock;
  const _StockDot({required this.inStock});

  @override
  Widget build(BuildContext context) {
    final color = inStock ? const Color(0xFF4CAF50) : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: inStock ? const Color(0xFF4CAF50) : Colors.red[600],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            inStock ? 'In Stock' : 'Out',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: inStock
                  ? const Color(0xFF4CAF50)
                  : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}