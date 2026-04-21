import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../models/component_model.dart';
import '../../services/firestore_service.dart';

// ── Design tokens ─────────────────────────────────────────────
const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);
const _imgbbApiKey = 'ae70af99cf7f84e2fb2484daf9e9f94f';

class AddEditProductScreen extends StatefulWidget {
  final ComponentModel? component;
  const AddEditProductScreen({super.key, this.component});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _imageCtrl;
  String _type = 'cpu';
  bool _inStock = true;
  bool _saving = false;
  bool _uploading = false;
  File? _pickedImage;

  bool get _isEditing => widget.component != null;

  final _types = ['cpu', 'gpu', 'ram', 'ssd', 'motherboard', 'psu', 'case'];

  // Type accent colors for visual flair
  static const _typeColors = {
    'cpu':         Color(0xFF1A6BFF),
    'gpu':         Color(0xFF9C27B0),
    'ram':         Color(0xFF4CAF50),
    'ssd':         Color(0xFFFF9800),
    'motherboard': Color(0xFF00BCD4),
    'psu':         Color(0xFFF44336),
    'case':        Color(0xFF607D8B),
  };

  Color get _typeColor => _typeColors[_type] ?? _primary;

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    _nameCtrl  = TextEditingController(text: c?.name ?? '');
    _specCtrl  = TextEditingController(text: c?.spec ?? '');
    _priceCtrl = TextEditingController(
        text: c != null ? c.price.toStringAsFixed(0) : '');
    _emojiCtrl = TextEditingController(text: c?.emoji ?? '🖥️');
    _imageCtrl = TextEditingController(text: c?.imageUrl ?? '');
    _type      = c?.type ?? 'cpu';
    _inStock   = c?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _priceCtrl.dispose();
    _emojiCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _pickedImage = File(picked.path);
    });

    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final url = data['data']['url'] as String;
        setState(() => _imageCtrl.text = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Image uploaded!', style: GoogleFonts.inter()),
            ]),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ));
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      setState(() => _pickedImage = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Upload failed: $e', style: GoogleFonts.inter()),
          ]),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final imageUrl = _imageCtrl.text.trim();

    final data = {
      'type'    : _type,
      'name'    : _nameCtrl.text.trim(),
      'spec'    : _specCtrl.text.trim(),
      'price'   : double.parse(_priceCtrl.text.trim()),
      'emoji'   : _emojiCtrl.text.trim(),
      'inStock' : _inStock,
      'imageUrl': imageUrl.isEmpty ? null : imageUrl,
    };

    try {
      if (_isEditing) {
        await FirestoreService().updateComponent(widget.component!.id, data);
      } else {
        await FirestoreService().addComponent(data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Component updated!' : 'Component added!',
            style: GoogleFonts.inter(),
          ),
        ]),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Error: $e', style: GoogleFonts.inter()),
        ]),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Form(
        key: _formKey,
        child: Column(
          children: [

            // ── Gradient Header ──────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryDark, _primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back + title row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            _isEditing ? 'Edit Component' : 'Add Component',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Emoji preview + name preview
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            // Live emoji preview
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  _emojiCtrl.text.isNotEmpty
                                      ? _emojiCtrl.text
                                      : '🖥️',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameCtrl.text.isNotEmpty
                                      ? _nameCtrl.text
                                      : 'New Component',
                                  style: GoogleFonts.syne(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Type badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _type.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Form fields ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [

                  // ── Section: Basic Info ──────────────────────
                  _SectionLabel('Basic Info'),
                  const SizedBox(height: 10),
                  _FormCard(children: [

                    // Component Type dropdown
                    _FieldWrapper(
                      label: 'Component Type',
                      icon: Icons.category_rounded,
                      iconColor: _typeColor,
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.black87),
                        decoration: _dropdownDecoration(),
                        items: _types.map((t) {
                          final color = _typeColors[t] ?? _primary;
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(t.toUpperCase(),
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),

                    _CardDivider(),

                    // Emoji + Name row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emoji field
                          SizedBox(
                            width: 72,
                            child: TextFormField(
                              controller: _emojiCtrl,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Emoji',
                                labelStyle: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.grey[500]),
                                filled: true,
                                fillColor: _surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: _primary, width: 1.5),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Name field
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: _fieldDecoration(
                                  label: 'Component Name',
                                  hint: 'e.g. RTX 4070 Ti'),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Section: Details ─────────────────────────
                  _SectionLabel('Details'),
                  const SizedBox(height: 10),
                  _FormCard(children: [

                    // Spec
                    _FieldWrapper(
                      label: 'Specifications',
                      icon: Icons.tune_rounded,
                      child: TextFormField(
                        controller: _specCtrl,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: _fieldDecoration(
                            label: 'Specs',
                            hint: 'e.g. 12GB GDDR6X, 192-bit'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),

                    _CardDivider(),

                    // Price
                    _FieldWrapper(
                      label: 'Price (USD)',
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: _fieldDecoration(
                          label: 'Price',
                          hint: '0',
                          prefix: '\$ ',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Section: Image ───────────────────────────
                  _SectionLabel('Image'),
                  const SizedBox(height: 10),
                  _FormCard(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Upload + URL row
                          Row(
                            children: [
                              // Upload button
                              GestureDetector(
                                onTap: _uploading ? null : _pickAndUpload,
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF9C27B0).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      _uploading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF9C27B0),
                                              ),
                                            )
                                          : const Icon(Icons.upload_rounded,
                                              size: 18, color: Color(0xFF9C27B0)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _uploading ? 'Uploading...' : 'Upload',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF9C27B0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // URL field
                              Expanded(
                                child: TextFormField(
                                  controller: _imageCtrl,
                                  keyboardType: TextInputType.url,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.inter(fontSize: 12),
                                  decoration: _fieldDecoration(
                                    label: 'or paste URL',
                                    hint: 'https://...',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Preview area
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _pickedImage != null && _imageCtrl.text.isEmpty
                                // Local file preview while uploading
                                ? Image.file(
                                    _pickedImage!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : _imageCtrl.text.trim().isNotEmpty
                                    // Network preview after upload / manual URL
                                    ? Image.network(
                                        _imageCtrl.text.trim(),
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _imagePlaceholder(isError: true),
                                      )
                                    // Empty placeholder
                                    : _imagePlaceholder(isError: false),
                          ),

                          // Clear button
                          if (_imageCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                _imageCtrl.clear();
                                _pickedImage = null;
                              }),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded,
                                      size: 14, color: Colors.red[400]),
                                  const SizedBox(width: 4),
                                  Text('Remove image',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.red[400],
                                        fontWeight: FontWeight.w500,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Section: Availability ────────────────────
                  _SectionLabel('Availability'),
                  const SizedBox(height: 10),
                  _FormCard(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (_inStock ? Colors.green : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _inStock
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color:
                                  _inStock ? Colors.green[600] : Colors.red[400],
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('In Stock',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    )),
                                Text(
                                  _inStock
                                      ? 'Visible to customers'
                                      : 'Hidden from customers',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _inStock,
                            onChanged: (v) => setState(() => _inStock = v),
                            activeColor: Colors.green[600],
                          ),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Save Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEditing
                                      ? Icons.save_rounded
                                      : Icons.add_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditing
                                      ? 'Save Changes'
                                      : 'Add Component',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder({required bool isError}) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withOpacity(0.05)
            : _surface,
        border: isError
            ? Border.all(color: Colors.red.withOpacity(0.2))
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError) ...[
              Icon(Icons.broken_image_rounded,
                  color: Colors.red[300], size: 32),
              const SizedBox(height: 6),
              Text('Invalid image URL',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.red[400])),
            ] else ...[
              Text(
                _emojiCtrl.text.isNotEmpty ? _emojiCtrl.text : '🖥️',
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 6),
              Text('Upload or paste a URL above',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey[400])),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────

InputDecoration _fieldDecoration({
  required String label,
  String? hint,
  String? prefix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefix,
    labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
    filled: true,
    fillColor: _surface,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

InputDecoration _dropdownDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: _surface,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[400],
        letterSpacing: 1.2,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _FieldWrapper extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _FieldWrapper({
    required this.label,
    required this.icon,
    required this.child,
    this.iconColor = _primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.shade100);
  }
}