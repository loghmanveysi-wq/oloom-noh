// صفحه جزئیات هر فصل: خلاصه فصل و فعالیت‌ها (پاسخ‌نامه‌ی فعالیت‌ها، آزمایش‌ها و خودآزمایی) + آزمون
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../widgets/attachments.dart';
import 'quiz_screen.dart';

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}

class ChapterDetailScreen extends StatefulWidget {
  final int chapterIndex;
  final String chapterTitle;

  const ChapterDetailScreen({
    super.key,
    required this.chapterIndex,
    required this.chapterTitle,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen>
    with SingleTickerProviderStateMixin {
  static const List<_TabInfo> _tabs = [
    _TabInfo('خلاصه فصل', Icons.menu_book_rounded),
    _TabInfo('فعالیت‌ها', Icons.edit_note_rounded),
  ];

  late final TabController _tc = TabController(length: _tabs.length, vsync: this);

  String get chapterId => 'chapter_${widget.chapterIndex + 1}';

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Widget _tabBox(int i, bool selected) {
    final info = _tabs[i];
    final fg = selected ? AppTheme.primaryBlue : Colors.white;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () {
          SoundService.play(Sfx.tap);
          _tc.animateTo(i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? Colors.white : Colors.white54, width: 1.2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(info.icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                info.label,
                style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: AnimatedBuilder(
              animation: _tc.animation!,
              builder: (context, _) {
                final sel = _tc.animation!.value.round();
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  children: [
                    for (var i = 0; i < _tabs.length; i++) _tabBox(i, sel == i),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.quiz),
        label: const Text('آزمون پایان فصل'),
        onPressed: () {
          SoundService.play(Sfx.tap);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(chapterId: chapterId, chapterTitle: widget.chapterTitle),
            ),
          );
        },
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _SummaryTab(chapterId: chapterId),
          _ActivitiesTab(chapterId: chapterId),
        ],
      ),
    );
  }
}

Widget _centerMessage(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ),
    );

// ------------------------------ خلاصه فصل ------------------------------
class _SummaryTab extends StatefulWidget {
  final String chapterId;
  const _SummaryTab({required this.chapterId});

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> with AutomaticKeepAliveClientMixin {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream = FirebaseFirestore.instance
      .collection('chapterContent')
      .doc(widget.chapterId)
      .snapshots();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _centerMessage('خطا در بارگذاری: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.data();
        final text = (data?['summary'] ?? data?['content'] ?? '').toString().trim();
        final atts = parseAttachments(data?['attachments']);
        if (text.isEmpty && atts.isEmpty) {
          return _centerMessage('هنوز خلاصه‌ای برای این فصل ثبت نشده است.');
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (text.isNotEmpty)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 6, color: AppTheme.accentOrange),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(text, style: const TextStyle(fontSize: 15, height: 1.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              AttachmentsView(items: atts),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------ فعالیت‌ها ------------------------------
class _ActivitiesTab extends StatefulWidget {
  final String chapterId;
  const _ActivitiesTab({required this.chapterId});

  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> with AutomaticKeepAliveClientMixin {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = FirebaseFirestore.instance
      .collection('chapterContent')
      .doc(widget.chapterId)
      .collection('activities')
      .orderBy('order')
      .snapshots();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _centerMessage('خطا در بارگذاری: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _centerMessage('هنوز فعالیتی برای این فصل ثبت نشده است.');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                title: Text((d['title'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((d['answer'] ?? '').toString().trim().isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SelectableText(
                        (d['answer'] ?? '').toString(),
                        style: const TextStyle(fontSize: 15, height: 1.9),
                      ),
                    ),
                  AttachmentsView(items: parseAttachments(d['attachments'])),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
