// ورود / ثبت‌نام دانش‌آموزان: ثبت‌نام با مشخصات کامل، ورود بعدی فقط با شماره موبایل و رمز عبور
// بازیابی رمز عبور از طریق ایمیلی که هنگام ثبت‌نام ثبت شده است.
import '../widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';

// تبدیل شماره‌ی موبایل (با ارقام فارسی/عربی، +98 و ...) به شکل استاندارد 09123456789
String? _normalizePhone(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in input.trim().split('')) {
    var i = fa.indexOf(ch);
    if (i < 0) i = ar.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  var s = b.toString().replaceAll(RegExp(r'[\s\-()]'), '');
  if (s.startsWith('+98')) {
    s = '0${s.substring(3)}';
  } else if (s.startsWith('0098')) {
    s = '0${s.substring(4)}';
  } else if (s.startsWith('98') && s.length == 12) {
    s = '0${s.substring(2)}';
  } else if (s.length == 10 && s.startsWith('9')) {
    s = '0$s';
  }
  return RegExp(r'^09\d{9}$').hasMatch(s) ? s : null;
}

String _maskEmail(String e) {
  final i = e.indexOf('@');
  if (i <= 1) return e;
  return '${e[0]}***${e.substring(i)}';
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  final _name = TextEditingController();
  final _school = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _school, _city, _phone, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fail(String msg) {
    if (mounted) setState(() => _error = msg);
  }

  Future<String?> _emailForPhone(String phone) async {
    final doc = await FirebaseFirestore.instance.collection('loginIndex').doc(phone).get();
    if (!doc.exists) return null;
    final e = (doc.data()?['email'] ?? '').toString();
    return e.isEmpty ? null : e;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      if (_isLogin) {
        await _login();
      } else {
        await _register();
      }
    } on FirebaseAuthException catch (e) {
      _fail(_friendlyError(e.code));
    } on FirebaseException catch (e) {
      _fail('خطا در ارتباط با سرور (${e.code}). اینترنت و قوانین Firestore را بررسی کنید.');
    } catch (e) {
      _fail('خطایی رخ داد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ورود: شماره موبایل + رمز عبور (حساب‌های قدیمی می‌توانند ایمیل بنویسند)
  Future<void> _login() async {
    final raw = _phone.text.trim();
    if (raw.isEmpty || _pass.text.isEmpty) {
      _fail('شماره موبایل و رمز عبور را وارد کنید.');
      return;
    }
    String email;
    if (raw.contains('@')) {
      email = raw.toLowerCase();
    } else {
      final phone = _normalizePhone(raw);
      if (phone == null) {
        _fail('شماره موبایل معتبر نیست (مثال: 09123456789).');
        return;
      }
      final found = await _emailForPhone(phone);
      if (found == null) {
        _fail('با این شماره ثبت‌نام نشده است. ابتدا ثبت‌نام کنید.');
        return;
      }
      email = found;
    }
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: _pass.text);
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final school = _school.text.trim();
    final city = _city.text.trim();
    final phone = _normalizePhone(_phone.text);
    final email = _email.text.trim().toLowerCase();
    final pass = _pass.text;

    if (name.length < 3) {
      _fail('نام و نام خانوادگی را کامل وارد کنید.');
      return;
    }
    if (school.isEmpty) {
      _fail('نام مدرسه را وارد کنید.');
      return;
    }
    if (city.isEmpty) {
      _fail('نام شهر را وارد کنید.');
      return;
    }
    if (phone == null) {
      _fail('شماره موبایل معتبر نیست (مثال: 09123456789).');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _fail('ایمیل معتبر نیست. برای بازیابی رمز عبور لازم است.');
      return;
    }
    if (pass.length < 6) {
      _fail('رمز عبور باید حداقل ۶ کاراکتر باشد.');
      return;
    }
    if (pass != _pass2.text) {
      _fail('تکرار رمز عبور با رمز عبور یکسان نیست.');
      return;
    }

    final db = FirebaseFirestore.instance;
    final indexRef = db.collection('loginIndex').doc(phone);
    if ((await indexRef.get()).exists) {
      _fail('این شماره قبلاً ثبت‌نام شده است. وارد شوید.');
      return;
    }

    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: pass);
    final user = cred.user!;
    try {
      final batch = db.batch();
      batch.set(indexRef, {'uid': user.uid, 'email': email});
      batch.set(db.collection('users').doc(user.uid), {
        'name': name,
        'school': school,
        'city': city,
        'phone': phone,
        'email': email,
        'role': 'student',
        'xp': 0,
        'level': 1,
        'onlineStatus': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      // اگر ثبت اطلاعات انجام نشد، حساب ناقص را پاک می‌کنیم تا کاربر دوباره تلاش کند
      await user.delete();
      rethrow;
    }
  }

  // بازیابی رمز عبور: ارسال لینک به ایمیل ثبت‌شده
  Future<void> _forgot() async {
    final raw = _phone.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _error = 'ابتدا شماره موبایل خود را در کادر بالا بنویسید.';
        _info = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      String? email;
      if (raw.contains('@')) {
        email = raw.toLowerCase();
      } else {
        final phone = _normalizePhone(raw);
        if (phone == null) {
          _fail('شماره موبایل معتبر نیست (مثال: 09123456789).');
          return;
        }
        email = await _emailForPhone(phone);
        if (email == null) {
          _fail('با این شماره ثبت‌نام نشده است.');
          return;
        }
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _info =
            'لینک بازیابی رمز عبور به ایمیل ${_maskEmail(email!)} ارسال شد. پوشه‌ی اسپم را هم بررسی کنید.');
      }
    } on FirebaseAuthException catch (e) {
      _fail(_friendlyError(e.code));
    } catch (_) {
      _fail('ارسال ایمیل انجام نشد. اینترنت را بررسی کنید.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'کاربری با این مشخصات یافت نشد.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'شماره موبایل یا رمز عبور اشتباه است.';
      case 'email-already-in-use':
        return 'این ایمیل قبلاً برای حساب دیگری ثبت شده است.';
      case 'weak-password':
        return 'رمز عبور باید حداقل ۶ کاراکتر باشد.';
      case 'invalid-email':
        return 'فرمت ایمیل صحیح نیست.';
      case 'network-request-failed':
        return 'اتصال اینترنت برقرار نیست.';
      case 'too-many-requests':
        return 'تعداد تلاش‌ها زیاد است؛ کمی بعد دوباره تلاش کنید.';
      case 'user-disabled':
        return 'این حساب غیرفعال شده است.';
      default:
        return 'خطا: $code';
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    bool ltr = false,
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: password && _obscure,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          suffixIcon: password
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.science, size: 72, color: AppTheme.primaryBlue),
              const SizedBox(height: 12),
              const Text(
                'علوم نهم – استاد ویسی',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'ورود به حساب کاربری' : 'ثبت‌نام دانش‌آموز جدید',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              if (!_isLogin) ...[
                _field(_name, 'نام و نام خانوادگی', Icons.person_outline),
                _field(_school, 'نام مدرسه', Icons.school_outlined),
                _field(_city, 'شهر', Icons.location_city_outlined),
              ],
              _field(_phone, _isLogin ? 'شماره موبایل' : 'شماره موبایل (برای ورودهای بعدی)',
                  Icons.phone_android,
                  type: TextInputType.phone, ltr: true),
              if (!_isLogin)
                _field(_email, 'ایمیل (برای بازیابی رمز عبور)', Icons.email_outlined,
                    type: TextInputType.emailAddress, ltr: true),
              _field(_pass, 'رمز عبور', Icons.lock_outline, password: true, ltr: true),
              if (!_isLogin)
                _field(_pass2, 'تکرار رمز عبور', Icons.lock_outline, password: true, ltr: true),
              if (_isLogin)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _loading ? null : _forgot,
                    child: const Text('رمز عبور را فراموش کرده‌ام'),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
              if (_info != null) ...[
                const SizedBox(height: 4),
                Text(_info!,
                    style: TextStyle(color: Colors.green.shade700), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'ورود' : 'ثبت‌نام'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                          _info = null;
                        }),
                child: Text(_isLogin ? 'حساب ندارید؟ ثبت‌نام کنید' : 'حساب دارید؟ وارد شوید'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                ),
                icon: const Icon(Icons.admin_panel_settings, size: 18),
                label: const Text('ورود مدیر'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
