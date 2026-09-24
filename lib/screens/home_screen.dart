// صفحه اصلی: ۱۵ فصل کتاب، دکمه خروج، و دکمه مدیریت (فقط برای دبیر)
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

  void _openAdminMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppTheme.primaryBlue),
              title: const Text('گزارش‌ها و داشبورد'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppTheme.accentOrange),
              title: const Text('مدیریت محتوا (PDF، تصاویر، آزمون)'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContentManagerScreen()),
                );
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF1E88E5)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 12, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherProfileScreen()),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: AppTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'علوم نهم – استاد ویسی',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isTeacher)
                      IconButton(
                        tooltip: 'مدیریت',
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                        onPressed: _openAdminMenu,
                      ),
                    IconButton(
                      tooltip: 'خروج',
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final title = scienceGrade9Chapters[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChapterDetailScreen(
                            chapterIndex: index,
                            chapterTitle: title,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: scienceGra
