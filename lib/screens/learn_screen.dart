// تب «آموزش»: فهرست ۱۵ فصل کتاب علوم نهم
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../services/sound_service.dart';
import '../widgets/fade_slide.dart';
import 'chapter_detail_screen.dart';
import 'ai_chat_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const List<Color> _palette = [
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 140,
          title: const Text('آموزش'),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton.icon(
                onPressed: () {
                  SoundService.play(Sfx.tap);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                },
                icon: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'هوش مصنوعی',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF42A5F5)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  const Icon(Icons.auto_stories, color: Colors.white70, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('فصل‌های کتاب علوم نهم',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('یک فصل را انتخاب کن و شروع کن',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final title = scienceGrade9Chapters[index];
                final c = _palette[index % _palette.length];
                return FadeSlide(
                  delayMs: (index % 6) * 60,
                  child: _chapterCard(context, index, title, c),
                );
              },
              childCount: scienceGrade9Chapters.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chapterCard(BuildContext context, int index, String title, Color c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          SoundService.play(Sfx.tap);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChapterDetailScreen(chapterIndex: index, chapterTitle: title),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: c),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [c, c.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text(
                              'خلاصه فصل  •  فعالیت‌ها',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, color: c, size: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
