// رتبه‌بندی کلی رقابت: جایگاه شما، سکوی ۳ نفر اول و فهرست بازیکنان
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/fade_slide.dart';
import '../widgets/player_avatar.dart';

class LeaderboardBody extends StatefulWidget {
  const LeaderboardBody({super.key});

  @override
  State<LeaderboardBody> createState() => _LeaderboardBodyState();
}

class _LeaderboardBodyState extends State<LeaderboardBody> with AutomaticKeepAliveClientMixin {
  static const List<Color> _medal = [Color(0xFFFFC107), Color(0xFFB0BEC5), Color(0xFFCD7F32)];

  final String? _me = FirebaseAuth.instance.currentUser?.uid;
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('leaderboard');
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _top =
      _col.orderBy('points', descending: true).limit(50).snapshots();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _mine =
      _me == null ? null : _col.doc(_me).snapshots();

  int? _rankPoints;
  Future<int>? _rankFuture;

  @override
  bool get wantKeepAlive => true;

  int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

  // جایگاه کسی که در ۵۰ نفر اول نیست: تعداد کسانی که امتیاز بیشتر دارند + ۱
  Future<int> _rankOf(int points) {
    if (_rankPoints != points || _rankFuture == null) {
      _rankPoints = points;
      _rankFuture = _col
          .where('points', isGreaterThan: points)
          .count()
          .get()
          .then((r) => (r.count ?? 0) + 1);
    }
    return _rankFuture!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: ArenaColors.background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _top,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('بارگذاری رتبه‌بندی انجام نشد. اینترنت و قوانین Firestore را بررسی کنید.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final entries = [
            for (final d in snap.data!.docs) <String, dynamic>{...d.data(), 'uid': d.id},
          ];
          final myIdx = entries.indexWhere((e) => e['uid'] == _me);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              FadeSlide(child: _myCard(entries, myIdx)),
              const SizedBox(height: 18),
              if (entries.isEmpty)
                FadeSlide(delayMs: 80, child: _emptyCard())
              else
                FadeSlide(delayMs: 80, child: _podium(entries)),
              const SizedBox(height: 14),
              for (var i = 3; i < entries.length; i++) _row(i + 1, entries[i]),
              const SizedBox(height: 10),
              const Text(
                'امتیاز هر رقابت: برد ۲۰  •  مساوی ۱۰  •  باخت ۰',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------- جایگاه شما ----------------------------
  Widget _myCard(List<Map<String, dynamic>> entries, int myIdx) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _mine,
      builder: (context, snap) {
        final me = snap.data?.data();
        Widget rankText(String text) => Text(
              text,
              style: const TextStyle(color: ArenaColors.gold, fontSize: 34, fontWeight: FontWeight.w900),
            );
        Widget rankWidget;
        if (me == null) {
          rankWidget = const Text('—',
              style: TextStyle(color: Colors.white54, fontSize: 30, fontWeight: FontWeight.bold));
        } else if (myIdx >= 0) {
          rankWidget = rankText('#${myIdx + 1}');
        } else {
          rankWidget = FutureBuilder<int>(
            future: _rankOf(_n(me['points'])),
            builder: (context, r) => rankText(r.hasData ? '#${r.data}' : '...'),
          );
        }
        final name = (me?['name'] ?? '').toString();
        final photo = (me?['photo'] ?? '').toString();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF2563EB)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B21B6).withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              PlayerAvatar(name: name, photoUrl: photo, size: 58, ring: ArenaColors.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('جایگاه شما',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    rankWidget,
                    if (me == null)
                      const Text('هنوز رقابتی نداده‌ای؛ اولین رقابتت را شروع کن!',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              if (me != null)
                Column(
                  children: [
                    Text('${_n(me['points'])}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('امتیاز', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${_n(me['wins'])} برد از ${_n(me['games'])} بازی',
                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, color: ArenaColors.gold, size: 54),
          SizedBox(height: 10),
          Text('جدول رتبه‌بندی هنوز خالی است',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('اولین رقابت را انجام بده تا اولین نفر جدول باشی!',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  // ------------------------------ سکو ------------------------------
  Widget _podium(List<Map<String, dynamic>> entries) {
    Map<String, dynamic>? at(int i) => i < entries.length ? entries[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _slot(at(1), 2, 90),
        _slot(at(0), 1, 124),
        _slot(at(2), 3, 70),
      ],
    );
  }

  Widget _slot(Map<String, dynamic>? e, int place, double height) {
    final c = _medal[place - 1];
    final mine = e != null && e['uid'] == _me;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (e != null) ...[
            if (place == 1) const Text('👑', style: TextStyle(fontSize: 24)),
            PlayerAvatar(
              name: (e['name'] ?? '').toString(),
              photoUrl: (e['photo'] ?? '').toString(),
              size: place == 1 ? 74 : 58,
              ring: c,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 96,
              child: Text(
                mine ? 'شما' : (e['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
            Text('${_n(e['points'])}',
                style: TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.bold)),
          ] else
            const SizedBox(height: 60),
          const SizedBox(height: 4),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                colors: [c.withOpacity(0.85), c.withOpacity(0.25)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text('$place',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ------------------------- ردیف نفر ۴ به بعد -------------------------
  Widget _row(int rank, Map<String, dynamic> e) {
    final mine = e['uid'] == _me;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? ArenaColors.cyan.withOpacity(0.18) : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mine ? ArenaColors.cyan : Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: Text('$rank',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          PlayerAvatar(
            name: (e['name'] ?? '').toString(),
            photoUrl: (e['photo'] ?? '').toString(),
            size: 42,
            ring: Colors.white24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mine ? 'شما' : (e['name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('${_n(e['wins'])} برد از ${_n(e['games'])} بازی',
                    style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${_n(e['points'])}',
                  style: const TextStyle(
                      color: ArenaColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('امتیاز', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}
