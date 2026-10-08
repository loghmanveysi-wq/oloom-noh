import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_core/core.dart';

import 'theme/app_theme.dart';
import 'services/theme_provider.dart';
import 'screens/auth_wrapper.dart';

// کلید لایسنس Community سینک‌فیوژن (اختیاری). هنگام build با
// --dart-define=SYNCFUSION_KEY=... داده می‌شود؛ اگر خالی باشد ثبت نمی‌شود.
const String _syncfusionKey = String.fromEnvironment('SYNCFUSION_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // صفحه‌ی قرمز خطا فقط در حالت توسعه (در نسخه‌ی نهایی به کاربر نشان داده نمی‌شود)
  if (kDebugMode) {
    ErrorWidget.builder = (details) => Material(
          color: Colors.red,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        );
  }

  if (_syncfusionKey.isNotEmpty) {
    SyncfusionLicense.registerLicense(_syncfusionKey);
  }

  await Future.wait([
    Firebase.initializeApp(),
    Hive.initFlutter(),
  ]);
  await Hive.openBox('settingsBox');
  runApp(const OloomNohApp());
}

class OloomNohApp extends StatelessWidget {
  const OloomNohApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'علوم نهم – استاد ویسی',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
