// صفحه آزمایشگاه مجازی: لیست شبیه‌سازهای تعاملی علوم نهم
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VirtualLabScreen extends StatelessWidget {
  const VirtualLabScreen({super.key});

  static const List<Map<String, dynamic>> _experiments = [
    {'title': 'شبیه‌ساز مدار الکتریکی', 'icon': Icons.electrical_services},
    {'title': 'شبیه‌ساز فشار مایعات', 'icon': Icons.water_drop},
    {'title': 'شبیه‌ساز چگالی', 'icon': Icons.science},
    {'title': 'شبیه‌ساز حرکت و سرعت', 'icon': Icons.speed},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آزمایشگاه مجازی')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1,
        ),
        itemCount: _experiments.length,
        itemBuilder: (context, i) {
          final exp = _experiments[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('این شبیه‌ساز در مرحله بعد پیاده‌سازی می‌شود')),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(exp['icon'], size: 44, color: AppTheme.primaryBlue),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(exp['title'], textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
