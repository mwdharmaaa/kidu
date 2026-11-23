import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'services/audio_player_manager.dart';
import 'theme/apple_music_theme.dart';
import 'views/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio playback service & notification for Kidu
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.kidu.app.audio',
    androidNotificationChannelName: 'Kidu Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Set system UI overlay (transparent status bar for edge-to-edge Apple Music aesthetic)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KiduApp());
}

class KiduApp extends StatelessWidget {
  const KiduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AudioPlayerManager>(
      create: (_) => AudioPlayerManager(),
      child: MaterialApp(
        title: 'Kidu',
        debugShowCheckedModeBanner: false,
        theme: AppleMusicTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
