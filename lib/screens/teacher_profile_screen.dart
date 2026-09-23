// صفحه پروفایل استاد لقمان ویسی با قابلیت تغییر عکس پروفایل
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../services/cloudinary_service.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  String? _photoUrl;
  bool _uploading = false;

  // شناسه استاد - در نسخه نهایی از Firebase Auth گرفته می‌شود
  final String teacherId = 'loghman-veisi';

  Future<void> _pickAndUploadImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
              title: const Text('انتخاب از گالری'),
              onTap: () {
                Navigator.pop(ctx);
                _getImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.accentOrange),
              title: const Text('گرفتن عکس با دوربین'),
              onTap: () {
                Navigator.pop(ctx);
                _getImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    // برش دایره‌ای عکس
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      cropStyle: CropStyle.circle,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'برش عکس پروفایل',
          toolbarColor: AppTheme.primaryBlue,
          toolbarWidgetColor: Colors.white,
        ),
      ],
    );
    if (cropped == null) return;

    setState(() => _uploading = true);

    try {
      // آپلود عکس به Cloudinary به‌جای Firebase Storage
      final url = await CloudinaryService.uploadFile(
        File(cropped.path),
        folder: 'teachers/$teacherId',
      );

      await FirebaseFirestore.instance.collection('teachers').doc(teacherId).set(
        {'photoUrl': url},
        SetOptions(merge: true),
      );

      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در آپلود عکس: $e')),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل استاد')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('teachers').doc(teacherId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          _photoUrl ??= data?['photoUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
                      backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                      child: _uploading
                          ? const CircularProgressIndicator()
                          : (_photoUrl == null
                              ? const Icon(Icons.person, size: 60, color: AppTheme.primaryBlue)
                              : null),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: InkWell(
                        onTap: _pickAndUploadImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.accentOrange,
                          child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('📷 تغییر عکس پروفایل'),
                ),
                const SizedBox(height: 20),
                _infoCard('نام', data?['name'] ?? 'لقمان ویسی'),
                _infoCard('سمت', data?['title'] ?? 'دبیر علوم تجربی'),
                _infoCard('مدرسه', data?['school'] ?? 'دبیرستان ام‌المومنین روانسر'),
                _infoCard('شهر', data?['city'] ?? 'روانسر، استان کرمانشاه'),
                _infoCard('عناوین', data?['titles'] ??
                    'مدرس تیمز کشوری | سرگروه آموزشی علوم تجربی روانسر'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
