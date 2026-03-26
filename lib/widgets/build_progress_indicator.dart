import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$selected / $total selected',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('\$${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: selected / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }
}
