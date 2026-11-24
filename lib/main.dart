import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'services/audio_player_manager.dart';
import 'theme/qidu_theme.dart';
import 'views/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio playback service & notification for Qidu
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.qidu.app.audio',
    androidNotificationChannelName: 'Qidu Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Set system UI overlay (transparent status bar for edge-to-edge aesthetic)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const QiduApp());
}

class QiduApp extends StatelessWidget {
  const QiduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AudioPlayerManager>(
      create: (_) => AudioPlayerManager(),
      child: MaterialApp(
        title: 'Qidu',
        debugShowCheckedModeBanner: false,
        theme: QiduTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
