// آواتار بازیکن (عکس شخصی یا حرف اول نام) و رنگ‌های صفحه‌های رقابت
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArenaColors {
  static const Color top = Color(0xFF0A1128);
  static const Color bottom = Color(0xFF1B1F6E);
  static const Color gold = Color(0xFFFFC107);
  static const Color green = Color(0xFF00C853);
  static const Color red = Color(0xFFFF5252);
  static const Color cyan = Color(0xFF29B6F6);

  static const BoxDecoration background = BoxDecoration(
    gradient: LinearGradient(
      colors: [top, bottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

class PlayerAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double size;
  final Color ring;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.size = 56,
    this.ring = Colors.white,
  });

  Widget _initial() => Center(
        child: name.trim().isEmpty
            ? Icon(Icons.person, color: Colors.white, size: size * 0.55)
            : Text(
                String.fromCharCode(name.trim().runes.first),
                style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.bold),
              ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF7E57C2)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: photoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              memCacheWidth: 200,
              placeholder: (_, __) => _initial(),
              errorWidget: (_, __, ___) => _initial(),
            )
          : _initial(),
    );
  }
}
