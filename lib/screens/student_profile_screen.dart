// پروفایل دانش‌آموز: مشخصات، آمار آزمون‌ها، ویرایش نام و کلاس، تنظیمات و خروج از حساب
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../services/sound_service.dart';
import '../services/theme_provider.dart';
import '../widgets/fade_slide.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late final DocumentReference<Map<String, dynamic>>? _ref = _user == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_user!.uid);
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream = _ref?.snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>>? _examStream =
      _ref?.collection('exams').snapshots();
  bool _sound = SoundService.enabled;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _colorFor(double pct) {
    if (pct >= 80) return Colors.green.shade700;
    if (pct >= 50) return AppTheme.accentOrange;
    return Colors.red.shade700;
  }

  int _ms(Map<String, dynamic> m) {
    final t = m['timestamp'];
    return t is Timestamp ? t.millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _edit(Map<String, dynamic>? data) async {
    final nameC = TextEditingController(text: (data?['name'] ?? '').toString());
    final classC = TextEditingController(text: (data?['class'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش مشخصات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                  labelText: 'نام و نام خانوادگی', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: classC,
              decoration: const InputDecoration(
                  labelText: 'کلاس (مثلاً نهم ۱)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok != true || _ref == null) return;
    try {
      await _ref!.update({'name': nameC.text.trim(), 'class': classC.text.trim()});
      _snack('مشخصات ذخیره شد ✅');
    } catch (e) {
      _snack('خطا: $e');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('می‌خواهید از حساب خود خارج شوید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل من')),
      body: _user == null
          ? const Center(child: Text('ابتدا وارد حساب خود شوید.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FadeSlide(child: _headerCard()),
                const SizedBox(height: 14),
                FadeSlide(delayMs: 100, child: _statsCard()),
                const SizedBox(height: 14),
                FadeSlide(delayMs: 180, child: _settingsCard()),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('خروج از حساب', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  // ------------------------------ مشخصات ------------------------------
  Widget _headerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userStream,
          builder: (context, snap) {
            final data = snap.data?.data();
            final name = (data?['name'] ?? '').toString().trim();
            final cls = (data?['class'] ?? '').toString().trim();
            final contact = _user!.email ?? _user!.phoneNumber ?? '';
            return Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, Color(0xFF42A5F5)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: name.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 44)
                      : Text(
                          String.fromCharCode(name.runes.first),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
                Text(name.isEmpty ? 'دانش‌آموز' : name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (cls.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Chip(
                    avatar: const Icon(Icons.class_outlined, size: 18, color: AppTheme.primaryBlue),
                    label: Text(cls),
                  ),
                ],
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(contact, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _edit(data),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('ویرایش مشخصات'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --------------------------- آمار آزمون‌ها ---------------------------
  Widget _statsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _examStream,
          builder: (context, snap) {
            final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final best = <String, double>{};
            final list = <Map<String, dynamic>>[];
            for (final d in docs) {
              final m = d.data();
              final total = (m['total'] as num?)?.toInt() ?? 0;
              final score = (m['score'] as num?)?.toInt() ?? 0;
              if (total <= 0) continue;
              final id = (m['chapterId'] ?? '').toString();
              final pct = score * 100 / total;
              if (pct > (best[id] ?? -1)) best[id] = pct;
              list.add({...m, 'pct': pct});
            }
            list.sort((a, b) => _ms(b).compareTo(_ms(a)));
            final avg = best.isEmpty ? 0 : best.values.reduce((a, b) => a + b) / best.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppTheme.accentOrange),
                    SizedBox(width: 8),
                    Text('آمار آزمون‌های من',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _stat(Icons.edit_note_rounded, '${list.length}', 'آزمون', const Color(0xFF1565C0))),
                    const SizedBox(width: 10),
                    Expanded(child: _stat(Icons.trending_up_rounded, '${avg.round()}٪', 'میانگین نمره', const Color(0xFF2E7D32))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat(Icons.menu_book_rounded,
                          '${best.length}/${scienceGrade9Chapters.length}', 'فصل آزموده', const Color(0xFF6A1B9A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  const Text('هنوز آزمونی نداده‌اید. از تب «آزمون» شروع کنید.',
                      style: TextStyle(color: Colors.grey))
                else ...[
                  const Text('آخرین آزمون‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  for (final m in list.take(5))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text((m['chapterTitle'] ?? '').toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${m['score']} از ${m['total']}'),
                      trailing: Text(
                        '${(m['pct'] as double).round()}٪',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _colorFor(m['pct'] as double)),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: c),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  // ------------------------------ تنظیمات ------------------------------
  Widget _settingsCard() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.primaryBlue),
            title: const Text('افکت‌های صوتی'),
            value: _sound,
            onChanged: (v) {
              setState(() => _sound = v);
              SoundService.setEnabled(v);
              if (v) SoundService.play(Sfx.tap);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded, color: AppTheme.primaryBlue),
            title: const Text('حالت شب'),
            value: dark,
            onChanged: (_) {
              SoundService.play(Sfx.tap);
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
