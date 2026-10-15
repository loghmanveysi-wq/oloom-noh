// تب‌بار باکسی و خوانا برای نوار بالای صفحه‌ها (داخل AppBar.bottom)
// تب انتخاب‌شده سفید است و بقیه نیمه‌شفاف با کادر سفید؛ همه‌ی نوشته‌ها روی زمینه‌ی آبی واضح دیده می‌شوند.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class BoxedTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> labels;
  final List<IconData> icons;
  final TabController? controller; // اگر خالی باشد از DefaultTabController استفاده می‌شود

  const BoxedTabBar({
    super.key,
    required this.labels,
    required this.icons,
    this.controller,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final tc = controller ?? DefaultTabController.of(context);
    return SizedBox(
      height: 56,
      child: AnimatedBuilder(
        animation: tc.animation!,
        builder: (context, _) {
          final sel = tc.animation!.value.round();
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            children: [
              for (var i = 0; i < labels.length; i++) _box(tc, i, sel == i),
            ],
          );
        },
      ),
    );
  }

  Widget _box(TabController tc, int i, bool selected) {
    final fg = selected ? AppTheme.primaryBlue : Colors.white;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () {
          SoundService.play(Sfx.tap);
          tc.animateTo(i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? Colors.white : Colors.white54, width: 1.2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icons[i], size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                labels[i],
                style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
