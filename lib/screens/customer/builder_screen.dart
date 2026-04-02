import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/component_model.dart';
import 'component_picker_screen.dart';
import 'cart_screen.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

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
    'cpu':         {'label': 'CPU',         'icon': Icons.memory_rounded,           'desc': 'Processor'},
    'gpu':         {'label': 'GPU',         'icon': Icons.videocam_rounded,         'desc': 'Graphics Card'},
    'ram':         {'label': 'RAM',         'icon': Icons.storage_rounded,          'desc': 'Memory'},
    'ssd':         {'label': 'SSD',         'icon': Icons.sd_card_rounded,          'desc': 'Storage'},
    'motherboard': {'label': 'Motherboard', 'icon': Icons.developer_board_rounded,  'desc': 'Main Board'},
    'psu':         {'label': 'PSU',         'icon': Icons.bolt_rounded,             'desc': 'Power Supply'},
    'case':        {'label': 'Case',        'icon': Icons.computer_rounded,         'desc': 'PC Case'},
  };

  double get _total => _build.values
      .where((c) => c != null)
      .fold(0.0, (s, c) => s + c!.price);

  int get _selectedCount => _build.values.where((c) => c != null).length;

  Future<void> _pickComponent(String type) async {
    final picked = await Navigator.push<ComponentModel>(
      context,
      MaterialPageRoute(builder: (_) => ComponentPickerScreen(type: type)),
    );
    if (picked != null) setState(() => _build[type] = picked);
  }

  void _checkout() {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Select at least one component first!',
                  style: GoogleFonts.inter()),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen(selectedBuild: _build)),
    ).then((ordered) {
      if (ordered == true && mounted) {
        setState(() {
          for (final k in _build.keys) _build[k] = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _selectedCount / 7;

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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PC Builder',
                                style: GoogleFonts.syne(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                            Text('Build your perfect PC',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                )),
                          ],
                        ),
                        // Total price badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\$${_total.toStringAsFixed(0)}',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_selectedCount of 7 components selected',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            )),
                        Text('${(progress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Slot list ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: _slotInfo.entries.map((entry) {
                final type = entry.key;
                final info = entry.value;
                final component = _build[type];
                final isSelected = component != null;

                return GestureDetector(
                  onTap: () => _pickComponent(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _primary.withOpacity(0.3)
                            : Colors.grey.shade100,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [

                          // Icon box
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary.withOpacity(0.1)
                                  : _surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              info['icon'] as IconData,
                              size: 22,
                              color: isSelected ? _primary : Colors.grey[400],
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Type label
                                Text(
                                  isSelected
                                      ? component!.name
                                      : info['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isSelected
                                      ? component!.spec
                                      : info['desc'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Right side
                          if (isSelected) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${component!.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.syne(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _build[type] = null),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Remove',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.red[600],
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDE8FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Add',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  )),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),

      // ── Floating checkout button ─────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedCount > 0 ? _checkout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              disabledForegroundColor: Colors.grey[400],
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedCount > 0
                      ? 'Review Order — \$${_total.toStringAsFixed(0)}'
                      : 'Select components to continue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}