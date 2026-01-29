import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'providers/mindmap_provider.dart';
import 'providers/review_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo database
  await DatabaseService.initialize();

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
      ],
      child: const DhammaMindApp(),
    ),
  );
}
