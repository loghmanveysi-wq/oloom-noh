// پنل مدیریت محتوا: افزودن سؤال آزمون، تصویر فصل، و PDF کتاب
// بدون نیاز به رفتن به Firebase Console
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../services/cloudinary_service.dart';

class ContentManagerScreen extends StatefulWidget {
  const ContentManagerScreen({super.key});

  @override
  State<ContentManagerScreen> createState() => _ContentManagerScreenState();
}

class _ContentManagerScreenState extends State<ContentManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت محتوا'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'سؤال آزمون'),
              Tab(text: 'تصویر فصل'),
              Tab(text: 'کتاب PDF'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AddQuestionTab(),
            _AddImageTab(),
            _AddBookTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------
// تب ۱: افزودن سؤال آزمون
// -------------------------------------------------
class _AddQuestionTab extends StatefulWidget {
  const _AddQuestionTab();

  @override
  State<_AddQuestionTab> createState() => _AddQuestionTabState();
}

class _AddQuestionTabState extends State<_AddQuestionTab> {
  int? _chapterIndex;
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;
  bool _saving = false;

  Future<void> _save() async {
    if (_chapterIndex == null || _questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فصل و متن سؤال را وارد کنید')));
      return;
    }
    setState(() => _saving = true);
    final chapterId = 'chapter_${_chapterIndex! + 1}';
    try {
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(chapterId)
          .collection('questions')
          .add({
        'question': _questionController.text.trim(),
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correctIndex': _correctIndex,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('سؤال با موفقیت ذخیره شد ✅')));
        _questionController.clear();
        for (final c in _optionControllers) {
          c.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('انتخاب فصل', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _chapterIndex,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: List.generate(
              scienceGrade9Chapters.length,
              (i) => DropdownMenuItem(value: i, child: Text('فصل ${i + 1}: ${scienceGrade9Chapters[i]}')),
            ),
            onChanged: (v) => setState(() => _chapterIndex = v),
          ),
          const SizedBox(height: 16),
          const Text('متن سؤال', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            maxLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('گزینه‌ها (گزینه درست را با دکمه رادیویی مشخص کنید)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: _correctIndex,
                    onChanged: (v) => setState(() => _correctIndex = v!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _optionControllers[i],
                      decoration: InputDecoration(
                        labelText: 'گزینه ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ذخیره سؤال'),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------
// تب ۲: افزودن تصویر آموزشی فصل
// -------------------------------------------------
class _AddImageTab extends StatefulWidget {
  const _AddImageTab();

  @override
  State<_AddImageTab> createState() => _AddImageTabState();
}

class _AddImageTabState extends State<_AddImageTab> {
  int? _chapterIndex;
  final _captionController = TextEditingController();
  File? _pickedImage;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_chapterIndex == null || _pickedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فصل و عکس را انتخاب کنید')));
      return;
    }
    setState(() => _uploading = true);
    final chapterId = 'chapter_${_chapterIndex! + 1}';
    try {
      final url = await CloudinaryService.uploadFile(_pickedImage!, folder: 'images/$chapterId');
      await FirebaseFirestore.instance
          .collection('images')
          .doc(chapterId)
          .collection('items')
          .add({
        'url': url,
        'caption': _captionController.text.trim(),
        'order': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تصویر با موفقیت اضافه شد ✅')));
        setState(() {
          _pickedImage = null;
          _captionController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('انتخاب فصل', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _chapterIndex,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: List.generate(
              scienceGrade9Chapters.length,
              (i) => DropdownMenuItem(value: i, child: Text('فصل ${i + 1}: ${scienceGrade9Chapters[i]}')),
            ),
            onChanged: (v) => setState(() => _chapterIndex = v),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _pickedImage == null
                  ? const Center(child: Icon(Icons.add_photo_alternate, size: 48, color: AppTheme.primaryBlue))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(labelText: 'زیرنویس تصویر', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading ? null : _upload,
              child: _uploading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('آپلود تصویر'),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------
// تب ۳: افزودن PDF کتاب
// -------------------------------------------------
class _AddBookTab extends StatefulWidget {
  const _AddBookTab();

  @override
  State<_AddBookTab> createState() => _AddBookTabState();
}

class _AddBookTabState extends State<_AddBookTab> {
  int? _chapterIndex;
  final _titleController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _uploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedFile = result.files.single);
    }
  }

  Future<void> _upload() async {
    if (_chapterIndex == null || _pickedFile == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فصل، عنوان و فایل PDF را وارد کنید')));
      return;
    }
    setState(() => _uploading = true);
    final chapterId = 'chapter_${_chapterIndex! + 1}';
    try {
      final file = File(_pickedFile!.path!);
      final url = await CloudinaryService.uploadFile(file, folder: 'books/$chapterId');
      await FirebaseFirestore.instance.collection('books').add({
        'title': _titleController.text.trim(),
        'chapter': chapterId,
        'pdfUrl': url,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF با موفقیت اضافه شد ✅')));
        setState(() {
          _pickedFile = null;
          _titleController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('انتخاب فصل', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _chapterIndex,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: List.generate(
              scienceGrade9Chapters.length,
              (i) => DropdownMenuItem(value: i, child: Text('فصل ${i + 1}: ${scienceGrade9Chapters[i]}')),
            ),
            onChanged: (v) => setState(() => _chapterIndex = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'عنوان کتاب/جزوه', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_pickedFile == null ? 'انتخاب فایل PDF' : 'فایل انتخاب شد ✓'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading ? null : _upload,
              child: _uploading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('آپلود PDF'),
            ),
          ),
        ],
      ),
    );
  }
}
