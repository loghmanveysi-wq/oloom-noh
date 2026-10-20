// جستجوی حریف تصادفی برای رقابت زنده
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/competition_service.dart';
import '../services/sound_service.dart';
import '../widgets/player_avatar.dart';
import 'match_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _me = FirebaseAuth.instance.currentUser?.uid;

  Map<String, String> _info = {'name': 'بازیکن', 'photo': ''};
  Map<String, String>? _opp; // اطلاعات حریف بعد از پیدا شدن
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;
  Timer? _scanTimer;
  Timer? _hbTimer;
  Timer? _clock;
  bool _busy = false;
  bool _opened = false;
  bool _gone = false;
  int _elapsed = 0;
  String? _error;
  List<Map<String, dynamic>>? _questions;

  DocumentReference<Map<String, dynamic>> get _myQueue => _db.collection('matchQueue').doc(_me);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_me == null) {
      setState(() => _error = 'ابتدا وارد حساب خود شوید.');
      return;
    }
    _info = await CompetitionService.myInfo();
    if (_gone) return;
    try {
      try {
        await _myQueue.delete();
      } catch (_) {}
      await _myQueue.set({
        'uid': _me,
        'name': _info['name'],
        'photo': _info['photo'],
        'heartbeat': FieldValue.serverTimestamp(),
        'matchId': null,
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'اتصال به رقابت برقرار نشد. اینترنت و قوانین Firestore را بررسی کنید.');
      return;
    }
    if (_gone) return;
    _queueSub = _myQueue.snapshots().listen((s) {
      final id = s.data()?['matchId'];
      if (id is String && id.isNotEmpty) _open(id);
    });
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (_) => _scan());
    _hbTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _myQueue.update({'heartbeat': FieldValue.serverTimestamp()}).catchError((_) {});
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _opened) return;
      setState(() => _elapsed++);
      if (_elapsed >= 60) _timeout();
    });
    _scan();
  }

  void _stopAll({required bool deleteQueue}) {
    _scanTimer?.cancel();
    _hbTimer?.cancel();
    _clock?.cancel();
    _queueSub?.cancel();
    if (deleteQueue && _me != null) {
      _myQueue.delete().catchError((_) {});
    }
  }

  void _timeout() {
    _stopAll(deleteQueue: true);
    if (mounted) {
      setState(() => _error =
          'الان حریفی آنلاین پیدا نشد. کمی بعد دوباره تلاش کن یا از یکی از هم‌کلاسی‌ها بخواه هم‌زمان وارد رقابت شود.');
    }
  }

  // دنبال حریفی می‌گردد که در صف منتظر است
  Future<void> _scan() async {
    if (_busy || _opened || _gone) return;
    _busy = true;
    try {
      final snap =
          await _db.collection('matchQueue').orderBy('heartbeat', descending: true).limit(10).get();
      final now = DateTime.now();
      for (final d in snap.docs) {
        if (d.id == _me) continue;
        final m = d.data();
        if (m['matchId'] != null) continue;
        final hb = m['heartbeat'];
        if (hb is! Timestamp) continue;
        if (now.difference(hb.toDate()).inSeconds > 45) continue;
        final id = await _claim(d.id, m);
        if (id != null) {
          _open(id);
          return;
        }
      }
    } catch (_) {
      // اسکن بعدی دوباره تلاش می‌کند
    } finally {
      _busy = false;
    }
  }

  // با یک تراکنش، حریف را «رزرو» می‌کند تا فقط یک نفر او را بردارد
  Future<String?> _claim(String candUid, Map<String, dynamic> cand) async {
    _questions ??= await CompetitionService.pickQuestions();
    final questions = _questions!;
    if (questions.isEmpty) {
      if (mounted) setState(() => _error = 'هنوز سؤال کافی در بانک سؤال‌ها ثبت نشده است.');
      _stopAll(deleteQueue: true);
      return null;
    }
    final candRef = _db.collection('matchQueue').doc(candUid);
    final matchRef = _db.collection('matches').doc();
    final players = [candUid, _me!]..shuffle();
    try {
      await _db.runTransaction((tx) async {
        final cs = await tx.get(candRef);
        if (!cs.exists || cs.data()?['matchId'] != null) throw StateError('taken');
        final ms = await tx.get(_myQueue);
        if (ms.exists && ms.data()?['matchId'] != null) throw StateError('mine-taken');
        tx.set(matchRef, {
          'players': players,
          'info': {
            candUid: {'name': cand['name'] ?? 'حریف', 'photo': cand['photo'] ?? ''},
            _me!: {'name': _info['name'], 'photo': _info['photo']},
          },
          'questions': questions,
          'answers': {},
          'cursor': 0,
          'status': 'active',
          'quitter': null,
          'lastMove': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(candRef, {'matchId': matchRef.id});
        if (ms.exists) tx.delete(_myQueue);
      });
      return matchRef.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _open(String id) async {
    if (_opened) return;
    _opened = true;
    _stopAll(deleteQueue: false);
    try {
      final snap = await _db.collection('matches').doc(id).get();
      final data = snap.data();
      final players = List<String>.from(data?['players'] ?? []);
      final oppUid = players.firstWhere((p) => p != _me, orElse: () => '');
      final inf = (data?['info'] as Map?)?[oppUid] as Map?;
      if (mounted) {
        setState(() => _opp = {
              'name': (inf?['name'] ?? 'حریف').toString(),
              'photo': (inf?['photo'] ?? '').toString(),
            });
      }
    } catch (_) {}
    SoundService.play(Sfx.found);
    try {
      await _myQueue.delete();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MatchScreen(matchId: id)));
  }

  @override
  void dispose() {
    _gone = true;
    _stopAll(deleteQueue: !_opened);
    _ac.dispose();
    super.dispose();
  }

  Widget _ring(double t) => Container(
        width: 110 + 230 * t,
        height: 110 + 230 * t,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity((1 - t) * 0.6), width: 2),
        ),
      );

  Widget _searchView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 340,
          height: 340,
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 3; i++) _ring((_ac.value + i / 3) % 1.0),
                PlayerAvatar(name: _info['name'] ?? '', photoUrl: _info['photo'] ?? '', size: 96),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('در جستجوی حریف...',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('لطفاً صبر کنید  •  $_elapsed ثانیه',
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }

  Widget _foundView() {
    final opp = _opp!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('حریف پیدا شد! ⚔️',
            style: TextStyle(color: ArenaColors.gold, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                PlayerAvatar(name: _info['name'] ?? '', photoUrl: _info['photo'] ?? '', size: 90, ring: ArenaColors.cyan),
                const SizedBox(height: 8),
                const Text('شما', style: TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text('VS',
                  style: TextStyle(color: ArenaColors.gold, fontSize: 30, fontWeight: FontWeight.w900)),
            ),
            Column(
              children: [
                PlayerAvatar(name: opp['name'] ?? '', photoUrl: opp['photo'] ?? '', size: 90, ring: ArenaColors.red),
                const SizedBox(height: 8),
                SizedBox(
                  width: 110,
                  child: Text(opp['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('آماده باش...', style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_search_rounded, color: Colors.white54, size: 72),
          const SizedBox(height: 14),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.8)),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
            ),
            child: const Text('تلاش دوباره'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ArenaColors.background,
        width: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _opp != null
                      ? _foundView()
                      : _error != null
                          ? _errorView()
                          : _searchView(),
                ),
              ),
              if (_opp == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B4A)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انصراف'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
