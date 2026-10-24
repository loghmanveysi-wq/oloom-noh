// پنل مدیریت (فقط برای مدیر): خلاصه فصل، فعالیت‌ها، سؤال آزمون، کتاب PDF و جدول دانش‌آموزان
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import '../widgets/boxed_tab_bar.dart';
import 'chapter_content_admin.dart';
import 'question_admin.dart';
import 'students_table_tab.dart';

class ContentManagerScreen extends StatelessWidget {
  const ContentManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AdminService.isTeacherStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('پنل مدیریت')),
            body: const Center(child: Text('این بخش فقط برای مدیر است.')),
          );
        }
        return const _ContentManagerBody();
      },
    );
  }
}

class _ContentManagerBody extends StatelessWidget {
  const _ContentManagerBody();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت'),
          bottom: const BoxedTabBar(
            labels: [
              'خلاصه فصل',
              'فعالیت‌ها',
              'سؤال آزمون',
              'کتاب PDF',
              'دانش‌آموزان',
            ],
            icons: [
              Icons.menu_book_rounded,
              Icons.edit_note_rounded,
              Icons.quiz_rounded,
              Icons.picture_as_pdf_rounded,
              Icons.groups_rounded,
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SummaryAdminTab(),
            ItemsAdminTab(
              collection: 'activities',
              singular: 'فعالیت',
              titleHint: 'مثلاً: پاسخ‌نامه‌ی فعالیت‌ها، آزمایش‌ها و خودآزمایی',
            ),
            QuestionsAdminTab(),
            _AddBookTab(),
            StudentsTableTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------
// تب: افزودن PDF کتاب
// -------------------------------------------------
class _AddBookTab extends StatefulWidget {
  const _AddBookTab();

  @override
  State<_AddBookTab> createState() => _AddBookTabState();
}

class _AddBookTabState extends State<_AddBookTab> {
  final _titleController = TextEditingController(text: 'کتاب علوم نهم');
  final _urlController = TextEditingController();
  bool _saving = false;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final doc = await FirebaseFirestore.instance.collection('books').doc('full_book').get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _currentUrl = data['pdfUrl'];
        if (data['title'] != null) _titleController.text = data['title'];
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('عنوان و لینک PDF را وارد کنید')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('books').doc('full_book').set({
        'title': _titleController.text.trim(),
        'pdfUrl': _urlController.text.trim(),
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('کتاب با موفقیت ثبت/به\u200cروزرسانی شد \u2705')));
        setState(() {
          _currentUrl = _urlController.text.trim();
          _urlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'راهنما: کل فایل PDF کتاب علوم نهم را اول در سایت Cloudinary (بخش Media Library) آپلود کنید، '
              'سپس لینک آن (secure_url) را اینجا paste کنید. این کتاب مستقل از فصل\u200cهاست و در بخش «کتاب» نمایش داده می\u200cشود.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          if (_currentUrl != null && _currentUrl!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('کتاب فعلی ثبت شده است \u2705', style: TextStyle(color: Colors.green.shade800)),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'عنوان کتاب', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'لینک PDF جدید (از Cloudinary)',
              hintText: 'https://res.cloudinary.com/...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ثبت / به\u200cروزرسانی کتاب'),
            ),
          ),
        ],
      ),
    );
  }
}
