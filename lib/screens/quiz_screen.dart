// آزمون پایان فصل: سؤال تصادفی، گزینه‌های بُرزده، مرور اشتباهات و ثبت نمره (فقط یک‌بار)
import '../widgets/app_background.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/quiz_question.dart';
import '../services/sound_service.dart';

class QuizScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;

  const QuizScreen({super.key, required this.chapterId, required this.chapterTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizItem {
  final QuizQuestion q;
  final List<int> order; // ترتیب نمایش گزینه‌ها (اندیس اصلی هر گزینه)
  _QuizItem(this.q, this.order);
}

class _Answer {
  final _QuizItem item;
  final int chosen;
  _Answer(this.item, this.chosen);
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _perExam = 10;

  List<_QuizItem>? _items;
  String? _error;
  int _current = 0;
  int? _selected; // اندیس اصلی گزینه‌ی انتخاب‌شده
  int _score = 0;
  bool _finished = false;
  bool _saved = false;
  bool _saveFailed = false;
  final List<_Answer> _answers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.chapterId)
          .collection('questions')
          .get();
      final rnd = Random();
      final valid = <QuizQuestion>[];
      for (final d in snap.docs) {
        final q = QuizQuestion.fromMap(d.data(), d.id);
        final filled = [
          for (var i = 0; i < q.options.length; i++)
            if (q.options[i].trim().isNotEmpty) i
        ];
        final hasContent = q.question.trim().isNotEmpty || q.imageUrl != null;
        if (hasContent && filled.length >= 2 && filled.contains(q.correctIndex)) {
          valid.add(q);
        }
      }
      valid.shuffle(rnd);
      final items = valid.take(_perExam).map((q) {
        final order = [
          for (var i = 0; i < q.options.length; i++)
            if (q.options[i].trim().isNotEmpty) i
        ]..shuffle(rnd);
        return _QuizItem(q, order);
      }).toList();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = 'خطا در بارگذاری سؤال‌ها: $e');
    }
  }

  void _restart() {
    setState(() {
      _items = null;
      _error = null;
      _current = 0;
      _selected = null;
      _score = 0;
      _finished = false;
      _saved = false;
      _saveFailed = false;
      _answers.clear();
    });
    _load();
  }

  void _select(int original) {
    if (_selected != null) return;
    final item = _items![_current];
    setState(() {
      _selected = original;
      if (original == item.q.correctIndex) _score++;
      _answers.add(_Answer(item, original));
    });
    SoundService.play(original == item.q.correctIndex ? Sfx.correct : Sfx.wrong);
  }

  void _next() {
    if (_current < _items!.length - 1) {
      setState(() {
        _current++;
        _selected = null;
      });
    } else {
      setState(() => _finished = true);
      SoundService.play(_score * 2 >= _items!.length ? Sfx.success : Sfx.nav);
      _save();
    }
  }

  Future<void> _save() async {
    if (_saved) return;
    _saved = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exams')
          .add({
        'chapterId': widget.chapterId,
        'chapterTitle': widget.chapterTitle,
        'score': _score,
        'total': _items!.length,
        'wrongIds': [
          for (final a in _answers)
            if (a.chosen != a.item.q.correctIndex) a.item.q.id
        ],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: Text('آزمون: ${widget.chapterTitle}')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _restart, child: const Text('تلاش دوباره')),
            ],
          ),
        ),
      );
    }
    if (_items == null) return const Center(child: CircularProgressIndicator());
    if (_items!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('هنوز سؤال کاملی برای این فصل ثبت نشده است.', textAlign: TextAlign.center),
        ),
      );
    }
    return _finished ? _result() : _questionView();
  }

  Widget _questionView() {
    final total = _items!.length;
    final item = _items![_current];
    final q = item.q;
    return Column(
      children: [
        LinearProgressIndicator(value: (_current + (_selected == null ? 0 : 1)) / total),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سؤال ${_current + 1} از $total', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                if (q.question.trim().isNotEmpty)
                  Text(q.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.6)),
                if (q.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: q.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      memCacheWidth: 900,
                      placeholder: (_, __) => const SizedBox(
                          height: 120, child: Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                for (var p = 0; p < item.order.length; p++) _optionTile(q, item.order[p], p),
                if (_selected != null && q.explanation.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(q.explanation, style: const TextStyle(height: 1.7)),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null ? null : _next,
                child: Text(_current < total - 1 ? 'سؤال بعدی' : 'پایان آزمون'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionTile(QuizQuestion q, int i, int pos) {
    const letters = ['الف', 'ب', 'ج', 'د'];
    final answered = _selected != null;
    final isCorrect = i == q.correctIndex;
    final isChosen = i == _selected;
    Color? bg;
    Color border = Colors.transparent;
    IconData? trailing;
    Color? tc;
    if (answered) {
      if (isCorrect) {
        bg = Colors.green.withOpacity(0.15);
        border = Colors.green;
        trailing = Icons.check_circle;
        tc = Colors.green;
      } else if (isChosen) {
        bg = Colors.red.withOpacity(0.15);
        border = Colors.red;
        trailing = Icons.cancel;
        tc = Colors.red;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 1.6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: answered ? null : () => _select(i),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: (tc ?? AppTheme.primaryBlue).withOpacity(0.15),
                child: Text(
                  letters[pos < 4 ? pos : 3],
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: tc ?? AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(q.options[i], style: const TextStyle(fontSize: 15, height: 1.5))),
              if (trailing != null) Icon(trailing, color: tc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _result() {
    final total = _items!.length;
    final pct = (_score * 100 / total).round();
    final wrong = _answers.where((a) => a.chosen != a.item.q.correctIndex).toList();
    final msg = pct >= 80
        ? 'عالی بود! 🌟'
        : pct >= 50
            ? 'خوب است؛ اشتباهات را مرور کن.'
            : 'بیشتر مطالعه کن و دوباره تلاش کن.';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.emoji_events, color: AppTheme.accentOrange, size: 64),
        const SizedBox(height: 8),
        Text('نمره شما: $_score از $total  ($pct٪)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(msg, textAlign: TextAlign.center),
        if (_saveFailed)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('نمره ثبت نشد؛ اتصال اینترنت را بررسی کنید.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: _restart, child: const Text('آزمون دوباره'))),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بازگشت'),
              ),
            ),
          ],
        ),
        if (wrong.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('مرور اشتباهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          for (final a in wrong) _reviewCard(a),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('همه‌ی پاسخ‌ها درست بود 👏', textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Widget _reviewCard(_Answer a) {
    final q = a.item.q;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q.question.trim().isNotEmpty)
              Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, height: 1.6)),
            if (q.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: q.imageUrl!,
                    fit: BoxFit.contain,
                    memCacheWidth: 700,
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text('پاسخ شما: ${q.options[a.chosen]}', style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 4),
            Text('پاسخ درست: ${q.options[q.correctIndex]}',
                style: TextStyle(color: Colors.green.shade700)),
            if (q.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(q.explanation, style: const TextStyle(height: 1.7)),
            ],
          ],
        ),
      ),
    );
  }
}
