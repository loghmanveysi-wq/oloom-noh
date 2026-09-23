// صفحه اجرای آزمون پایان فصل + ثبت نمره در پنل دبیر
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/quiz_question.dart';

class QuizScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;

  const QuizScreen({super.key, required this.chapterId, required this.chapterTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _finished = false;

  Future<void> _submitResult(int total) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('exams')
        .add({
      'chapterId': widget.chapterId,
      'score': _score,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('آزمون: ${widget.chapterTitle}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.chapterId)
            .collection('questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final questions = snapshot.data!.docs
              .map((d) => QuizQuestion.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();

          if (questions.isEmpty) {
            return const Center(child: Text('هنوز سؤالی برای این فصل ثبت نشده است.'));
          }

          if (_finished) {
            _submitResult(questions.length);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: AppTheme.accentOrange, size: 64),
                  const SizedBox(height: 12),
                  Text('نمره شما: $_score از ${questions.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('بازگشت به فصل'),
                  ),
                ],
              ),
            );
          }

          final q = questions[_current];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: (_current + 1) / questions.length),
                const SizedBox(height: 16),
                Text('سؤال ${_current + 1} از ${questions.length}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (q.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: q.imageUrl!, height: 180, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 20),
                ...List.generate(q.options.length, (i) {
                  final isSelected = _selected == i;
                  final isCorrect = i == q.correctIndex;
                  Color? color;
                  if (_selected != null) {
                    if (isCorrect) color = Colors.green.withOpacity(0.2);
                    else if (isSelected) color = Colors.red.withOpacity(0.2);
                  }
                  return Card(
                    color: color,
                    child: ListTile(
                      title: Text(q.options[i]),
                      onTap: _selected == null
                          ? () {
                              setState(() {
                                _selected = i;
                                if (i == q.correctIndex) _score++;
                              });
                            }
                          : null,
                    ),
                  );
                }),
                const Spacer(),
                if (_selected != null)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_current < questions.length - 1) {
                          _current++;
                          _selected = null;
                        } else {
                          _finished = true;
                        }
                      });
                    },
                    child: Text(_current < questions.length - 1 ? 'سؤال بعدی' : 'پایان آزمون'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
