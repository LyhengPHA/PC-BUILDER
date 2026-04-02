import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';

const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  bool _darkMode = false;
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _db.collection('users').doc(uid).get();
    setState(() {
      _name = doc.data()?['name'] ?? '';
      _email = _auth.currentUser?.email ?? '';
    });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Name', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({'name': result});
      setState(() => _name = result);
      if (!mounted) return;
      _showSnack('Name updated!', success: true);
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(currentCtrl, 'Current Password', obscure: true),
            const SizedBox(height: 12),
            _dialogField(newCtrl, 'New Password', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = _auth.currentUser!;
                final cred = EmailAuthProvider.credential(
                    email: user.email!, password: currentCtrl.text);
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newCtrl.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack('Password changed!', success: true);
              } catch (e) {
                if (!context.mounted) return;
                _showSnack('Error: $e', success: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Update',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700, color: Colors.red[700])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will permanently delete your account and all your data. Enter your password to confirm.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            _dialogField(passCtrl, 'Password', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = _auth.currentUser!;
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: passCtrl.text);
        await user.reauthenticateWithCredential(cred);
        await _db.collection('users').doc(user.uid).delete();
        await user.delete();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      } catch (e) {
        if (!mounted) return;
        _showSnack('Error: $e', success: false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: GoogleFonts.inter()),
      ]),
      backgroundColor: success ? Colors.green[600] : Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Widget _dialogField(TextEditingController ctrl, String label,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [

          // ── Gradient Header + Profile ────────────────────────────
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
                  children: [
                    // Back button row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text('Settings',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Avatar + info
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(initials,
                                style: GoogleFonts.syne(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name.isNotEmpty ? _name : 'Loading...',
                                style: GoogleFonts.syne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 3),
                            Text(_email,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                )),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Customer',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Settings list ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [

                _SectionLabel('Profile'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.person_rounded,
                    label: 'Edit Name',
                    onTap: _editName,
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    label: 'Change Password',
                    onTap: _changePassword,
                  ),
                ]),

                const SizedBox(height: 20),

                _SectionLabel('App'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDE8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dark_mode_rounded,
                              color: _primary, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dark Mode',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  )),
                              Text('Coming soon',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  )),
                            ],
                          ),
                        ),
                        Switch(
                          value: _darkMode,
                          onChanged: (v) => setState(() => _darkMode = v),
                          activeColor: _primary,
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                _SectionLabel('About'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.info_rounded,
                    label: 'App Version',
                    trailing: Text('1.0.0',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[400],
                        )),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Contact Support',
                    subtitle: 'Chat with us in the Chat tab',
                  ),
                ]),

                const SizedBox(height: 20),

                _SectionLabel('Account'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    iconColor: Colors.orange[600]!,
                    labelColor: Colors.orange[700]!,
                    onTap: _logout,
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    iconColor: Colors.red[600]!,
                    labelColor: Colors.red[700]!,
                    onTap: _deleteAccount,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ));
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color labelColor;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.iconColor = _primary,
    this.labelColor = Colors.black87,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[400],
                        )),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[300], size: 20)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }
}