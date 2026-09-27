// صفحه آزمایشگاه مجازی: شبیه‌سازهای معتبر علوم (عمدتاً PhET دانشگاه کلرادو)
// با کلیک روی هرکدام، در مرورگر گوشی باز می‌شود
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class _SimItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  const _SimItem(this.title, this.subtitle, this.icon, this.url);
}

class VirtualLabScreen extends StatelessWidget {
  const VirtualLabScreen({super.key});

  static const List<_SimItem> _simulations = [
    _SimItem(
      'ساختار اتم',
      'مدل اتم، پروتون، نوترون و الکترون',
      Icons.blur_circular,
      'https://phet.colorado.edu/en/simulations/build-an-atom',
    ),
    _SimItem(
      'حالت‌های ماده',
      'جامد، مایع و گاز و تغییر حالت',
      Icons.water_drop,
      'https://phet.colorado.edu/en/simulations/states-of-matter-basics',
    ),
    _SimItem(
      'چگالی',
      'رابطه جرم، حجم و چگالی اجسام',
      Icons.scale,
      'https://phet.colorado.edu/en/simulations/density',
    ),
    _SimItem(
      'نیرو و حرکت',
      'نیرو، اصطکاک و حرکت اجسام',
      Icons.speed,
      'https://phet.colorado.edu/en/simulations/forces-and-motion-basics',
    ),
    _SimItem(
      'مدار الکتریکی',
      'ساخت مدار با باتری، لامپ و سیم',
      Icons.electrical_services,
      'https://phet.colorado.edu/en/simulations/circuit-construction-kit-dc',
    ),
    _SimItem(
      'فشار مایعات',
      'فشار آب در عمق‌های مختلف',
      Icons.waves,
      'https://phet.colorado.edu/en/simulations/under-pressure',
    ),
    _SimItem(
      'حرکت و سرعت',
      'نمودار مکان-زمان و سرعت-زمان',
      Icons.directions_run,
      'https://phet.colorado.edu/en/simulations/moving-man',
    ),
    _SimItem(
      'رفتار گازها',
      'فشار، دما و حجم گازها',
      Icons.air,
      'https://phet.colorado.edu/en/simulations/gas-properties',
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('امکان باز کردن این لینک وجود ندارد.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آزمایشگاه مجازی')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'این شبیه‌سازها از سایت معتبر PhET دانشگاه کلرادو هستند و رایگان‌اند. '
              'داخل هر سایت، از منوی «Choose Language» بالای صفحه می‌توانید زبان فارسی را انتخاب کنید.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _simulations.length,
              itemBuilder: (context, index) {
                final sim = _simulations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
                      child: Icon(sim.icon, color: AppTheme.accentOrange),
                    ),
                    title: Text(sim.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(sim.subtitle),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _open(context, sim.url),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
