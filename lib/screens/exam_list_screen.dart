// فهرست فصل‌ها با بهترین نمره‌ی دانش‌آموز (داخل تب «رقابت» هم نمایش داده می‌شود)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import 'quiz_screen.dart';

class ExamListScreen extends StatelessWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آزمون‌ها')),
      body: const ExamListBody(),
    );
  }
}

/// محتوای فهرست آزمون‌ها (بدون Scaffold) تا در تب‌ها هم استفاده شود
class ExamListBody extends StatefulWidget {
  const ExamListBody({super.key});

  @override
  State<ExamListBody> createState() => _ExamListBodyState();
}

class _ExamListBodyState extends State<ExamListBody> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _stream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exams')
          .snapshots();
    }
  }

  Color _colorFor(double pct) {
    if (pct >= 80) return Colors.green.shade700;
    if (pct >= 50) return AppTheme.accentOrange;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return _stream == null
        ? _list(const {}, const {})
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              final best = <String, double>{};
              final attempts = <String, int>{};
              final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              for (final d in docs) {
                final m = d.data();
                final id = (m['chapterId'] ?? '').toString();
                final total = (m['total'] as num?)?.toInt() ?? 0;
                final score = (m['score'] as num?)?.toInt() ?? 0;
                if (id.isEmpty || total <= 0) continue;
                final pct = score * 100 / total;
                attempts[id] = (attempts[id] ?? 0) + 1;
                if (pct > (best[id] ?? -1)) best[id] = pct;
              }
              return _list(best, attempts);
            },
          );
  }

  Widget _list(Map<String, double> best, Map<String, int> attempts) {
    final totalAttempts = attempts.values.fold<int>(0, (a, b) => a + b);
    final avgBest = best.isEmpty ? 0 : best.values.reduce((a, b) => a + b) / best.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: totalAttempts == 0
                ? const Text('هنوز آزمونی نداده‌اید. یکی از فصل‌ها را انتخاب کنید.',
                    textAlign: TextAlign.center)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('تعداد آزمون', '$totalAttempts'),
                      _stat('میانگین بهترین نمره‌ها', '${avgBest.round()}٪'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < scienceGrade9Chapters.length; i++) _tile(i, best, attempts),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _tile(int i, Map<String, double> best, Map<String, int> attempts) {
    final id = 'chapter_${i + 1}';
    final title = scienceGrade9Chapters[i];
    final pct = best[id];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
          child: Text('${i + 1}',
              style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(pct == null
            ? 'هنوز آزمون نداده‌اید'
            : 'بهترین نمره: ${pct.round()}٪  •  ${attempts[id]} بار'),
        trailing: pct == null
            ? const Icon(Icons.chevron_left)
            : Text('${pct.round()}٪',
                style: TextStyle(fontWeight: FontWeight.bold, color: _colorFor(pct))),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizScreen(chapterId: id, chapterTitle: title)),
        ),
      ),
    );
  }
}
