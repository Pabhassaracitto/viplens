// Cập nhật 0025310126
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/statistics_service.dart';
import 'providers/mindmap_provider.dart';
import 'providers/review_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/folder_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo services
  await DatabaseService.initialize();
  await NotificationService.initialize();
  await StatisticsService.initialize();

  // Đặt orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Đặt style cho status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MindMapProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
      ],
      child: const DhammaMindApp(),
    ),
  );
}
