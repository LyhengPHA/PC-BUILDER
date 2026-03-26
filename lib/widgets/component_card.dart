import 'package:flutter/material.dart';
import '../models/component_model.dart';

class ComponentCard extends StatelessWidget {
  final ComponentModel component;
  const ComponentCard({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Image or Emoji ─────────────────────────────────
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
                                  color: cs.primaryContainer.withOpacity(0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => _emojiPlaceholder(cs),
                    )
                  : _emojiPlaceholder(cs),
            ),

            // ── Details ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        component.type.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cs.primary),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Name
                    Text(
                      component.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Spec
                    Text(
                      component.spec,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price
                    Text(
                      '\$${component.price.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
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

  // Fallback when no image URL is provided
  Widget _emojiPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.primaryContainer.withOpacity(0.4),
      child: Center(
        child: Text(
          component.emoji,
          style: const TextStyle(fontSize: 44),
        ),
      ),
    );
  }
}