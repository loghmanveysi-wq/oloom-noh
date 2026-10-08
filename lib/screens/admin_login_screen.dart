// ورود مخصوص مدیر (سازنده‌ی اپ) با نام کاربری و رمز عبور
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userController.text.trim().isEmpty || _passController.text.isEmpty) {
      setState(() => _error = 'نام کاربری و رمز عبور را وارد کنید.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: AdminService.emailFromUsername(_userController.text),
        password: _passController.text,
      );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      if (doc.data()?['role'] != 'teacher') {
        await FirebaseAuth.instance.signOut();
        if (mounted) setState(() => _error = 'این حساب دسترسی مدیر ندارد.');
        return;
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (_) {
      if (mounted) setState(() => _error = 'نام کاربری یا رمز عبور اشتباه است.');
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() => _error = 'خطایی رخ داد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود مدیر')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.admin_panel_settings, size: 72, color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              TextField(
                controller: _userController,
                autocorrect: false,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'نام کاربری', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passController,
                obscureText: _obscure,
                textDirection: TextDirection.ltr,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'رمز عبور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ورود'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
