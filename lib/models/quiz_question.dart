// مدل سوال چهارگزینه‌ای برای آزمون‌های پایان فصل
class QuizQuestion {
  final String id;
  final String question;
  final String? imageUrl;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    this.imageUrl,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map, String id) {
    final img = map['imageUrl'];
    return QuizQuestion(
      id: id,
      question: (map['question'] ?? '').toString(),
      imageUrl: (img is String && img.isNotEmpty) ? img : null,
      options: List<String>.from((map['options'] ?? []).map((e) => e.toString())),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: (map['explanation'] ?? '').toString(),
    );
  }
}
