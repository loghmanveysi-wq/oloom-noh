// انیمیشن ورود نرم: محو شدن + حرکت کوتاه به بالا
import 'package:flutter/material.dart';

class FadeSlide extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const FadeSlide({super.key, required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}
