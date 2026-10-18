// پیوست‌های محتوا (تصویر، ویدیو، فایل): ویرایشگر برای مدیر و نمایش برای دانش‌آموز
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/cloudinary_service.dart';
import '../screens/media_viewer_screen.dart';

const List<String> _imageExt = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
const List<String> _videoExt = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v'];

String _extOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// نوع پیوست را از روی پسوند فایل تشخیص می‌دهد: image | video | file
String attachmentTypeOf(String name) {
  final ext = _extOf(name);
  if (_imageExt.contains(ext)) return 'image';
  if (_videoExt.contains(ext)) return 'video';
  return 'file';
}

/// تبدیل فیلد attachments سند Firestore به فهرست امن
List<Map<String, dynamic>> parseAttachments(dynamic raw) {
  if (raw is! List) return [];
  final out = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is Map && (e['url'] ?? '').toString().isNotEmpty) {
      out.add({
        'type': (e['type'] ?? 'file').toString(),
        'url': e['url'].toString(),
        'name': (e['name'] ?? '').toString(),
      });
    }
  }
  return out;
}

String _typeLabel(String type) {
  switch (type) {
    case 'image':
      return 'تصویر';
    case 'video':
      return 'ویدیو';
    default:
      return 'فایل';
  }
}

// ============================ ویرایشگر (مدیر) ============================
class AttachmentsEditor extends StatefulWidget {
  final List<Map<String, dynamic>> initial;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final ValueChanged<bool>? onBusyChanged;
  final String folder;

  const AttachmentsEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.folder,
    this.onBusyChanged,
  });

  @override
  State<AttachmentsEditor> createState() => _AttachmentsEditorState();
}

class _AttachmentsEditorState extends State<AttachmentsEditor> {
  static const int _maxVideoMb = 100;
  static const int _maxOtherMb = 10;

  late final List<Map<String, dynamic>> _items = [
    for (final e in widget.initial) Map<String, dynamic>.from(e),
  ];
  bool _busy = false;
  String _busyText = '';
  String? _error;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (x != null) await _upload(File(x.path), 'image', x.name);
  }

  Future<void> _pickVideo() async {
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (x != null) await _upload(File(x.path), 'video', x.name);
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles();
    final f = r?.files.single;
    if (f == null || f.path == null) return;
    await _upload(File(f.path!), attachmentTypeOf(f.name), f.name);
  }

  Future<void> _upload(File file, String type, String name) async {
    final size = await file.length();
    final maxMb = type == 'video' ? _maxVideoMb : _maxOtherMb;
    if (size > maxMb * 1024 * 1024) {
      setState(() => _error = 'حجم فایل بیش از $maxMb مگابایت است (سقف پلن رایگان Cloudinary).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _busyText = type == 'video'
          ? 'در حال آپلود ویدیو؛ ممکن است چند دقیقه طول بکشد...'
          : 'در حال آپلود...';
    });
    widget.onBusyChanged?.call(true);
    try {
      final url = await CloudinaryService.uploadFile(file, folder: widget.folder);
      if (!mounted) return;
      setState(() => _items.add({'type': type, 'url': url, 'name': name}));
      widget.onChanged(List<Map<String, dynamic>>.of(_items));
    } catch (e) {
      if (mounted) setState(() => _error = 'خطا در آپلود: $e');
    } finally {
      widget.onBusyChanged?.call(false);
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int i) {
    setState(() => _items.removeAt(i));
    widget.onChanged(List<Map<String, dynamic>>.of(_items));
  }

  Widget _thumb(Map<String, dynamic> a) {
    switch (a['type']) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: a['url'].toString(),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            memCacheWidth: 150,
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        );
      case 'video':
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.play_circle_fill, color: Colors.white),
        );
      default:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.insert_drive_file, color: AppTheme.primaryBlue),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('پیوست‌ها (تصویر، ویدیو، فایل)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: _thumb(_items[i]),
              title: Text(
                (_items[i]['name'] ?? '').toString().isEmpty
                    ? _typeLabel(_items[i]['type'].toString())
                    : _items[i]['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_typeLabel(_items[i]['type'].toString())),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _busy ? null : () => _remove(i),
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('تصویر'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickVideo,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('ویدیو'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('فایل'),
            ),
          ],
        ),
        if (_busy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Expanded(child: Text(_busyText, style: const TextStyle(fontSize: 12.5))),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'ویدیو را ترجیحاً با فرمت MP4 بگذارید. سقف حجم: ویدیو ۱۰۰ مگابایت، بقیه ۱۰ مگابایت.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ======================== نمایش برای دانش‌آموز ========================
class AttachmentsView extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const AttachmentsView({super.key, required this.items});

  IconData _fileIcon(String name) {
    switch (_extOf(name)) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in items)
          Padding(padding: const EdgeInsets.only(top: 12), child: _item(context, a)),
      ],
    );
  }

  Widget _item(BuildContext context, Map<String, dynamic> a) {
    final url = a['url'].toString();
    final name = (a['name'] ?? '').toString();
    switch (a['type']) {
      case 'image':
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ImageViewerScreen(url: url)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              memCacheWidth: 900,
              placeholder: (_, __) =>
                  const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        );
      case 'video':
        return Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url, title: name)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'پخش ویدیو' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Text('برای پخش لمس کنید',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(_fileIcon(name), color: AppTheme.primaryBlue),
            title: Text(name.isEmpty ? 'فایل پیوست' : name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text('برای باز کردن لمس کنید'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        );
    }
  }
}
