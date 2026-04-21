import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/component_model.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import 'builder_screen.dart';
import 'order_tracking_screen.dart';
import 'chat_screen.dart';
import 'package:pc_builder_app/screens/customer/customer_settings_screen.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);
const _cardBg = Colors.white;

const _categories = [
  {'key': 'all',         'label': 'All',         'icon': Icons.apps_rounded},
  {'key': 'cpu',         'label': 'CPU',          'icon': Icons.memory_rounded},
  {'key': 'gpu',         'label': 'GPU',          'icon': Icons.videocam_rounded},
  {'key': 'ram',         'label': 'RAM',          'icon': Icons.storage_rounded},
  {'key': 'ssd',         'label': 'SSD',          'icon': Icons.sd_card_rounded},
  {'key': 'motherboard', 'label': 'Motherboard',  'icon': Icons.developer_board_rounded},
  {'key': 'psu',         'label': 'PSU',          'icon': Icons.bolt_rounded},
  {'key': 'case',        'label': 'Case',         'icon': Icons.computer_rounded},
];

// ════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _filterType = 'all';
  bool _hasOrderNotification = false;
  Set<String> _seenStatusKeys = {};    // statuses user has already seen
  Set<String> _detectedStatusKeys = {}; // statuses detected from stream

  @override
  void initState() {
    super.initState();
    _loadSeenStatuses();
  }

  // Load previously seen order statuses from local storage
  Future<void> _loadSeenStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList('seen_order_statuses') ?? [];
    setState(() => _seenStatusKeys = seen.toSet());
  }

  // Mark all detected statuses as seen when user taps Orders tab
  Future<void> _markOrdersSeen() async {
    final prefs = await SharedPreferences.getInstance();
    _seenStatusKeys.addAll(_detectedStatusKeys);
    await prefs.setStringList(
        'seen_order_statuses', _seenStatusKeys.toList());
    setState(() => _hasOrderNotification = false);
  }

  // Called when orders stream updates — only shows badge, never auto-dismisses
  void _checkForNewStatuses(List<OrderModel> orders) {
    bool hasNew = false;
    for (final order in orders) {
      if (order.status == 'pending') continue;
      final key = '${order.id}_${order.status}';
      _detectedStatusKeys.add(key); // track detected but don't mark seen yet
      if (!_seenStatusKeys.contains(key)) {
        hasNew = true;
      }
    }
    if (hasNew != _hasOrderNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasOrderNotification = hasNew);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getMyOrders(),
        builder: (ctx, snap) {
          if (snap.hasData) {
            final orders = snap.data!.docs
                .map((d) => OrderModel.fromFirestore(d))
                .toList();
            _checkForNewStatuses(orders);
          }

          return IndexedStack(
            index: _currentIndex,
            children: [
              _ShopTab(
                filterType: _filterType,
                onFilterChanged: (t) => setState(() => _filterType = t),
                onSettingsTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerSettingsScreen())),
                onLogoutTap: () async {
                  await AuthService().signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
              const BuilderScreen(),
              const OrderTrackingScreen(),
              const ChatScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) async {
          setState(() => _currentIndex = i);
          // Clear badge when user taps Orders tab
          if (i == 2 && _hasOrderNotification) {
            await _markOrdersSeen();
          }
        },
        backgroundColor: _cardBg,
        indicatorColor: const Color(0xFFDDE8FF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded, color: _primary),
            label: 'Shop',
          ),
          const NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build_rounded, color: _primary),
            label: 'Builder',
          ),
          // Orders tab with badge
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.receipt_long_outlined,
              showBadge: _hasOrderNotification,
            ),
            selectedIcon: _BadgeIcon(
              icon: Icons.receipt_long_rounded,
              color: _primary,
              showBadge: _hasOrderNotification,
            ),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: _primary),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Badge Icon widget
// ════════════════════════════════════════════════════════════════
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final bool showBadge;
  final Color color;

  const _BadgeIcon({
    required this.icon,
    required this.showBadge,
    this.color = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color),
        if (showBadge)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _ShopTab extends StatefulWidget {
  final String filterType;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const _ShopTab({
    required this.filterType,
    required this.onFilterChanged,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _promoBannerDismissed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Column(
      children: [

        // ── Gradient Header (stays fixed at top) ─────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryDark, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PC Builder Shop',
                            style: GoogleFonts.syne(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        Text('Find the best parts for your build',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    onPressed: widget.onSettingsTap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white),
                    onPressed: widget.onLogoutTap,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Everything below scrolls together ────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.filterType == 'all'
                ? fs.getComponents(inStockOnly: true)
                : fs.getComponents(type: widget.filterType, inStockOnly: true),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: _primary));
              }

              final allDocs = snap.data?.docs ?? [];
              final docs = _searchQuery.isEmpty
                  ? allDocs
                  : allDocs.where((d) {
                      final c = ComponentModel.fromFirestore(d);
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.spec.toLowerCase().contains(_searchQuery);
                    }).toList();

              return CustomScrollView(
                slivers: [

                  // ── Promo Banner (scrolls away) ─────────────────
                  if (!_promoBannerDismissed)
                    SliverToBoxAdapter(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('discounts')
                            .where('active', isEqualTo: true)
                            .limit(3)
                            .snapshots(),
                        builder: (ctx, promoSnap) {
                          final promoDocs = promoSnap.data?.docs ?? [];
                          final now = DateTime.now();
                          final active = promoDocs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final exp = data['expiresAt'];
                            if (exp == null) return true;
                            final expDate = (exp as Timestamp).toDate();
                            return expDate.isAfter(now);
                          }).toList();

                          if (active.isEmpty) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50)
                                      .withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 10, 8, 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.local_offer_rounded,
                                            color: Colors.white,
                                            size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Active Promotions',
                                          style: GoogleFonts.syne(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          )),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => setState(() =>
                                            _promoBannerDismissed = true),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...active.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final code = data['code'] ?? '';
                                  final percent =
                                      (data['percent'] ?? 0).toInt();
                                  final desc = data['description'] ?? '';

                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 4, 14, 4),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Row(children: [
                                                const Icon(Icons.copy_rounded,
                                                    color: Colors.white,
                                                    size: 16),
                                                const SizedBox(width: 8),
                                                Text('Code "$code" copied!',
                                                    style:
                                                        GoogleFonts.inter()),
                                              ]),
                                              backgroundColor:
                                                  const Color(0xFF2E7D32),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              margin:
                                                  const EdgeInsets.all(12),
                                              duration: const Duration(
                                                  seconds: 2),
                                            ));
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(code,
                                                    style: GoogleFonts.syne(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF2E7D32),
                                                      letterSpacing: 1,
                                                    )),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.copy_rounded,
                                                    size: 11,
                                                    color: Color(0xFF4CAF50)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text('$percent% OFF',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              )),
                                        ),
                                        const SizedBox(width: 8),
                                        if (desc.isNotEmpty)
                                          Expanded(
                                            child: Text(desc,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.white70,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // ── Search Bar ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search components...',
                          hintStyle: GoogleFonts.inter(
                              color: Colors.grey[400], fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: _cardBg,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Category Chips ──────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final key = cat['key'] as String;
                          final label = cat['label'] as String;
                          final icon = cat['icon'] as IconData;
                          final selected = widget.filterType == key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => widget.onFilterChanged(key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? _primary : _cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? _primary
                                        : Colors.grey.shade200,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                              color:
                                                  _primary.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3))
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Icon(icon,
                                        size: 14,
                                        color: selected
                                            ? Colors.white
                                            : Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(label,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Results Count ───────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: Text(
                        '${docs.length} components found',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // ── Component Grid ──────────────────────────────
                  docs.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No components found',
                                    style: GoogleFonts.inter(
                                        color: Colors.grey[400])),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _ComponentCard(
                                  component: ComponentModel.fromFirestore(
                                      docs[i])),
                              childCount: docs.length,
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _ComponentCard extends StatelessWidget {
  final ComponentModel component;
  const _ComponentCard({required this.component});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: component.imageUrl != null &&
                        component.imageUrl!.isNotEmpty
                    ? Image.network(
                        component.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(component.emoji,
                              style: const TextStyle(fontSize: 36)),
                        ),
                      )
                    : Center(
                        child: Text(component.emoji,
                            style: const TextStyle(fontSize: 36)),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDDE8FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(component.type.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    letterSpacing: 0.5,
                  )),
            ),
            const SizedBox(height: 6),
            Text(component.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(component.spec,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${component.price.toStringAsFixed(0)}',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _primary,
                    )),
                _StockBadge(inStock: component.inStock),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _StockBadge extends StatelessWidget {
  final bool inStock;
  const _StockBadge({required this.inStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: inStock
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: inStock ? Colors.green[600] : Colors.red[600],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            inStock ? 'In Stock' : 'Out',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: inStock ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}