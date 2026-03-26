import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import 'component_picker_screen.dart';
import 'cart_screen.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  final Map<String, ComponentModel?> _build = {
    'cpu': null,
    'gpu': null,
    'ram': null,
    'ssd': null,
    'motherboard': null,
    'psu': null,
    'case': null,
  };

  final Map<String, Map<String, dynamic>> _slotInfo = {
    'cpu':         {'label': 'CPU',         'emoji': '🧠', 'desc': 'Processor'},
    'gpu':         {'label': 'GPU',         'emoji': '🎮', 'desc': 'Graphics Card'},
    'ram':         {'label': 'RAM',         'emoji': '💾', 'desc': 'Memory'},
    'ssd':         {'label': 'SSD',         'emoji': '💿', 'desc': 'Storage'},
    'motherboard': {'label': 'Motherboard', 'emoji': '🔲', 'desc': 'Main Board'},
    'psu':         {'label': 'PSU',         'emoji': '🔌', 'desc': 'Power Supply'},
    'case':        {'label': 'Case',        'emoji': '🗄️', 'desc': 'PC Case'},
  };

  double get _total => _build.values
      .where((c) => c != null)
      .fold(0.0, (s, c) => s + c!.price);

  int get _selectedCount =>
      _build.values.where((c) => c != null).length;

  Future<void> _pickComponent(String type) async {
    final picked = await Navigator.push<ComponentModel>(
      context,
      MaterialPageRoute(
          builder: (_) => ComponentPickerScreen(type: type)),
    );
    if (picked != null) {
      setState(() => _build[type] = picked);
    }
  }

  void _checkout() {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Select at least one component first!')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(selectedBuild: _build),
      ),
    ).then((ordered) {
      // Clear the build if order was placed successfully
      if (ordered == true && mounted) {
        setState(() {
          for (final k in _build.keys) {
            _build[k] = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Builder'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_selectedCount / 7 components',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    Text('\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _selectedCount / 7,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF1565C0)),
                ),
              ],
            ),
          ),

          // Component slots
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _slotInfo.entries.map((entry) {
                final type = entry.key;
                final info = entry.value;
                final component = _build[type];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: component != null
                            ? const Color(0xFF1565C0).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text(info['emoji']!,
                              style: const TextStyle(fontSize: 24))),
                    ),
                    title: Text(
                      component?.name ?? info['label']!,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: component == null
                              ? Colors.grey[600]
                              : null),
                    ),
                    subtitle: Text(
                      component != null
                          ? '${component.spec} • \$${component.price.toStringAsFixed(0)}'
                          : info['desc']!,
                      style: TextStyle(
                          fontSize: 12,
                          color: component != null
                              ? Colors.green[700]
                              : Colors.grey[500]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (component != null)
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.red),
                            onPressed: () =>
                                setState(() => _build[type] = null),
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _pickComponent(type),
                  ),
                );
              }).toList(),
            ),
          ),

          // Order button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _selectedCount > 0 ? _checkout : null,
                icon: const Icon(Icons.shopping_cart),
                label: Text(
                    'Review Order — \$${_total.toStringAsFixed(2)}'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}