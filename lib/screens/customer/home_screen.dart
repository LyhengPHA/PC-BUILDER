import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/component_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import 'builder_screen.dart';
import 'order_tracking_screen.dart';
import 'chat_screen.dart';
import 'package:pc_builder_app/screens/customer/customer_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _filterType = 'all';

  final _types = [
    'all', 'cpu', 'gpu', 'ram', 'ssd', 'motherboard', 'psu', 'case'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Builder Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const CustomerSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ShopTab(
              filterType: _filterType,
              types: _types,
              onFilterChanged: (t) =>
                  setState(() => _filterType = t)),
          const BuilderScreen(),
          const OrderTrackingScreen(),
          const ChatScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.store), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.build), label: 'Builder'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  final String filterType;
  final List<String> types;
  final ValueChanged<String> onFilterChanged;

  const _ShopTab({
    required this.filterType,
    required this.types,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            itemCount: types.length,
            itemBuilder: (_, i) {
              final t = types[i];
              final selected = filterType == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                      t == 'all' ? 'All' : t.toUpperCase()),
                  selected: selected,
                  onSelected: (_) => onFilterChanged(t),
                  selectedColor: const Color(0xFF1565C0)
                      .withOpacity(0.2),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: filterType == 'all'
                ? fs.getComponents()
                : fs.getComponents(type: filterType),
            builder: (ctx, snap) {
              if (snap.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                    child: Text('No components found'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final c = ComponentModel.fromFirestore(docs[i]);
                  return _ComponentCard(component: c);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ComponentCard extends StatelessWidget {
  final ComponentModel component;
  const _ComponentCard({required this.component});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            component.imageUrl != null &&
                    component.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      component.imageUrl!,
                      height: 60,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                          component.emoji,
                          style:
                              const TextStyle(fontSize: 36)),
                    ),
                  )
                : Text(component.emoji,
                    style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(component.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(component.spec,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '\$${component.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1565C0))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: component.inStock
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    component.inStock ? 'In Stock' : 'Out',
                    style: TextStyle(
                        fontSize: 10,
                        color: component.inStock
                            ? Colors.green[700]
                            : Colors.red[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}