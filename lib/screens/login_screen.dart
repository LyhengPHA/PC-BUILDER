import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'customer/home_screen.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _navigated = false;

  String _friendlyError(String error) {
    if (error.contains('invalid-credential') ||
        error.contains('wrong-password') ||
        error.contains('invalid-email')) {
      return 'Incorrect email or password. Please try again.';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('network') ||
        error.contains('connection')) {
      return 'No internet connection. Please check your network.';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled. Contact support.';
    }
    return 'Login failed. Please try again.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_navigated) return;
    setState(() => _loading = true);

    final navigator = Navigator.of(context);

    try {
      final data = await AuthService().signIn(
        _emailCtrl.text, _passCtrl.text);

      if (_navigated) return;

      print('🎯 Role from signIn: ${data?['role']}');

      final role = data?['role'] as String?;
      _navigated = true;

      if (role != null && role.trim().toLowerCase() == 'admin') {
        print('➡️ Navigating to Admin Dashboard');
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        print('➡️ Navigating to Customer Home');
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      _navigated = false;
      _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.computer,
                        size: 72, color: Color(0xFF1565C0)),
                    const SizedBox(height: 16),
                    const Text('PC Builder',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: null,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                        v == null || !v.contains('@')
                          ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      autofillHints: null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                            ? Icons.visibility_off : Icons.visibility),
                          onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                        v == null || v.length < 6
                          ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding:
                          const EdgeInsets.symmetric(vertical: 16)),
                      child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                        : const Text('Sign In',
                            style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}