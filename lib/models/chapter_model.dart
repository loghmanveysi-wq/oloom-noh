// مدل داده هر فصل از کتاب علوم نهم
class ChapterModel {
  final int id;
  final String title;
  final String coverImageUrl;
  final double progressPercent; // بین ۰ تا ۱۰۰
  final String pdfUrl;

  ChapterModel({
    required this.id,
    required this.title,
    this.coverImageUrl = '',
    this.progressPercent = 0,
    this.pdfUrl = '',
  });

  factory ChapterModel.fromMap(Map<String, dynamic> map, int id) {
    return ChapterModel(
      id: id,
      title: map['title'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      progressPercent: (map['progressPercent'] ?? 0).toDouble(),
      pdfUrl: map['pdfUrl'] ?? '',
    );
  }
}

// لیست ثابت ۱۵ فصل کتاب علوم تجربی پایه نهم
final List<String> scienceGrade9Chapters = [
  'مواد و نقش آنها در زندگی',
  'رفتار اتم‌ها با یکدیگر',
  'به دنبال محیطی بهتر برای زندگی',
  'حرکت چیست؟',
  'نیرو',
  'زمین‌ساخت ورقه‌ای',
  'آثاری از گذشته زمین',
  'فشار و آثار آن',
  'ماشین‌ها',
  'نگاهی به فضا',
  'گوناگونی جانداران',
  'دنیای گیاهان',
  'جانوران بی‌مهره',
  'جانوران مهره‌دار',
  'با هم زیستن',
];
