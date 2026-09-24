// صفحه ورود و ثبت‌نام: دانش‌آموز (شماره موبایل + رمز) و دبیر (ایمیل + رمز)
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _teacherMode = false;
  bool _registerMode = false;
  bool _loading = false;
  bool _hidePass = true;
  String? _error;

  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _class = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    _name.dispose();
    _class.dispose();
    _email.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  String? _validate() {
    if (_teacherMode) {
      if (!_email.text.contains('@')) return 'ایمیل را درست وارد کنید.';
      if (_pass.text.isEmpty) return 'رمز عبور را وارد کنید.';
      return null;
    }
    if (!AuthService.isValidPhone(_phone.text)) {
      return 'شماره موبایل را درست وارد کنید (مثلاً 09123456789).';
    }
    if (_pass.text.length < 6) return 'رمز عبور باید حداقل ۶ کاراکتر باشد.';
    if (_registerMode) {
      if (_name.text.trim().isEmpty) return 'نام و نام خانوادگی را وارد کنید.';
      if (_class.text.trim().isEmpty) return 'کلاس را وارد کنید.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (_teacherMode) {
        await AuthService.signInTeacher(_email.text, _pass.text);
      } else if (_registerMode) {
        await AuthService.registerStudent(
          phone: _phone.text,
          password: _pass.text,
          name: _name.text,
          className: _class.text,
        );
      } else {
        await AuthService.signInStudent(_phone.text, _pass.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passField = TextField(
      controller: _pass,
      obscureText: _hidePass,
      textDirection: TextDirection.ltr,
      decoration: _dec(
        'رمز عبور',
        Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _hidePass = !_hidePass),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.science, size: 64, color: AppTheme.primaryBlue),
                  const SizedBox(height: 8),
                  const Text(
                    'علوم نهم – استاد ویسی',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('دانش‌آموز')),
                      ButtonSegment(value: true, label: Text('دبیر')),
                    ],
                    selected: {_teacherMode},
                    onSelectionChanged: (s) => setState(() {
                      _teacherMode = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_teacherMode) ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('ایمیل', Icons.email_outlined),
                    ),
                    const SizedBox(height: 12),
                    passField,
                  ] else ...[
                    if (_registerMode) ...[
                      TextField(
                        controller: _name,
                        decoration: _dec('نام و نام خانوادگی', Icons.person_outline),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _class,
                        decoration: _dec('کلاس (مثلاً ۹/۱)', Icons.school_outlined),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('شماره موبایل', Icons.phone_android),
                    ),
                    const SizedBox(height: 12),
                    passField,
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_teacherMode
                            ? 'ورود دبیر'
                            : (_registerMode ? 'ثبت‌نام' : 'ورود')),
                  ),
                  if (!_teacherMode)
                    TextButton(
                      onPressed: () => setState(() {
                        _registerMode = !_registerMode;
                        _error = null;
                      }),
                      child: Text(_registerMode
                          ? 'قبلاً ثبت‌نام کرده‌ام، ورود'
                          : 'حساب ندارم، ثبت‌نام'),
                    ),
                  if (!_teacherMode && _registerMode)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'شماره موبایل شما نام کاربری شماست. رمز را جایی یادداشت کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
