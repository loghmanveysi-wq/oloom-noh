// ابزارهای ظاهری برنامه: پس‌زمینه‌ی متحرک علمی، اپ‌بار گرادیانی و عنوان درخشان
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// پس‌زمینه‌ی متحرک: گرادیان نرم + نورهای شناور + حباب‌های بالا‌رونده + اتم‌های چرخان.
/// هر صفحه‌ای را که روی آن قرار بگیرد (با Scaffold شفاف) زنده می‌کند.
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _BackgroundPainter(_c, dark), size: Size.infinite),
        ),
        widget.child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Animation<double> t;
  final bool dark;

  _BackgroundPainter(this.t, this.dark) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? const [Color(0xFF0A1020), Color(0xFF111B33), Color(0xFF0E2A3A)]
              : const [Color(0xFFE6F0FF), Color(0xFFF3EEFF), Color(0xFFFFF1E2)],
        ).createShader(rect),
    );

    final a = t.value * 2 * math.pi;

    void orb(double fx, double fy, double r, Color c, double phase) {
      final center = Offset(
        size.width * (fx + 0.06 * math.sin(a + phase)),
        size.height * (fy + 0.05 * math.cos(a + phase)),
      );
      final radius = r * size.shortestSide;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [c, c.withOpacity(0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    orb(0.12, 0.10, 0.65, AppTheme.primaryBlue.withOpacity(dark ? 0.30 : 0.20), 0);
    orb(0.95, 0.45, 0.55, AppTheme.accentOrange.withOpacity(dark ? 0.16 : 0.16), 2);
    orb(0.15, 0.92, 0.65, const Color(0xFF00BFA5).withOpacity(dark ? 0.20 : 0.15), 4);

    // حباب‌های بالا‌رونده (سرعت‌ها عدد صحیح‌اند تا حلقه‌ی انیمیشن بی‌درز باشد)
    final bubble = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = (dark ? Colors.white : AppTheme.primaryBlue).withOpacity(dark ? 0.16 : 0.18);
    for (var i = 0; i < 10; i++) {
      final speed = (i % 3) + 1;
      final y = size.height * (1 - ((t.value * speed + i * 0.11) % 1.0));
      final x = size.width * (((i * 0.173 + 0.09) % 1.0) + 0.02 * math.sin(a * 3 + i));
      canvas.drawCircle(Offset(x, y), 4.0 + (i % 5) * 3.0, bubble);
    }

    // اتم‌های چرخان
    _atom(canvas, Offset(size.width * 0.84, size.height * 0.16), 34, a);
    _atom(canvas, Offset(size.width * 0.14, size.height * 0.60), 26, -a);
    _atom(canvas, Offset(size.width * 0.78, size.height * 0.84), 30, a * 2);
  }

  void _atom(Canvas canvas, Offset c, double r, double angle) {
    final col = (dark ? Colors.white : AppTheme.primaryBlue).withOpacity(dark ? 0.14 : 0.14);
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = col;
    final fill = Paint()..color = col.withOpacity(dark ? 0.30 : 0.30);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawCircle(Offset.zero, r * 0.16, fill);
    for (var k = 0; k < 3; k++) {
      canvas.save();
      canvas.rotate(angle + k * math.pi / 3);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.8), orbit);
      canvas.drawCircle(Offset(r, 0), r * 0.1, fill);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.dark != dark;
}

/// اپ‌بار گرادیانی با گوشه‌های گرد؛ جایگزین مستقیم AppBar
class GAppBar extends AppBar {
  GAppBar({
    super.key,
    super.leading,
    super.automaticallyImplyLeading,
    super.title,
    super.actions,
    super.bottom,
  }) : super(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black45,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          flexibleSpace: const _GradientBar(),
        );
}

class _GradientBar extends StatelessWidget {
  const _GradientBar();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? const [Color(0xFF16232E), Color(0xFF1B3A5C)]
              : const [AppTheme.primaryBlue, Color(0xFF2F8DE0), Color(0xFF42A5F5)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
    );
  }
}

/// متن با درخشش متحرک (برای عنوان‌های مهم)
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const ShimmerText(this.text, {super.key, required this.style});

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Colors.white, Color(0xFFFFE082), Colors.white],
            stops: [
              (v - 0.25).clamp(0.0, 1.0),
              v.clamp(0.0, 1.0),
              (v + 0.25).clamp(0.0, 1.0),
            ],
          ).createShader(rect),
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}
