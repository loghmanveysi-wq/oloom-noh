// قاب اصلی برنامه: نوار پایین با ۵ دکمه؛ «خانه» در وسط (معرفی نرم‌افزار و سازنده)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../widgets/app_background.dart';
import 'learn_screen.dart';
import 'book_list_screen.dart';
import 'intro_screen.dart';
import 'competition_tab_screen.dart';
import 'virtual_lab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _homeIndex = 2;
  int _index = _homeIndex;
  final Set<int> _visited = {_homeIndex};

  void _go(int i) {
    if (i == _index) return;
    SoundService.play(Sfx.nav);
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const LearnScreen();
      case 1:
        return const BookListScreen();
      case 2:
        return IntroScreen(onNavigate: _go);
      case 3:
        return const CompetitionTabScreen();
      default:
        return const VirtualLabScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == _homeIndex,
      onPopInvoked: (didPop) {
        if (!didPop) _go(_homeIndex);
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < 5; i++) _visited.contains(i) ? _page(i) : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: _bottomBar(),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final theme = Theme.of(context);
    final barColor = (theme.cardTheme.color ?? theme.colorScheme.surface).withOpacity(0.96);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 78,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    _item(0, Icons.school_rounded, 'آموزش'),
                    _item(1, Icons.menu_book_rounded, 'کتاب'),
                    _centerItem(),
                    _item(3, Icons.emoji_events_rounded, 'رقابت'),
                    _item(4, Icons.science_rounded, 'آزمایشگاه'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: MediaQuery.of(context).padding.bottom, color: barColor),
      ],
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final sel = _index == i;
    final cs = Theme.of(context).colorScheme;
    final color = sel ? cs.primary : cs.onSurfaceVariant;
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 64,
          child: InkWell(
            onTap: () => _go(i),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? cs.primary.withOpacity(0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _centerItem() {
    final sel = _index == _homeIndex;
    final cs = Theme.of(context).colorScheme;
    final colors = sel
        ? const [AppTheme.accentOrange, Color(0xFFFFA000)]
        : const [AppTheme.primaryBlue, Color(0xFF42A5F5)];
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _go(_homeIndex),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 2),
              Text(
                'خانه',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: sel ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
