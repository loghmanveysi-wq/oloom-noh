// صفحه جزئیات هر فصل: PDF، گالری تصاویر، خلاصه، آزمون پایان فصل
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';
import 'quiz_screen.dart';

class ChapterDetailScreen extends StatelessWidget {
  final int chapterIndex;
  final String chapterTitle;

  const ChapterDetailScreen({
    super.key,
    required this.chapterIndex,
    required this.chapterTitle,
  });

  String get chapterId => 'chapter_${chapterIndex + 1}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapterTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _actionCard(
              context,
              icon: Icons.picture_as_pdf,
              color: AppTheme.primaryBlue,
              label: 'مطالعه PDF این فصل',
              onTap: () async {
                final book = await FirebaseFirestore.instance
                    .collection('books')
                    .where('chapter', isEqualTo: chapterId)
                    .limit(1)
                    .get();
                if (book.docs.isEmpty) return;
                final data = book.docs.first.data();
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: chapterTitle,
                      pdfUrl: data['pdfUrl'],
                      bookId: book.docs.first.id,
                    ),
                  ),
                );
              },
            ),
            _actionCard(
              context,
              icon: Icons.quiz,
              color: AppTheme.accentOrange,
              label: 'آزمون پایان فصل',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizScreen(chapterId: chapterId, chapterTitle: chapterTitle)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🖼️ گالری تصاویر آموزشی فصل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('images')
                  .doc(chapterId)
                  .collection('items')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('هنوز تصویری برای این فصل بارگذاری نشده است.');
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final img = docs[i].data() as Map<String, dynamic>;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: img['url'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            color: Colors.black54,
                            child: Text(
                              img['caption'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context,
      {required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
