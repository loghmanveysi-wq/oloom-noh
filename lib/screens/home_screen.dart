// صفحه اصلی: ۱۵ فصل، دکمه خروج، و دکمه مدیریت (فقط دبیر)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../services/auth_service.dart';
import 'teacher_profile_screen.dart';
import 'chapter_detail_screen.dart';
import 'virtual_lab_screen.dart';
import 'admin_dashboard_screen.dart';
import 'content_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    AuthService.isTeacher().then((v) {
      if (mounted) setState(() => _isTeacher = v);
    });
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openAdminMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppTheme.primaryBlue),
              title: const Text('گزارش‌ها و داشبورد'),
              onTap: () {
                Navigator.pop(ctx);
                _go(const AdminDashboardScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppTheme.accentOrange),
              title: const Text('مدیریت محتوا (PDF، تصاویر، آزمون)'),
              onTap: () {
                Navigator.pop(ctx);
                _go(const ContentManagerScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('از حساب خود خارج می‌شوید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('علوم نهم – استاد ویسی'),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => _go(const TeacherProfileScreen()),
        ),
        actions: [
          if (_isTeacher)
            IconButton(
              tooltip: 'مدیریت',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _openAdminMenu,
            ),
          IconButton(
            tooltip: 'خروج',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scienceGrade9Chapters.length,
        itemBuilder: (context, index) {
          final title = scienceGrade9Chapters[index];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(value: 0, minHeight: 6),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _go(
                ChapterDetailScreen(chapterIndex: index, chapterTitle: title),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 3) _go(const VirtualLabScreen());
          if (i == 4) _go(const TeacherProfileScreen());
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'کتاب'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'آزمون'),
          NavigationDestination(icon: Icon(Icons.science), label: 'آزمایشگاه'),
          NavigationDestination(icon: Icon(Icons.person), label: 'پروفایل'),
        ],
      ),
    );
  }
}
