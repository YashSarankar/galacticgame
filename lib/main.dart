import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_game_screen.dart';
import 'services/ad_manager.dart';
import 'services/storage_service.dart';
import 'utils/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Flame asset prefix to empty so it uses root asset paths
  Flame.images.prefix = '';


  // Lock orientation to portrait for optimal mobile gaming experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: GameTheme.backgroundVoid,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Services
  await StorageService.initialize();
  await AdManager().initialize();

  runApp(
    const ProviderScope(
      child: GalacticMergeApp(),
    ),
  );
}

class GalacticMergeApp extends StatelessWidget {
  const GalacticMergeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galactic Merge Idle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: GameTheme.backgroundVoid,
        colorScheme: const ColorScheme.dark(
          primary: GameTheme.neonCyan,
          secondary: GameTheme.neonMagenta,
          surface: GameTheme.cardSurface,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: GameTheme.textPrimary,
              displayColor: GameTheme.textPrimary,
            ),
      ),
      home: const MainGameScreen(),
    );
  }
}
