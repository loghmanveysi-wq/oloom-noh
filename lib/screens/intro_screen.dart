// صفحه «خانه» (دکمه‌ی وسط): معرفی نرم‌افزار و معرفی سازنده؛ همه‌چیز در یک صفحه و بدون اسکرول
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

  Widget _section(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), child: child);

  // همه‌ی بخش‌ها در یک صفحه جا می‌شوند: اگر صفحه بلند باشد فاصله‌ها بیشتر می‌شود،
  // و اگر کوتاه باشد (گوشی کوچک) کل صفحه کمی کوچک‌تر نمایش داده می‌شود؛ هرگز اسکرول ندارد.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, c) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: c.maxWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hero(context),
                    _section(FadeSlide(child: _aboutCard())),
                    _section(FadeSlide(delayMs: 100, child: _aiBanner())),
                    _section(FadeSlide(delayMs: 180, child: _creatorCard())),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        },
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(top: -40, left: -30, child: _bubble(130, 0.10)),
          Positioned(bottom: -50, right: -20, child: _bubble(150, 0.08)),
          Padding(
            padding: EdgeInsets.fromLTRB(8, top + 4, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [_profileButton(), const Spacer(), ..._topIcons(context)]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.science, size: 30, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'علوم نهم',
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'همراه شما برای یادگیری علوم تجربی',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.accentOrange, size: 20),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _aboutCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.info_outline, 'معرفی نرم‌افزار'),
            const SizedBox(height: 8),
            const Text(
              'علوم نهم همراه آموزشی شما برای درس علوم تجربی پایه‌ی نهم است: '
              'خلاصه‌ی فصل‌ها، جواب فعالیت‌ها و خودآزمایی‌ها، آزمون تصادفی، کتاب، '
              'آزمایشگاه مجازی و دستیار هوش مصنوعی. از دکمه‌های پایین صفحه به هر بخش بروید.',
              style: TextStyle(height: 1.7, fontSize: 13.5),
            ),
          ],
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
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _push(const AiChatScreen()),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.smart_toy_rounded, color: Colors.white, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('دستیار هوش مصنوعی',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('هر سؤالی از درس علوم داری بپرس',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4))),
        ],
      ),
    );
  }

  Widget _creatorCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.person_pin_rounded, 'سازنده‌ی نرم‌افزار'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84,
                  height: 106,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.accentOrange, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      _teacherPhoto,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 44, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('لقمان ویسی',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const Text('دبیر علوم تجربی',
                          style: TextStyle(
                              color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      _infoRow(Icons.school_outlined, 'دبیرستان ام‌المومنین روانسر'),
                      _infoRow(Icons.location_on_outlined, 'روانسر، استان کرمانشاه'),
                      _infoRow(Icons.workspace_premium_outlined, 'مدرس تیمز کشوری'),
                      _infoRow(Icons.groups_rounded, 'سرگروه آموزشی علوم تجربی روانسر'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
