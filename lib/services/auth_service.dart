// سرویس ورود و ثبت‌نام: دانش‌آموز با شماره موبایل + رمز، دبیر با ایمیل + رمز
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// تبدیل ارقام فارسی و عربی به انگلیسی و یکسان‌سازی شکل شماره
  static String normalizePhone(String input) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final ch in input.split('')) {
      final i = fa.indexOf(ch);
      final j = ar.indexOf(ch);
      if (i >= 0) {
        buf.write(i);
      } else if (j >= 0) {
        buf.write(j);
      } else if (RegExp(r'[0-9]').hasMatch(ch)) {
        buf.write(ch);
      }
    }
    var d = buf.toString();
    if (d.startsWith('0098')) {
      d = '0${d.substring(4)}';
    } else if (d.startsWith('98') && d.length == 12) {
      d = '0${d.substring(2)}';
    } else if (d.length == 10 && d.startsWith('9')) {
      d = '0$d';
    }
    return d;
  }

  static bool isValidPhone(String phone) =>
      RegExp(r'^09\d{9}$').hasMatch(normalizePhone(phone));

  static String _emailFromPhone(String phone) =>
      '${normalizePhone(phone)}@oloom-noh.app';

  /// ثبت‌نام دانش‌آموز
  static Future<void> registerStudent({
    required String phone,
    required String password,
    required String name,
    required String className,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _emailFromPhone(phone),
      password: password,
    );
    try {
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'phone': normalizePhone(phone),
        'class': className.trim(),
        'role': 'student',
        'onlineStatus': true,
        'progressPercent': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await cred.user!.delete();
      rethrow;
    }
  }

  /// ورود دانش‌آموز
  static Future<void> signInStudent(String phone, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: _emailFromPhone(phone),
      password: password,
    );
    try {
      await _db.collection('users').doc(cred.user!.uid).update({
        'onlineStatus': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// ورود دبیر (فقط اگر سندی در مجموعه admin داشته باشد)
  static Future<void> signInTeacher(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (!await isTeacher(cred.user!.uid)) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'not-teacher');
    }
  }

  /// آیا کاربر فعلی دبیر است؟
  static Future<bool> isTeacher([String? uid]) async {
    final id = uid ?? _auth.currentUser?.uid;
    if (id == null) return false;
    try {
      final doc = await _db.collection('admin').doc(id).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).update({'onlineStatus': false});
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// پیام خطای فارسی
  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'این شماره قبلاً ثبت‌نام کرده است. وارد شوید.';
        case 'weak-password':
          return 'رمز عبور باید حداقل ۶ کاراکتر باشد.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          return 'شماره یا رمز عبور اشتباه است.';
        case 'network-request-failed':
          return 'اتصال اینترنت را بررسی کنید.';
        case 'too-many-requests':
          return 'تلاش‌های زیاد. چند دقیقه بعد دوباره امتحان کنید.';
        case 'not-teacher':
          return 'این حساب دسترسی دبیر ندارد.';
      }
    }
    return 'خطایی رخ داد. دوباره تلاش کنید.';
  }
}
