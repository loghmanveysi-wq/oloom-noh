// صفحه‌ی بازی رقابتی: ۴ نوبت یکی‌درمیان (هر بازیکن ۲ نوبت)، هر نوبت ۳ سؤال.
// وقتی حریف پاسخ می‌دهد، شما سؤال‌ها و درست/غلط بودن پاسخ‌هایش را زنده می‌بینید.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/competition_service.dart';
import '../services/sound_service.dart';
import '../widgets/player_avatar.dart';
import 'matchmaking_screen.dart';

class MatchScreen extends StatefulWidget {
  final String matchId;

  const MatchScreen({super.key, required this.matchId});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  static const int _questionSeconds = 20;
  static const List<String> _letters = ['الف', 'ب', 'ج', 'د'];

  late final DocumentReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('matches').doc(widget.matchId);
  final String? _me = FirebaseAuth.instance.currentUser?.uid;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _tick;
  Timer? _clock;
  Map<String, dynamic>? _m;
  final Set<String> _heard = {};
  int _secondsLeft = _questionSeconds;
  int _timerFor = -1;
  bool _submitting = false;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _sub = _ref.snapshots().listen(_onSnap, onError: (_) {});
    _clock = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  // ---------------------------- وضعیت بازی ----------------------------
  List<String> get _players => List<String>.from(_m?['players'] ?? const []);
  int get _cursor => (_m?['cursor'] as num?)?.toInt() ?? 0;
  String get _status => (_m?['status'] ?? 'active').toString();
  List get _questions => (_m?['questions'] as List?) ?? const [];
  Map<String, dynamic> get _answers => Map<String, dynamic>.from((_m?['answers'] as Map?) ?? {});
  String get _oppUid => _players.firstWhere((p) => p != _me, orElse: () => '');

  String _turnUid(int index) {
    final p = _players;
    return p.length == 2 ? p[(index ~/ CompetitionService.perRound) % 2] : '';
  }

  bool get _myTurn =>
      _status == 'active' && _cursor < CompetitionService.total && _turnUid(_cursor) == _me;

  Map<String, dynamic>? _answer(int i) {
    final a = _answers['q$i'];
    return a == null ? null : Map<String, dynamic>.from(a as Map);
  }

  int _score(String uid) {
    var n = 0;
    for (final v in _answers.values) {
      final a = Map<String, dynamic>.from(v as Map);
      if (a['uid'] == uid && a['ok'] == true) n++;
    }
    return n;
  }

  Map<String, String> _info(String uid) {
    final raw = (_m?['info'] as Map?)?[uid] as Map?;
    return {
      'name': (raw?['name'] ?? 'بازیکن').toString(),
      'photo': (raw?['photo'] ?? '').toString(),
    };
  }

  String _result() {
    if (_status == 'abandoned') return _m?['quitter'] == _me ? 'loss' : 'win';
    final my = _score(_me ?? '');
    final opp = _score(_oppUid);
    return my > opp ? 'win' : (my < opp ? 'loss' : 'draw');
  }

  bool get _opponentStalled {
    if (_status != 'active' || _myTurn) return false;
    final lm = _m?['lastMove'];
    if (lm is! Timestamp) return false;
    return DateTime.now().difference(lm.toDate()).inSeconds > 75;
  }

  // ------------------------------ رویدادها ------------------------------
  void _onSnap(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data();
    if (data == null || !mounted) return;
    final ans = Map<String, dynamic>.from((data['answers'] as Map?) ?? {});
    ans.forEach((k, v) {
      if (_heard.add(k)) {
        final a = Map<String, dynamic>.from(v as Map);
        if (a['uid'] != _me) SoundService.play(a['ok'] == true ? Sfx.correct : Sfx.wrong);
      }
    });
    setState(() => _m = data);
    _syncTimer();
    _finishIfNeeded();
  }

  void _syncTimer() {
    if (_status != 'active') {
      _tick?.cancel();
      return;
    }
    if (_myTurn && _timerFor != _cursor && _answer(_cursor) == null) {
      _timerFor = _cursor;
      _secondsLeft = _questionSeconds;
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) {
          t.cancel();
          _submit(-1);
        }
      });
    }
  }

  void _finishIfNeeded() {
    if (_status == 'active' || _recorded) return;
    _recorded = true;
    _tick?.cancel();
    final r = _result();
    CompetitionService.recordResult(r).catchError((_) {});
    SoundService.play(r == 'win' ? Sfx.success : (r == 'loss' ? Sfx.lose : Sfx.nav));
  }

  Future<void> _submit(int sel) async {
    final idx = _cursor;
    if (!_myTurn || _answer(idx) != null || _submitting) return;
    _submitting = true;
    _tick?.cancel();
    final q = Map<String, dynamic>.from(_questions[idx] as Map);
    final ok = sel == (q['ans'] as num).toInt();
    SoundService.play(ok ? Sfx.correct : Sfx.wrong);
    try {
      await _ref.update({
        'answers.q$idx': {'uid': _me, 'sel': sel, 'ok': ok},
        'lastMove': FieldValue.serverTimestamp(),
      });
      // کمی مکث تا پاسخ درست/غلط دیده شود، بعد سؤال بعدی
      await Future.delayed(const Duration(milliseconds: 1400));
      final last = idx == CompetitionService.total - 1;
      await _ref.update({
        'cursor': idx + 1,
        if (last) 'status': 'finished',
        'lastMove': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ارسال پاسخ انجام نشد. اینترنت را بررسی کنید.')));
      }
    } finally {
      _submitting = false;
    }
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروج از رقابت'),
        content: const Text('اگر خارج شوی، این بازی را باخته‌ای. مطمئنی؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ادامه‌ی بازی')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _recorded = true;
    _tick?.cancel();
    try {
      await _ref.update({
        'status': 'abandoned',
        'quitter': _me,
        'lastMove': FieldValue.serverTimestamp(),
      });
      await CompetitionService.recordResult('loss');
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  Future<void> _claimWin() async {
    try {
      await _ref.update({
        'status': 'abandoned',
        'quitter': _oppUid,
        'lastMove': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ------------------------------- نمایش -------------------------------
  @override
  Widget build(BuildContext context) {
    final playing = _m != null && _status == 'active';
    return PopScope(
      canPop: !playing,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: ArenaColors.top,
        appBar: AppBar(
          backgroundColor: ArenaColors.top,
          title: const Text('رقابت'),
        ),
        body: Container(
          decoration: ArenaColors.background,
          child: _m == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : (playing ? _playView() : _resultView()),
        ),
      ),
    );
  }

  Widget _playView() {
    final idx = _cursor >= CompetitionService.total ? CompetitionService.total - 1 : _cursor;
    final q = Map<String, dynamic>.from(_questions[idx] as Map);
    final turn = _turnUid(idx);
    final answered = _answer(idx);
    return SafeArea(
      child: Column(
        children: [
          _scoreBar(turn),
          _roundHeader(idx, turn),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _turnBanner(turn, answered),
                  const SizedBox(height: 12),
                  _questionCard(q, idx, answered),
                ],
              ),
            ),
          ),
          if (_opponentStalled) _stallBar(),
          _roundsSummary(),
        ],
      ),
    );
  }

  Widget _scoreBar(String turn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _playerChip(_me ?? '', turn == _me),
          const Text('VS',
              style: TextStyle(color: ArenaColors.gold, fontSize: 24, fontWeight: FontWeight.w900)),
          _playerChip(_oppUid, turn == _oppUid),
        ],
      ),
    );
  }

  Widget _playerChip(String uid, bool isTurn) {
    final inf = _info(uid);
    return Column(
      children: [
        PlayerAvatar(
          name: inf['name']!,
          photoUrl: inf['photo']!,
          size: 54,
          ring: isTurn ? ArenaColors.gold : Colors.white24,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 110,
          child: Text(
            uid == _me ? 'شما' : inf['name']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Text('${_score(uid)}',
            style: const TextStyle(color: ArenaColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _roundHeader(int idx, String turn) {
    final per = CompetitionService.perRound;
    final r = idx ~/ per;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          Text('نوبت ${r + 1} از ${CompetitionService.rounds}  •  سؤال ${idx % per + 1} از $per',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (var k = 0; k < per; k++) _dot(r * per + k, idx, 26)],
          ),
        ],
      ),
    );
  }

  // دایره‌ی وضعیت هر سؤال: خاکستری (در انتظار)، سبز (درست)، قرمز (غلط)
  Widget _dot(int gi, int current, double size) {
    final a = _answer(gi);
    Color bg = Colors.white12;
    Widget? icon;
    if (a != null) {
      final ok = a['ok'] == true;
      bg = ok ? ArenaColors.green : ArenaColors.red;
      icon = Icon(ok ? Icons.check : Icons.close, color: Colors.white, size: size * 0.62);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: gi == current && a == null ? ArenaColors.cyan : Colors.transparent,
          width: 2,
        ),
      ),
      child: icon,
    );
  }

  Widget _turnBanner(String turn, Map<String, dynamic>? answered) {
    final mine = turn == _me;
    final oppName = _info(_oppUid)['name']!;
    String text;
    Color color;
    if (answered != null) {
      final ok = answered['ok'] == true;
      color = ok ? ArenaColors.green : ArenaColors.red;
      text = mine
          ? (ok ? 'آفرین! پاسخ درست بود ✅' : 'پاسخ غلط بود ❌')
          : (ok ? '$oppName درست جواب داد ✅' : '$oppName غلط جواب داد ❌');
    } else if (mine) {
      color = ArenaColors.cyan;
      text = 'نوبت شماست! سریع جواب بده';
    } else {
      color = Colors.white54;
      text = '$oppName در حال پاسخ دادن است...';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: TextStyle(color: color == Colors.white54 ? Colors.white70 : color,
                    fontWeight: FontWeight.bold, fontSize: 14.5)),
          ),
          if (mine && answered == null)
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _secondsLeft / _questionSeconds,
                    strokeWidth: 4,
                    color: _secondsLeft <= 5 ? ArenaColors.red : ArenaColors.cyan,
                    backgroundColor: Colors.white12,
                  ),
                  Text('$_secondsLeft', style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          if (!mine && answered == null)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _questionCard(Map<String, dynamic> q, int idx, Map<String, dynamic>? answered) {
    final opts = List<String>.from(q['opts'] ?? const []);
    final img = (q['img'] ?? '').toString();
    final text = (q['q'] ?? '').toString();
    final interactive = _myTurn && answered == null && !_submitting;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (text.isNotEmpty)
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.7)),
          if (img.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: img,
                fit: BoxFit.contain,
                memCacheWidth: 800,
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (var i = 0; i < opts.length; i++) _option(i, opts[i], q, answered, interactive),
        ],
      ),
    );
  }

  Widget _option(int i, String text, Map<String, dynamic> q, Map<String, dynamic>? answered, bool interactive) {
    final correct = (q['ans'] as num).toInt();
    Color bg = Colors.white.withOpacity(0.08);
    Color border = Colors.white24;
    IconData? icon;
    if (answered != null) {
      final sel = (answered['sel'] as num).toInt();
      if (i == correct) {
        bg = ArenaColors.green.withOpacity(0.22);
        border = ArenaColors.green;
        icon = Icons.check_circle;
      } else if (i == sel) {
        bg = ArenaColors.red.withOpacity(0.22);
        border = ArenaColors.red;
        icon = Icons.cancel;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: interactive ? () => _submit(i) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white12,
                child: Text(_letters[i < 4 ? i : 3],
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
              ),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stallBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('حریف مدتی است پاسخ نمی‌دهد.', style: TextStyle(color: Colors.white)),
          ),
          TextButton(onPressed: _claimWin, child: const Text('پایان بازی و ثبت برد')),
        ],
      ),
    );
  }

  // خلاصه‌ی ۴ نوبت (پایین صفحه)
  Widget _roundsSummary() {
    final per = CompetitionService.perRound;
    final cur = _cursor >= CompetitionService.total ? CompetitionService.total - 1 : _cursor;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0x33000000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var r = 0; r < CompetitionService.rounds; r++)
            Column(
              children: [
                Text(
                  _players.length == 2 && _players[r % 2] == _me ? 'شما' : 'حریف',
                  style: TextStyle(
                    color: _status == 'active' && cur ~/ per == r ? ArenaColors.gold : Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [for (var k = 0; k < per; k++) _dot(r * per + k, cur, 14)]),
              ],
            ),
        ],
      ),
    );
  }

  // ------------------------------ نتیجه ------------------------------
  Widget _resultView() {
    final r = _result();
    final abandoned = _status == 'abandoned';
    String title;
    IconData icon;
    Color color;
    if (r == 'win') {
      title = abandoned ? 'حریف از بازی خارج شد؛ برنده شدی! 🎉' : 'تبریک! برنده شدی 🎉';
      icon = Icons.emoji_events_rounded;
      color = ArenaColors.gold;
    } else if (r == 'loss') {
      title = abandoned ? 'از بازی خارج شدی و باختی' : 'این بار باختی؛ دفعه‌ی بعد!';
      icon = Icons.sentiment_dissatisfied_rounded;
      color = ArenaColors.red;
    } else {
      title = 'مساوی شد!';
      icon = Icons.sentiment_neutral_rounded;
      color = ArenaColors.cyan;
    }
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Icon(icon, color: color, size: 84),
                  const SizedBox(height: 10),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_playerChip(_me ?? '', false), _playerChip(_oppUid, false)],
                  ),
                  const SizedBox(height: 18),
                  const Text('امتیاز: تعداد پاسخ‌های درست از ۶ سؤال هر نفر',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
          _roundsSummary(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                    ),
                    child: const Text('رقابت دوباره'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('بازگشت'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
