import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'inventory_screen.dart';
import 'order_management_screen.dart';
import 'discount_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_settings_screen.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text('Admin Panel',
                                style: GoogleFonts.syne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                        Row(
                          children: [
                            _HeaderBtn(
                              icon: Icons.settings_outlined,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const AdminSettingsScreen())),
                            ),
                            const SizedBox(width: 8),
                            _HeaderBtn(
                              icon: Icons.logout_rounded,
                              onTap: () async {
                                await AuthService().signOut();
                                if (!context.mounted) return;
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Welcome text
                    Text('Welcome back! 👋',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        )),
                    const SizedBox(height: 4),
                    Text('Manage your PC shop',
                        style: GoogleFonts.syne(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
            ),
          ),

          // ── Dashboard grid ───────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [

                Text('Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 12),

                // 2x2 Grid
                Row(
                  children: [
                    Expanded(
                      child: _DashCard(
                        icon: Icons.inventory_2_rounded,
                        label: 'Inventory',
                        subtitle: 'Add, edit, delete parts',
                        color: _primary,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const InventoryScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        subtitle: 'Manage & update status',
                        color: const Color(0xFFFF9800),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const OrderManagementScreen())),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _DashCard(
                        icon: Icons.local_offer_rounded,
                        label: 'Discounts',
                        subtitle: 'Promo codes',
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const DiscountScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashCard(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Messages',
                        subtitle: 'Customer chat',
                        color: const Color(0xFF9C27B0),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AdminChatScreen())),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick tips
                Text('Quick Tips',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 12),

                _TipCard(
                  icon: Icons.lightbulb_rounded,
                  color: const Color(0xFFFF9800),
                  text: 'Keep inventory updated so customers see accurate stock.',
                ),
                const SizedBox(height: 8),
                _TipCard(
                  icon: Icons.local_shipping_rounded,
                  color: _primary,
                  text: 'Update order status promptly to keep customers informed.',
                ),
                const SizedBox(height: 8),
                _TipCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF9C27B0),
                  text: 'Reply to customer messages quickly for better experience.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _DashCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const Spacer(),
            Text(label,
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                )),
            const SizedBox(height: 3),
            Text(subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[400],
                )),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
class _TipCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _TipCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }
}