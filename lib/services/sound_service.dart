// افکت‌های صوتی برنامه. صداها در لحظه ساخته می‌شوند (به فایل صوتی جداگانه نیاز نیست).
// کاربر می‌تواند صدا را از صفحه‌ی «خانه» خاموش کند.
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

enum Sfx { tap, nav, correct, wrong, success, found, lose }

class _Note {
  final double freq;
  final int ms;
  const _Note(this.freq, this.ms);
}

class SoundService {
  static const int _rate = 22050;
  static final Map<Sfx, Uint8List> _cache = {};
  static AudioPlayer? _player;

  static bool get enabled =>
      Hive.box('settingsBox').get('soundOn', defaultValue: true) == true;

  static Future<void> setEnabled(bool value) =>
      Hive.box('settingsBox').put('soundOn', value);

  static Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    try {
      if (sfx == Sfx.tap || sfx == Sfx.nav) HapticFeedback.selectionClick();
      final player = _player ??= AudioPlayer();
      final bytes = _cache.putIfAbsent(sfx, () => _build(sfx));
      await player.stop();
      await player.play(BytesSource(bytes), volume: 0.7);
    } catch (_) {
      // اگر صدا پخش نشد، برنامه بدون مشکل ادامه می‌دهد
    }
  }

  static Uint8List _build(Sfx sfx) {
    switch (sfx) {
      case Sfx.tap:
        return _wav(const [_Note(1100, 45)], 0.35);
      case Sfx.nav:
        return _wav(const [_Note(660, 35), _Note(880, 55)], 0.3);
      case Sfx.correct:
        return _wav(const [_Note(784, 110), _Note(1175, 230)], 0.45);
      case Sfx.wrong:
        return _wav(const [_Note(311, 140), _Note(233, 270)], 0.45);
      case Sfx.found:
        return _wav(const [_Note(523, 90), _Note(784, 90), _Note(1047, 260)], 0.45);
      case Sfx.lose:
        return _wav(const [_Note(392, 150), _Note(330, 150), _Note(262, 320)], 0.45);
      case Sfx.success:
        return _wav(
          const [_Note(523, 110), _Note(659, 110), _Note(784, 110), _Note(1047, 400)],
          0.45,
        );
    }
  }

  static Uint8List _wav(List<_Note> notes, double volume) {
    final samples = <int>[];
    for (final n in notes) {
      final count = _rate * n.ms ~/ 1000;
      for (var i = 0; i < count; i++) {
        final t = i / _rate;
        final attack = min(1.0, i / (_rate * 0.004));
        final decay = pow(1 - i / count, 1.6).toDouble();
        final v = sin(2 * pi * n.freq * t) * 0.8 + sin(4 * pi * n.freq * t) * 0.2;
        samples.add((v * attack * decay * volume * 32767).round().clamp(-32768, 32767).toInt());
      }
    }
    final data = ByteData(44 + samples.length * 2);
    void str(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + samples.length * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, samples.length * 2, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      data.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
