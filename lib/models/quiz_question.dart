// مدل سوال چهارگزینه‌ای برای آزمون‌های پایان فصل
class QuizQuestion {
  final String id;
  final String question;
  final String? imageUrl;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    this.imageUrl,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map, String id) {
    return QuizQuestion(
      id: id,
      question: map['question'] ?? '',
      imageUrl: map['imageUrl'],
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }
}
