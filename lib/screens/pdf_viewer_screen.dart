// صفحه نمایش PDF کتاب با بوکمارک، جستجو، ذخیره آخرین صفحه
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final String bookId;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.bookId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();
  int _currentPage = 1;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  @override
  void initState() {
    super.initState();
    _loadLastPage();
  }

  Future<void> _loadLastPage() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('pdfProgress')
        .doc(widget.bookId)
        .get();
    final lastPage = doc.data()?['lastPage'];
    if (lastPage != null && mounted) {
      _controller.jumpToPage(lastPage);
    }
  }

  Future<void> _saveProgress(int page) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('pdfProgress')
        .doc(widget.bookId)
        .set({
      'lastPage': page,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _saveProgress(_currentPage),
            tooltip: 'ذخیره بوکمارک این صفحه',
          ),
        ],
        bottom: _showSearchBar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'جستجو در متن کتاب...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (q) => _controller.searchText(q),
                  ),
                ),
              )
            : null,
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        key: _pdfKey,
        controller: _controller,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableTextSelection: true,
        onPageChanged: (details) {
          _currentPage = details.newPageNumber;
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _controller.previousPage(),
            ),
            Text('صفحه $_currentPage'),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _controller.nextPage(),
            ),
          ],
        ),
      ),
    );
  }
}
