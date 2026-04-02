import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
        'pending'   => const Color(0xFFFF9800),
        'building'  => const Color(0xFF1A6BFF),
        'shipped'   => const Color(0xFF9C27B0),
        'delivered' => const Color(0xFF4CAF50),
        _           => Colors.grey,
      };

  IconData get _icon => switch (status) {
        'pending'   => Icons.hourglass_top_rounded,
        'building'  => Icons.build_rounded,
        'shipped'   => Icons.local_shipping_rounded,
        'delivered' => Icons.check_circle_rounded,
        _           => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}