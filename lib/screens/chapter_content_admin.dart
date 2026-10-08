// تب‌های پنل مدیریت برای محتوای فصل‌ها: خلاصه فصل، جواب فعالیت‌ها، خودآزمایی‌ها
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chapter_model.dart';

Widget _chapterDropdown({required int? value, required ValueChanged<int?> onChanged}) {
  return DropdownButtonFormField<int>(
    value: value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'انتخاب فصل', border: OutlineInputBorder()),
    items: List.generate(
      scienceGrade9Chapters.length,
      (i) => DropdownMenuItem(
        value: i,
        child: Text('فصل ${i + 1}: ${scienceGrade9Chapters[i]}', overflow: TextOverflow.ellipsis),
      ),
    ),
    onChanged: onChanged,
  );
}

// ------------------------------ خلاصه فصل ------------------------------
class SummaryAdminTab extends StatefulWidget {
  const SummaryAdminTab({super.key});

  @override
  State<SummaryAdminTab> createState() => _SummaryAdminTabState();
}

class _SummaryAdminTabState extends State<SummaryAdminTab> {
  int? _chapterIndex;
  final _controller = TextEditingController();
  bool _loading = false;
  bool _saving = false;

  String _id(int i) => 'chapter_${i + 1}';

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load(int i) async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('chapterContent').doc(_id(i)).get();
      final data = doc.data();
      if (!mounted) return;
      _controller.text = (data?['summary'] ?? data?['content'] ?? '').toString();
    } catch (e) {
      _snack('خطا: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_chapterIndex == null) {
      _snack('فصل را انتخاب کنید');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('chapterContent').doc(_id(_chapterIndex!)).set({
        'summary': _controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _snack('خلاصه فصل ذخیره شد ✅');
    } catch (e) {
      _snack('خطا: $e');
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
          _chapterDropdown(
            value: _chapterIndex,
            onChanged: (v) {
              setState(() => _chapterIndex = v);
              if (v != null) _load(v);
            },
          ),
          const SizedBox(height: 16),
          const Text('متن خلاصه فصل', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _loading
              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              : TextField(
                  controller: _controller,
                  minLines: 10,
                  maxLines: 20,
                  decoration: const InputDecoration(
                    hintText: 'خلاصه‌ی درس این فصل را اینجا بنویسید...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
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
                  : const Text('ذخیره خلاصه فصل'),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------- جواب فعالیت‌ها / خودآزمایی‌ها (افزودن، ویرایش، حذف، جابه‌جایی) -------------
class ItemsAdminTab extends StatefulWidget {
  final String collection; // activities | selfTests
  final String singular; // مثلاً «فعالیت» یا «خودآزمایی»
  final String titleHint;

  const ItemsAdminTab({
    super.key,
    required this.collection,
    required this.singular,
    required this.titleHint,
  });

  @override
  State<ItemsAdminTab> createState() => _ItemsAdminTabState();
}

class _ItemsAdminTabState extends State<ItemsAdminTab> {
  int? _chapterIndex;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  CollectionReference<Map<String, dynamic>> _col(int i) => FirebaseFirestore.instance
      .collection('chapterContent')
      .doc('chapter_${i + 1}')
      .collection(widget.collection);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _select(int? v) {
    setState(() {
      _chapterIndex = v;
      _stream = v == null ? null : _col(v).orderBy('order').snapshots();
    });
  }

  Future<void> _openEditor({
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
    required int nextOrder,
  }) async {
    final titleC = TextEditingController(text: (doc?.data()['title'] as String?) ?? '');
    final answerC = TextEditingController(text: (doc?.data()['answer'] as String?) ?? '');
    bool showError = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(doc == null ? 'افزودن ${widget.singular}' : 'ویرایش ${widget.singular}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: 'عنوان',
                    hintText: widget.titleHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerC,
                  minLines: 5,
                  maxLines: 12,
                  decoration: InputDecoration(
                    labelText: 'پاسخ',
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    errorText: showError ? 'عنوان و پاسخ را کامل کنید' : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (titleC.text.trim().isEmpty || answerC.text.trim().isEmpty) {
                  setD(() => showError = true);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted || _chapterIndex == null) return;
    try {
      final payload = {'title': titleC.text.trim(), 'answer': answerC.text.trim()};
      if (doc == null) {
        await _col(_chapterIndex!).add({
          ...payload,
          'order': nextOrder,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await doc.reference.update(payload);
      }
      _snack('ذخیره شد ✅');
    } catch (e) {
      _snack('خطا: $e');
    }
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف ${widget.singular}'),
        content: const Text('این مورد برای همیشه حذف می‌شود. مطمئنید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await doc.reference.delete();
    } catch (e) {
      _snack('خطا: $e');
    }
  }

  Future<void> _move(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, int index, int delta) async {
    final j = index + delta;
    if (j < 0 || j >= docs.length) return;
    final a = docs[index];
    final b = docs[j];
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(a.reference, {'order': b.data()['order']});
      batch.update(b.reference, {'order': a.data()['order']});
      await batch.commit();
    } catch (e) {
      _snack('خطا: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _chapterDropdown(value: _chapterIndex, onChanged: _select),
          const SizedBox(height: 12),
          if (_stream == null)
            const Expanded(
              child: Center(child: Text('یک فصل انتخاب کنید.', style: TextStyle(color: Colors.grey))),
            )
          else
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('خطا: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  final nextOrder = docs.isEmpty
                      ? 1
                      : docs
                              .map((d) => (d.data()['order'] as num?)?.toInt() ?? 0)
                              .reduce((a, b) => a > b ? a : b) +
                          1;
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openEditor(nextOrder: nextOrder),
                          icon: const Icon(Icons.add),
                          label: Text('افزودن ${widget.singular} جدید'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: docs.isEmpty
                            ? const Center(
                                child: Text('هنوز موردی ثبت نشده است.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: docs.length,
                                itemBuilder: (context, i) {
                                  final d = docs[i];
                                  final data = d.data();
                                  return Card(
                                    child: ListTile(
                                      title: Text((data['title'] ?? '').toString()),
                                      subtitle: Text(
                                        (data['answer'] ?? '').toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _openEditor(doc: d, nextOrder: nextOrder),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (v) {
                                          switch (v) {
                                            case 'edit':
                                              _openEditor(doc: d, nextOrder: nextOrder);
                                              break;
                                            case 'up':
                                              _move(docs, i, -1);
                                              break;
                                            case 'down':
                                              _move(docs, i, 1);
                                              break;
                                            case 'delete':
                                              _delete(d);
                                              break;
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                                          PopupMenuItem(value: 'up', child: Text('انتقال به بالا')),
                                          PopupMenuItem(value: 'down', child: Text('انتقال به پایین')),
                                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
