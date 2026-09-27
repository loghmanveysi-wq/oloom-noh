// صفحه «کتاب»: نمایش و مطالعه فایل کامل کتاب علوم نهم
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('کتاب علوم نهم')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('books').doc('full_book').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطا در بارگذاری: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final pdfUrl = data?['pdfUrl'] as String?;
          final title = data?['title'] as String? ?? 'کتاب علوم نهم';

          if (pdfUrl == null || pdfUrl.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'هنوز فایل کتاب بارگذاری نشده است.\nاز پنل مدیریت محتوا می‌توانید آن را اضافه کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 88, color: AppTheme.primaryBlue),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('مطالعه کتاب'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            title: title,
                            pdfUrl: pdfUrl,
                            bookId: 'full_book',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
