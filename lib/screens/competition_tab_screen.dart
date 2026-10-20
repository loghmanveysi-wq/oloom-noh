// تب «رقابت» در نوار پایین: رقابت زنده + آزمون فصل‌ها
import 'package:flutter/material.dart';
import '../widgets/boxed_tab_bar.dart';
import 'competition_home_screen.dart';
import 'exam_list_screen.dart';

class CompetitionTabScreen extends StatelessWidget {
  const CompetitionTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رقابت'),
          bottom: const BoxedTabBar(
            labels: ['رقابت زنده', 'آزمون فصل‌ها'],
            icons: [Icons.sports_esports_rounded, Icons.quiz_rounded],
          ),
        ),
        body: const TabBarView(
          children: [
            CompetitionHomeBody(),
            ExamListBody(),
          ],
        ),
      ),
    );
  }
}
