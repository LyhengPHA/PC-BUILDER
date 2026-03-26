import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  static const _steps = ['pending', 'building', 'shipped', 'delivered'];

  Color get _color => switch (status) {
        'pending' => Colors.orange,
        'building' => Colors.blue,
        'shipped' => Colors.purple,
        'delivered' => Colors.green,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final stepIndex = _steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _color.withOpacity(0.5)),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 11),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(_steps.length, (i) {
            final active = i <= stepIndex;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? _color : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
