// صفحه اصلی: نوار بالا با عکس استاد، کارت خوش‌آمدگویی، و ۱۵ کارت فصل
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import 'teacher_profile_screen.dart';
import 'chapter_detail_screen.dart';
import 'virtual_lab_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
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
                      child: Text('علوم نهم – استاد ویسی',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.notifications_none, color: Colors.white),
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
                        child: Text('${index + 1}', style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
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
                          builder: (_) => ChapterDetailScreen(chapterIndex: index, chapterTitle: title),
                        ),
                      ),
                    ),
                  );
                },
                childCount: scienceGrade9Chapters.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualLabScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileScreen()));
          }
          // شاخص ۱ (کتاب) و ۲ (آزمون) در مرحله بعد به صفحات مرتبط وصل می‌شوند
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
