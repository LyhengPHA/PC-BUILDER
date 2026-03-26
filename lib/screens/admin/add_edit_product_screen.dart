import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../services/firestore_service.dart';

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

  bool get _isEditing => widget.component != null;

  final _types = ['cpu', 'gpu', 'ram', 'ssd', 'motherboard', 'psu', 'case'];

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
          content: Text(_isEditing ? 'Component updated!' : 'Component added!'),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Edit Component' : 'Add Component')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Type ──────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                  labelText: 'Component Type',
                  border: OutlineInputBorder()),
              items: _types
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),

            // ── Emoji + Name ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emojiCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Emoji',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Spec ──────────────────────────────────────────
            TextFormField(
              controller: _specCtrl,
              decoration: const InputDecoration(
                  labelText: 'Specs (e.g. 8GB GDDR6)',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Price ─────────────────────────────────────────
            TextFormField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  prefixText: '\$',
                  border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null)
                  return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Image URL ─────────────────────────────────────
            TextFormField(
              controller: _imageCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'https://i.imgur.com/abc123.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),

            // Image preview
            if (_imageCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageCtrl.text.trim(),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.grey[100],
                    child: const Center(
                      child: Text('Invalid image URL',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── In Stock toggle ───────────────────────────────
            SwitchListTile(
              title: const Text('In Stock'),
              subtitle: const Text('Visible to customers'),
              value: _inStock,
              onChanged: (v) => setState(() => _inStock = v),
              tileColor: Colors.grey[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[200]!)),
            ),
            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isEditing ? 'Save Changes' : 'Add Component',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}