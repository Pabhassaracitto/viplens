// Cập nhật 0027310126
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/app_theme.dart';
import 'screens/home_screen.dart';
import 'providers/settings_provider.dart';

class DhammaMindApp extends StatefulWidget {
  const DhammaMindApp({super.key});

  @override
  State<DhammaMindApp> createState() => _DhammaMindAppState();
}

class _DhammaMindAppState extends State<DhammaMindApp> {
  @override
  void initState() {
    super.initState();
    // Load settings khi app khởi động
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDarkMode = settingsProvider.settings.isDarkMode;

        return MaterialApp(
          title: 'Dhamma Mind',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: HomeScreen(
            onToggleTheme: () => settingsProvider.toggleDarkMode(),
            isDarkMode: isDarkMode,
          ),
        );
      },
    );
  }
}
