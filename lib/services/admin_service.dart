// تشخیص مدیر (سازنده‌ی اپ) و تبدیل نام کاربری مدیر به ایمیل Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  /// دامنه‌ی داخلی برای ورود با «نام کاربری».
  /// مثال: نام کاربری veisi  →  veisi@admin.oloom-noh.app
  static const String adminEmailDomain = 'admin.oloom-noh.app';

  static String emailFromUsername(String input) {
    final v = input.trim().toLowerCase();
    return v.contains('@') ? v : '$v@$adminEmailDomain';
  }

  /// true فقط وقتی کاربر واردشده در Firestore نقش teacher داشته باشد
  static Stream<bool> isTeacherStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(false);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((d) => d.data()?['role'] == 'teacher');
    });
  }
}
