// مدیریت حالت شب/روز برنامه با ذخیره در Hive
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  final Box _box = Hive.box('settingsBox');
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    final saved = _box.get('themeMode', defaultValue: 'light');
    _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _box.put('themeMode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
