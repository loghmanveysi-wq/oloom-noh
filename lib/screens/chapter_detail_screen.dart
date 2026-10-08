// صفحه جزئیات هر فصل: خلاصه فصل، جواب فعالیت‌ها، خودآزمایی‌ها، گالری تصاویر + آزمون
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(chapterTitle),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'خلاصه فصل'),
              Tab(text: 'جواب فعالیت‌ها'),
              Tab(text: 'خودآزمایی‌ها'),
              Tab(text: 'گالری تصاویر'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.accentOrange,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.quiz),
          label: const Text('آزمون پایان فصل'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(chapterId: chapterId, chapterTitle: chapterTitle),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(chapterId: chapterId),
            _AnswersTab(
              chapterId: chapterId,
              collection: 'activities',
              emptyText: 'هنوز جواب فعالیتی برای این فصل ثبت نشده است.',
            ),
            _AnswersTab(
              chapterId: chapterId,
              collection: 'selfTests',
              emptyText: 'هنوز خودآزمایی‌ای برای این فصل ثبت نشده است.',
            ),
            _GalleryTab(chapterId: chapterId),
          ],
        ),
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
        if (text.isEmpty) return _centerMessage('هنوز خلاصه‌ای برای این فصل ثبت نشده است.');
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(text, style: const TextStyle(fontSize: 15, height: 1.9)),
          ),
        );
      },
    );
  }
}

// ------------------- جواب فعالیت‌ها / خودآزمایی‌ها -------------------
class _AnswersTab extends StatefulWidget {
  final String chapterId;
  final String collection; // activities | selfTests
  final String emptyText;
  const _AnswersTab({required this.chapterId, required this.collection, required this.emptyText});

  @override
  State<_AnswersTab> createState() => _AnswersTabState();
}

class _AnswersTabState extends State<_AnswersTab> with AutomaticKeepAliveClientMixin {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = FirebaseFirestore.instance
      .collection('chapterContent')
      .doc(widget.chapterId)
      .collection(widget.collection)
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
        if (docs.isEmpty) return _centerMessage(widget.emptyText);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text((d['title'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelectableText(
                      (d['answer'] ?? '').toString(),
                      style: const TextStyle(fontSize: 15, height: 1.9),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------------------ گالری ------------------------------
class _GalleryTab extends StatefulWidget {
  final String chapterId;
  const _GalleryTab({required this.chapterId});

  @override
  State<_GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<_GalleryTab> with AutomaticKeepAliveClientMixin {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = FirebaseFirestore.instance
      .collection('images')
      .doc(widget.chapterId)
      .collection('items')
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
        if (docs.isEmpty) return _centerMessage('هنوز تصویری برای این فصل بارگذاری نشده است.');
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final img = docs[i].data();
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: (img['url'] ?? '').toString(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      memCacheWidth: 600,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    color: Colors.black54,
                    child: Text(
                      (img['caption'] ?? '').toString(),
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
    );
  }
}
