import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primary = Color(0xFF1A6BFF);
const _surface = Color(0xFFF5F7FF);

class BuildProgressIndicator extends StatelessWidget {
  final int selected;
  final int total;
  final double totalPrice;

  const BuildProgressIndicator({
    super.key,
    required this.selected,
    required this.total,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : selected / total;
    final isComplete = selected == total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Parts selected label
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isComplete
                          ? Icons.check_circle_rounded
                          : Icons.build_rounded,
                      size: 15,
                      color: isComplete
                          ? const Color(0xFF4CAF50)
                          : _primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$selected',
                          style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text: ' / $total parts',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Total price
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: _surface,
              valueColor: AlwaysStoppedAnimation(
                isComplete ? const Color(0xFF4CAF50) : _primary,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Status text
          Text(
            isComplete
                ? '🎉 All parts selected! Ready to order.'
                : '${total - selected} more part${total - selected == 1 ? '' : 's'} needed',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isComplete
                  ? const Color(0xFF4CAF50)
                  : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}