import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/apple_music_theme.dart';
import '../equalizer/equalizer_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();
    final currentSong = manager.currentSong;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(
          child: Text("No song playing"),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = screenWidth * 0.78;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Dynamic Mesh Gradient Background (Apple Music signature ambient blur)
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.4),
                radius: 1.4,
                colors: [
                  manager.dominantColor.withOpacity(0.85),
                  manager.secondaryColor.withOpacity(0.9),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Backdrop Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.chevron_compact_down,
                          color: AppleMusicTheme.textSecondary,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        "Now Playing",
                        style: TextStyle(
                          color: AppleMusicTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // Equalizer Button
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.slider_horizontal_3,
                          color: AppleMusicTheme.accentRed,
                          size: 26,
                        ),
                        tooltip: "Equalizer",
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EqualizerScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Album Artwork with Apple-style rounded rect and drop shadow
                  Container(
                    width: artworkSize,
                    height: artworkSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 35,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: QueryArtworkWidget(
                        id: currentSong.id,
                        type: ArtworkType.AUDIO,
                        artworkWidth: artworkSize,
                        artworkHeight: artworkSize,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Container(
                          color: AppleMusicTheme.cardLighter,
                          child: Icon(
                            CupertinoIcons.music_note,
                            color: AppleMusicTheme.textSecondary.withOpacity(0.5),
                            size: 90,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Song Title & Artist + Favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppleMusicTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentSong.artist ?? "Unknown Artist",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppleMusicTheme.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.star,
                          color: AppleMusicTheme.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          // Favorite action
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Timeline Slider & Timestamps
                  StreamBuilder<Duration>(
                    stream: manager.player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final totalDuration =
                          manager.player.duration ?? Duration.zero;
                      final maxSeconds = totalDuration.inSeconds.toDouble();
                      final currentSeconds = position.inSeconds.toDouble().clamp(
                            0.0,
                            maxSeconds > 0 ? maxSeconds : 1.0,
                          );

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppleMusicTheme.textPrimary,
                              inactiveTrackColor:
                                  Colors.white.withOpacity(0.18),
                              thumbColor: AppleMusicTheme.textPrimary,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5),
                              trackHeight: 3.5,
                            ),
                            child: Slider(
                              value: currentSeconds,
                              min: 0.0,
                              max: maxSeconds > 0 ? maxSeconds : 1.0,
                              onChanged: (val) {
                                manager.seek(Duration(seconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: AppleMusicTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "-${_formatDuration(totalDuration - position)}",
                                  style: const TextStyle(
                                    color: AppleMusicTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Previous Track
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.backward_fill,
                          color: AppleMusicTheme.textPrimary,
                          size: 38,
                        ),
                        onPressed: () => manager.skipToPrevious(),
                      ),

                      // Large Play / Pause button
                      StreamBuilder<bool>(
                        stream: manager.player.playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return GestureDetector(
                            onTap: () => manager.playPause(),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: Icon(
                                isPlaying
                                    ? CupertinoIcons.pause_fill
                                    : CupertinoIcons.play_fill,
                                color: AppleMusicTheme.textPrimary,
                                size: 38,
                              ),
                            ),
                          );
                        },
                      ),

                      // Next Track
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.forward_fill,
                          color: AppleMusicTheme.textPrimary,
                          size: 38,
                        ),
                        onPressed: () => manager.skipToNext(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bottom Utilities (Lyrics, Airplay/Device, Playlist queue)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.quote_bubble,
                          color: AppleMusicTheme.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.airplayaudio,
                          color: AppleMusicTheme.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.list_bullet,
                          color: AppleMusicTheme.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
