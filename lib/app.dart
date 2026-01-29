import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'themes/app_theme.dart';

class DhammaMindApp extends StatefulWidget {
  const DhammaMindApp({super.key});

  @override
  State<DhammaMindApp> createState() => _DhammaMindAppState();
}

class _DhammaMindAppState extends State<DhammaMindApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isDarkMode = DatabaseService.isDarkMode;
    });
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      DatabaseService.setDarkMode(_isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhamma Mind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onToggleTheme: toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}
