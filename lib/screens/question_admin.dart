// مدیریت بانک سؤال آزمون (فقط مدیر): افزودن، ویرایش، حذف، تصویر سؤال و توضیح پاسخ
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chapter_model.dart';
import '../models/quiz_question.dart';
import '../services/cloudinary_service.dart';

class QuestionsAdminTab extends StatefulWidget {
  const QuestionsAdminTab({super.key});

  @override
  State<QuestionsAdminTab> createState() => _QuestionsAdminTabState();
}

class _QuestionsAdminTabState extends State<QuestionsAdminTab> {
  int? _chapterIndex;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  CollectionReference<Map<String, dynamic>> _col(int i) => FirebaseFirestore.instance
      .collection('quizzes')
      .doc('chapter_${i + 1}')
      .collection('questions');

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _select(int? v) {
    setState(() {
      _chapterIndex = v;
      _stream = v == null ? null : _col(v).snapshots();
    });
  }

  Future<void> _openEditor([QueryDocumentSnapshot<Map<String, dynamic>>? doc]) async {
    final i = _chapterIndex;
    if (i == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _QuestionEditorPage(
          col: _col(i),
          chapterId: 'chapter_${i + 1}',
          doc: doc,
        ),
      ),
    );
    if (saved == true) _snack('ذخیره شد ✅');
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف سؤال'),
        content: const Text('این سؤال برای همیشه حذف می‌شود. مطمئنید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await doc.reference.delete();
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
          DropdownButtonFormField<int>(
            value: _chapterIndex,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'انتخاب فصل', border: OutlineInputBorder()),
            items: List.generate(
              scienceGrade9Chapters.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text('فصل ${i + 1}: ${scienceGrade9Chapters[i]}', overflow: TextOverflow.ellipsis),
              ),
            ),
            onChanged: _select,
          ),
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
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن سؤال جدید'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('تعداد سؤال‌های این فصل: ${docs.length}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: docs.isEmpty
                            ? const Center(
                                child: Text('هنوز سؤالی ثبت نشده است.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: docs.length,
                                itemBuilder: (context, i) {
                                  final d = docs[i];
                                  final q = QuizQuestion.fromMap(d.data(), d.id);
                                  final correct =
                                      q.correctIndex < q.options.length ? q.options[q.correctIndex] : '';
                                  return Card(
                                    child: ListTile(
                                      leading: q.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: q.imageUrl!,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                memCacheWidth: 150,
                                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                              ),
                                            )
                                          : CircleAvatar(child: Text('${i + 1}')),
                                      title: Text(
                                        q.question.trim().isEmpty ? '(سؤال تصویری)' : q.question,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text('پاسخ درست: $correct',
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      onTap: () => _openEditor(d),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') {
                                            _openEditor(d);
                                          } else if (v == 'delete') {
                                            _delete(d);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
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

// ------------------------- صفحه‌ی افزودن / ویرایش یک سؤال -------------------------
class _QuestionEditorPage extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> col;
  final String chapterId;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  const _QuestionEditorPage({required this.col, required this.chapterId, this.doc});

  @override
  State<_QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<_QuestionEditorPage> {
  final _question = TextEditingController();
  final _explanation = TextEditingController();
  final List<TextEditingController> _options = List.generate(4, (_) => TextEditingController());
  int _correct = 0;
  String? _imageUrl;
  File? _picked;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.doc?.data();
    if (d != null) {
      final q = QuizQuestion.fromMap(d, widget.doc!.id);
      _question.text = q.question;
      _explanation.text = q.explanation;
      _imageUrl = q.imageUrl;
      _correct = q.correctIndex < 4 ? q.correctIndex : 0;
      for (var i = 0; i < 4 && i < q.options.length; i++) {
        _options[i].text = q.options[i];
      }
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _explanation.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (x != null) setState(() => _picked = File(x.path));
  }

  Future<void> _save() async {
    final opts = _options.map((c) => c.text.trim()).toList();
    final filled = opts.where((o) => o.isNotEmpty).length;
    final hasImage = _picked != null || _imageUrl != null;
    if (_question.text.trim().isEmpty && !hasImage) {
      setState(() => _error = 'متن سؤال یا تصویر سؤال را وارد کنید.');
      return;
    }
    if (filled < 2) {
      setState(() => _error = 'حداقل دو گزینه را پر کنید.');
      return;
    }
    if (opts[_correct].isEmpty) {
      setState(() => _error = 'گزینه‌ی درست نباید خالی باشد.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? url = _imageUrl;
      if (_picked != null) {
        url = await CloudinaryService.uploadFile(_picked!, folder: 'quizzes/${widget.chapterId}');
      }
      final isEdit = widget.doc != null;
      final data = <String, dynamic>{
        'question': _question.text.trim(),
        'options': opts,
        'correctIndex': _correct,
        'explanation': _explanation.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (url != null) {
        data['imageUrl'] = url;
      } else if (isEdit) {
        data['imageUrl'] = FieldValue.delete();
      }
      if (isEdit) {
        await widget.doc!.reference.update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await widget.col.add(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = 'خطا: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview() {
    if (_picked != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_picked!, height: 180, width: double.infinity, fit: BoxFit.contain),
      );
    }
    if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: _imageUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _picked != null || _imageUrl != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.doc == null ? 'افزودن سؤال' : 'ویرایش سؤال')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _question,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'متن سؤال (اگر سؤال فقط تصویر است، خالی بگذارید)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _preview(),
            if (hasImage) const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pick,
                  icon: const Icon(Icons.image),
                  label: Text(hasImage ? 'تعویض تصویر سؤال' : 'افزودن تصویر سؤال (اختیاری)'),
                ),
                if (hasImage)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _picked = null;
                              _imageUrl = null;
                            }),
                    child: const Text('حذف تصویر', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('گزینه‌ها (گزینه‌ی درست را با دکمه‌ی رادیویی مشخص کنید)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correct,
                      onChanged: (v) => setState(() => _correct = v ?? 0),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        decoration: InputDecoration(
                          labelText: 'گزینه ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _explanation,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'توضیح پاسخ (اختیاری؛ بعد از جواب دادن نمایش داده می‌شود)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ذخیره سؤال'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
