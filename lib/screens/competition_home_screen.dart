// صفحه‌ی اصلی بخش رقابت: شروع رقابت، هدف امروز و آمار شما
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/competition_service.dart';
import '../services/sound_service.dart';
import '../widgets/fade_slide.dart';
import '../widgets/player_avatar.dart';
import 'matchmaking_screen.dart';

class CompetitionHomeBody extends StatefulWidget {
  const CompetitionHomeBody({super.key});

  @override
  State<CompetitionHomeBody> createState() => _CompetitionHomeBodyState();
}

class _CompetitionHomeBodyState extends State<CompetitionHomeBody>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const int _dailyGoal = 3;

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream = _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid).snapshots();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

  String _league(int wins) {
    if (wins >= 25) return '💎 لیگ الماس';
    if (wins >= 10) return '🥇 لیگ طلا';
    if (wins >= 3) return '🥈 لیگ نقره';
    return '🥉 لیگ برنز';
  }

  void _start() {
    SoundService.play(Sfx.tap);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: ArenaColors.background,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          final data = snap.data?.data();
          final name = (data?['name'] ?? '').toString().trim();
          final photo = (data?['photoUrl'] ?? '').toString().trim();
          final comp = Map<String, dynamic>.from((data?['comp'] as Map?) ?? {});
          final games = _n(comp['games']);
          final wins = _n(comp['wins']);
          final losses = _n(comp['losses']);
          final rate = games == 0 ? 0 : (wins * 100 / games).round();
          final todayCount = comp['day'] == CompetitionService.today() ? _n(comp['today']) : 0;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                FadeSlide(child: _profileRow(name, photo, wins)),
                const SizedBox(height: 16),
                FadeSlide(delayMs: 80, child: _startCard()),
                const SizedBox(height: 16),
                FadeSlide(delayMs: 140, child: _howCard()),
                const SizedBox(height: 16),
                FadeSlide(delayMs: 200, child: _goalCard(todayCount)),
                const SizedBox(height: 16),
                FadeSlide(delayMs: 260, child: _statsCard(games, wins, losses, rate)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _glass({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }

  Widget _profileRow(String name, String photo, int wins) {
    return Row(
      children: [
        PlayerAvatar(name: name, photoUrl: photo, size: 54, ring: ArenaColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? 'بازیکن' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Text(_league(wins), style: const TextStyle(color: ArenaColors.gold, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: ArenaColors.gold, size: 20),
              const SizedBox(width: 6),
              Text('$wins برد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _startCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF2563EB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5B21B6).withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: ArenaColors.gold, size: 46),
          ),
          const SizedBox(height: 14),
          const Text('آماده‌ی رقابتی؟',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('با یک حریف تصادفی از هم‌کلاسی‌هایت روبه‌رو شو!',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 22),
          ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.05)
                .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: GestureDetector(
              onTap: _start,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00A152)]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                    SizedBox(width: 6),
                    Text('شروع رقابت',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _howRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: ArenaColors.cyan.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: ArenaColors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5))),
        ],
      ),
    );
  }

  Widget _howCard() {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('قانون بازی', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _howRow(Icons.shuffle_rounded, 'یک حریف تصادفی پیدا می‌شود.'),
          _howRow(Icons.repeat_rounded, 'هر بازیکن ۲ نوبت دارد و در هر نوبت ۳ سؤال علوم نهم جواب می‌دهد.'),
          _howRow(Icons.visibility_rounded, 'وقتی حریف جواب می‌دهد، سؤال‌ها و درست/غلط بودن پاسخ‌هایش را زنده می‌بینی.'),
          _howRow(Icons.timer_rounded, 'برای هر سؤال ۲۰ ثانیه وقت داری.'),
        ],
      ),
    );
  }

  Widget _goalCard(int done) {
    return _glass(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('هدف امروز',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$_dailyGoal رقابت انجام بده',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          for (var i = 0; i < _dailyGoal; i++)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? ArenaColors.green : Colors.white12,
              ),
              child: i < done ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _statsCard(int games, int wins, int losses, int rate) {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('عملکرد شما', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _statTile(Icons.sports_esports_rounded, '$games', 'مسابقه', ArenaColors.cyan),
              const SizedBox(width: 8),
              _statTile(Icons.emoji_events_rounded, '$wins', 'پیروزی', ArenaColors.green),
              const SizedBox(width: 8),
              _statTile(Icons.heart_broken_rounded, '$losses', 'شکست', ArenaColors.red),
              const SizedBox(width: 8),
              _statTile(Icons.percent_rounded, '$rate٪', 'نرخ برد', ArenaColors.gold),
            ],
          ),
        ],
      ),
    );
  }
}
