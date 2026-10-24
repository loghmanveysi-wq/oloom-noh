// منطق رقابت زنده: اطلاعات بازیکن، انتخاب سؤال‌ها، ثبت آمار و امتیاز
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_question.dart';

class CompetitionService {
  static const int rounds = 4; // ۴ نوبت یکی‌درمیان: هر بازیکن ۲ نوبت
  static const int perRound = 3; // هر نوبت ۳ سؤال
  static const int total = rounds * perRound; // ۱۲ سؤال

  static const int pointsWin = 20; // امتیاز برد
  static const int pointsDraw = 10; // امتیاز مساوی
  static const int pointsLoss = 0; // امتیاز باخت

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// نام و عکس کاربر برای نمایش به حریف
  static Future<Map<String, String>> myInfo() async {
    final u = uid;
    if (u == null) return {'name': 'بازیکن', 'photo': ''};
    final d = await _db.collection('users').doc(u).get();
    final m = d.data();
    var name = (m?['name'] ?? '').toString().trim();
    if (name.isEmpty) name = 'بازیکن';
    return {'name': name, 'photo': (m?['photoUrl'] ?? '').toString()};
  }

  /// ۱۲ سؤال تصادفی از بانک سؤال فصل‌ها. گزینه‌ها همین‌جا بُرزده می‌شوند و «ans» اندیس پاسخ درست است.
  static Future<List<Map<String, dynamic>>> pickQuestions() async {
    final rnd = Random();
    final chapters = List<int>.generate(15, (i) => i + 1)..shuffle(rnd);
    final pool = <Map<String, dynamic>>[];
    for (final ch in chapters) {
      final snap =
          await _db.collection('quizzes').doc('chapter_$ch').collection('questions').get();
      for (final d in snap.docs) {
        final q = QuizQuestion.fromMap(d.data(), d.id);
        final filled = [
          for (var i = 0; i < q.options.length; i++)
            if (q.options[i].trim().isNotEmpty) i
        ];
        final hasContent = q.question.trim().isNotEmpty || q.imageUrl != null;
        if (hasContent && filled.length >= 2 && filled.contains(q.correctIndex)) {
          final order = List<int>.of(filled)..shuffle(rnd);
          pool.add({
            'id': d.id,
            'q': q.question,
            if (q.imageUrl != null) 'img': q.imageUrl,
            'opts': [for (final i in order) q.options[i]],
            'ans': order.indexOf(q.correctIndex),
          });
        }
      }
      if (pool.length >= total * 2) break;
    }
    if (pool.isEmpty) return [];
    pool.shuffle(rnd);
    // اگر سؤال کم باشد، سؤال‌ها تکرار می‌شوند
    return [for (var i = 0; i < total; i++) pool[i % pool.length]];
  }

  static int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

  static String today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// ثبت نتیجه‌ی بازی: آمار کاربر + امتیاز + جدول رتبه‌بندی عمومی. result = win | loss | draw
  static Future<void> recordResult(String result) async {
    final u = uid;
    if (u == null) return;
    final ref = _db.collection('users').doc(u);
    final lbRef = _db.collection('leaderboard').doc(u);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final comp = Map<String, dynamic>.from((data?['comp'] as Map?) ?? {});
      final day = today();
      final sameDay = comp['day'] == day;
      final gain =
          result == 'win' ? pointsWin : (result == 'draw' ? pointsDraw : pointsLoss);
      comp['games'] = _n(comp['games']) + 1;
      comp['wins'] = _n(comp['wins']) + (result == 'win' ? 1 : 0);
      comp['losses'] = _n(comp['losses']) + (result == 'loss' ? 1 : 0);
      comp['draws'] = _n(comp['draws']) + (result == 'draw' ? 1 : 0);
      comp['points'] = _n(comp['points']) + gain;
      comp['today'] = (sameDay ? _n(comp['today']) : 0) + 1;
      comp['day'] = day;
      tx.update(ref, {'comp': comp});

      var name = (data?['name'] ?? '').toString().trim();
      if (name.isEmpty) name = 'بازیکن';
      tx.set(
        lbRef,
        {
          'name': name,
          'photo': (data?['photoUrl'] ?? '').toString(),
          'points': comp['points'],
          'wins': comp['wins'],
          'losses': comp['losses'],
          'draws': comp['draws'],
          'games': comp['games'],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
