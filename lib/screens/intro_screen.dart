// صفحه «خانه» (دکمه‌ی وسط): معرفی نرم‌افزار و معرفی سازنده
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide.dart';
import '../services/admin_service.dart';
import '../services/sound_service.dart';
import '../services/theme_provider.dart';
import 'ai_chat_screen.dart';
import 'admin_dashboard_screen.dart';
import 'content_manager_screen.dart';
import 'student_profile_screen.dart';

class IntroScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const IntroScreen({super.key, required this.onNavigate});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const String _teacherPhoto = 'assets/images/teacher.jpg';

  bool _sound = SoundService.enabled;
  late final Stream<bool> _admin = AdminService.isTeacherStream();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _me =
      FirebaseAuth.instance.currentUser == null
          ? null
          : FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots();

  void _toggleSound() {
    setState(() => _sound = !_sound);
    SoundService.setEnabled(_sound);
    if (_sound) SoundService.play(Sfx.tap);
  }

  void _push(Widget page) {
    SoundService.play(Sfx.tap);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _hero(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  FadeSlide(child: _aboutCard()),
                  const SizedBox(height: 16),
                  FadeSlide(delayMs: 120, child: _aiBanner()),
                  const SizedBox(height: 16),
                  FadeSlide(delayMs: 200, child: _creatorCard()),
                  const SizedBox(height: 18),
                  const Text(
                    'نسخه ۱.۰  •  ساخته‌شده با ❤ برای دانش‌آموزان',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------ سربرگ ------------------------------
  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _hero(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF42A5F5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(top: -40, left: -30, child: _bubble(140, 0.10)),
          Positioned(bottom: -50, right: -20, child: _bubble(170, 0.08)),
          Padding(
            padding: EdgeInsets.fromLTRB(8, top + 4, 8, 28),
            child: Column(
              children: [
                Row(children: [_profileButton(), const Spacer(), ..._topIcons(context)]),
                const SizedBox(height: 4),
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.science, size: 46, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 12),
                const Text(
                  'علوم نهم',
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'همراه شما برای یادگیری علوم تجربی',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دکمه‌ی پروفایل دانش‌آموز (بالا سمت راست): عکس شخصی یا حرف اول نام
  Widget _profileButton() {
    return Tooltip(
      message: 'پروفایل من',
      child: GestureDetector(
        onTap: () => _push(const StudentProfileScreen()),
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white54, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _me,
            builder: (context, snap) {
              final data = snap.data?.data();
              final name = (data?['name'] ?? '').toString().trim();
              final photo = (data?['photoUrl'] ?? '').toString().trim();
              if (photo.isNotEmpty) {
                return ClipOval(
                  child: SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: photo,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, color: AppTheme.primaryBlue),
                    ),
                  ),
                );
              }
              return Center(
                child: name.isEmpty
                    ? const Icon(Icons.person, color: AppTheme.primaryBlue)
                    : Text(
                        String.fromCharCode(name.runes.first),
                        style: const TextStyle(
                            color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 19),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _topIcons(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      IconButton(
        tooltip: _sound ? 'خاموش کردن صدا' : 'روشن کردن صدا',
        icon: Icon(_sound ? Icons.volume_up : Icons.volume_off, color: Colors.white),
        onPressed: _toggleSound,
      ),
      IconButton(
        tooltip: 'حالت شب / روز',
        icon: Icon(dark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
        onPressed: () {
          SoundService.play(Sfx.tap);
          context.read<ThemeProvider>().toggleTheme();
        },
      ),
      // آیکون‌های مدیریت فقط برای مدیر (نقش teacher) نمایش داده می‌شوند
      StreamBuilder<bool>(
        stream: _admin,
        initialData: false,
        builder: (context, snapshot) {
          if (snapshot.data != true) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'آمار و دانش‌آموزان',
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                onPressed: () => _push(const AdminDashboardScreen()),
              ),
              IconButton(
                tooltip: 'پنل مدیریت محتوا',
                icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                onPressed: () => _push(const ContentManagerScreen()),
              ),
            ],
          );
        },
      ),
      IconButton(
        tooltip: 'خروج از حساب',
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () => FirebaseAuth.instance.signOut(),
      ),
    ];
  }

  // -------------------------- معرفی نرم‌افزار --------------------------
  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accentOrange, size: 22),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _aboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.info_outline, 'معرفی نرم‌افزار'),
            const SizedBox(height: 12),
            const Text(
              'علوم نهم همراه آموزشی شما برای درس علوم تجربی پایه‌ی نهم است. '
              'در این نرم‌افزار می‌توانید خلاصه‌ی هر فصل، جواب فعالیت‌ها و خودآزمایی‌ها را مطالعه کنید، '
              'با آزمون‌های تصادفی خود را بسنجید، کتاب را بخوانید، در آزمایشگاه مجازی تمرین کنید '
              'و از دستیار هوش مصنوعی سؤال بپرسید.',
              style: TextStyle(height: 1.9, fontSize: 14.5),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                _tile(Icons.school_rounded, 'آموزش', 'خلاصه و فعالیت‌ها', const Color(0xFF1565C0), 0),
                _tile(Icons.menu_book_rounded, 'کتاب', 'مطالعه‌ی کتاب', const Color(0xFF00897B), 1),
                _tile(Icons.quiz_rounded, 'آزمون', 'خودت را بسنج', const Color(0xFF6A1B9A), 3),
                _tile(Icons.science_rounded, 'آزمایشگاه', 'شبیه‌ساز مجازی', const Color(0xFFC62828), 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, Color c, int tab) {
    return Material(
      color: c.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onNavigate(tab),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.accentOrange, Color(0xFFFFA000)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _push(const AiChatScreen()),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.smart_toy_rounded, color: Colors.white, size: 38),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('دستیار هوش مصنوعی',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('هر سؤالی از درس علوم داری بپرس',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------- معرفی سازنده ---------------------------
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _creatorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.person_pin_rounded, 'سازنده‌ی نرم‌افزار'),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 112,
                  height: 142,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.accentOrange, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.asset(
                      _teacherPhoto,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 56, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('لقمان ویسی',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('دبیر علوم تجربی',
                          style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _infoRow(Icons.school_outlined, 'دبیرستان ام‌المومنین روانسر'),
                      _infoRow(Icons.location_on_outlined, 'روانسر، استان کرمانشاه'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.workspace_premium, size: 18, color: AppTheme.accentOrange),
                  label: Text('مدرس تیمز کشوری', style: TextStyle(fontSize: 12.5)),
                ),
                Chip(
                  avatar: Icon(Icons.groups_rounded, size: 18, color: AppTheme.primaryBlue),
                  label: Text('سرگروه آموزشی علوم تجربی روانسر', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
