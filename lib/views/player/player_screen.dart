import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/qidu_theme.dart';
import '../equalizer/equalizer_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/lyrics_sheet.dart';
import 'widgets/queue_sheet.dart';
import '../home/widgets/metadata_editor_dialog.dart';

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
        backgroundColor: Colors.black,
        body: Center(
          child: Text("No audio selected", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = screenWidth * 0.78;
    final qualityInfo = manager.getAudioQualityInfo(currentSong);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fluid Ambient Gradient Mesh
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
                          color: QiduTheme.textSecondary,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        "Now Playing",
                        style: TextStyle(
                          color: QiduTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // More Options Menu (Delete, Equalizer, Settings)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          CupertinoIcons.ellipsis_circle,
                          color: QiduTheme.textSecondary,
                          size: 24,
                        ),
                        color: QiduTheme.cardDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        onSelected: (val) {
                          if (val == 'equalizer') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                            );
                          } else if (val == 'settings') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          } else if (val == 'edit_tag') {
                            showDialog(
                              context: context,
                              builder: (_) => MetadataEditorDialog(song: currentSong),
                            );
                          } else if (val == 'delete') {
                            _confirmDelete(context, manager, currentSong);
                          } else if (val == 'quality') {
                            _showQualityDetails(context, qualityInfo);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'quality',
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.waveform_circle, size: 18, color: QiduTheme.hiResGold),
                                SizedBox(width: 12),
                                Text("Audio Quality Info"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit_tag',
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.pencil, size: 18, color: Colors.white),
                                SizedBox(width: 12),
                                Text("Edit Info Lagu"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'equalizer',
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: QiduTheme.accentColor),
                                SizedBox(width: 12),
                                Text("Equalizer"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.gear, size: 18, color: Colors.white),
                                SizedBox(width: 12),
                                Text("Audio Settings"),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Text("Delete Song", style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Album Artwork with Bouncing Animation & Fluid Shadow
                  StreamBuilder<bool>(
                    stream: manager.player.playingStream,
                    builder: (context, playingSnapshot) {
                      final isPlaying = playingSnapshot.data ?? false;
                      return AnimatedScale(
                        scale: isPlaying ? 1.0 : 0.86,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: isPlaying ? 1.0 : 0.82,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: artworkSize,
                            height: artworkSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isPlaying ? 0.5 : 0.25),
                                  blurRadius: isPlaying ? 40 : 20,
                                  offset: Offset(0, isPlaying ? 22 : 10),
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
                                  color: QiduTheme.cardLighter,
                                  child: Icon(
                                    CupertinoIcons.music_note,
                                    color: QiduTheme.textSecondary.withOpacity(0.5),
                                    size: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Song Title, Artist & Lossless Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  manager.getSongTitle(currentSong),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: QiduTheme.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  manager.getSongArtist(currentSong),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: QiduTheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              manager.isFavorite(currentSong.id)
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: manager.isFavorite(currentSong.id)
                                  ? QiduTheme.accentColor
                                  : QiduTheme.textSecondary,
                              size: 24,
                            ),
                            tooltip: "Favorit",
                            onPressed: () => manager.toggleFavorite(currentSong.id),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Lossless / Hi-Res Lossless Interactive Badge
                      GestureDetector(
                        onTap: () => _showQualityDetails(context, qualityInfo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: QiduTheme.losslessBadgeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: qualityInfo.isHiRes
                                  ? QiduTheme.hiResGold.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                qualityInfo.isLossless
                                    ? CupertinoIcons.waveform
                                    : CupertinoIcons.music_note_2,
                                color: qualityInfo.isHiRes
                                    ? QiduTheme.hiResGold
                                    : QiduTheme.textSecondary,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                qualityInfo.badgeText,
                                style: TextStyle(
                                  color: qualityInfo.isHiRes
                                      ? QiduTheme.hiResGold
                                      : QiduTheme.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Timeline Slider & Timestamps
                  StreamBuilder<Duration>(
                    stream: manager.player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final totalDuration = manager.player.duration ?? Duration.zero;
                      final maxSeconds = totalDuration.inSeconds.toDouble();
                      final currentSeconds = position.inSeconds.toDouble().clamp(
                            0.0,
                            maxSeconds > 0 ? maxSeconds : 1.0,
                          );

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: QiduTheme.textPrimary,
                              inactiveTrackColor: Colors.white.withOpacity(0.18),
                              thumbColor: QiduTheme.textPrimary,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
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
                                    color: QiduTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "-${_formatDuration(totalDuration - position)}",
                                  style: const TextStyle(
                                    color: QiduTheme.textSecondary,
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

                  const SizedBox(height: 8),

                  // Transport Controls (Shuffle, Previous, Play/Pause, Next, Loop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle Button
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: manager.isShuffleEnabled
                              ? QiduTheme.accentColor
                              : QiduTheme.textSecondary,
                          size: 22,
                        ),
                        tooltip: manager.shuffleModeDescription,
                        onPressed: () async {
                          final msg = await manager.toggleShuffle();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                duration: const Duration(milliseconds: 1000),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: QiduTheme.cardDark,
                              ),
                            );
                          }
                        },
                      ),

                      // Previous Track
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.backward_fill,
                          color: QiduTheme.textPrimary,
                          size: 36,
                        ),
                        onPressed: () => manager.skipToPrevious(),
                      ),

                      // Large Play/Pause button
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
                                isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                color: QiduTheme.textPrimary,
                                size: 36,
                              ),
                            ),
                          );
                        },
                      ),

                      // Next Track
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.forward_fill,
                          color: QiduTheme.textPrimary,
                          size: 36,
                        ),
                        onPressed: () => manager.skipToNext(),
                      ),

                      // Loop / Repeat Button
                      IconButton(
                        icon: Icon(
                          manager.loopMode == LoopMode.one
                              ? CupertinoIcons.repeat_1
                              : CupertinoIcons.repeat,
                          color: manager.loopMode != LoopMode.off
                              ? QiduTheme.accentColor
                              : QiduTheme.textSecondary,
                          size: 22,
                        ),
                        tooltip: "Mode: ${manager.loopModeDescription}",
                        onPressed: () async {
                          final msg = await manager.toggleLoopMode();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                duration: const Duration(milliseconds: 1000),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: QiduTheme.cardDark,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Apple Music Style Volume Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.volume_down, color: QiduTheme.textSecondary, size: 16),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white.withOpacity(0.65),
                              inactiveTrackColor: Colors.white.withOpacity(0.14),
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                              trackHeight: 3,
                            ),
                            child: StreamBuilder<double>(
                              stream: manager.volumeStream,
                              builder: (context, volSnap) {
                                final vol = volSnap.data ?? manager.volume;
                                return Slider(
                                  value: vol.clamp(0.0, 1.0),
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) => manager.setVolume(val),
                                );
                              },
                            ),
                          ),
                        ),
                        const Icon(CupertinoIcons.volume_up, color: QiduTheme.textSecondary, size: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom Utilities
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.quote_bubble, color: QiduTheme.textSecondary, size: 22),
                        tooltip: "Lirik Lagu",
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => LyricsSheet(song: currentSong),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.devices_rounded, color: QiduTheme.textSecondary, size: 22),
                        tooltip: "Pengaturan Audio",
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.list_bullet, color: QiduTheme.textSecondary, size: 22),
                        tooltip: "Antrean Lagu",
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const QueueSheet(),
                          );
                        },
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

  void _showQualityDetails(BuildContext context, AudioQualityInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: QiduTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  info.isLossless ? CupertinoIcons.waveform : CupertinoIcons.music_note_2,
                  color: info.isHiRes ? QiduTheme.hiResGold : QiduTheme.accentColor,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  info.badgeText,
                  style: TextStyle(
                    color: info.isHiRes ? QiduTheme.hiResGold : QiduTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("Format", info.formatDescription),
            _infoRow("Sample Rate", info.sampleRate),
            _infoRow("Bit Depth", info.bitDepth),
            _infoRow("Channel Layout", "Stereo 2.0"),
            _infoRow("Decoder Engine", "Studio Native Hardware"),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done", style: TextStyle(color: QiduTheme.accentColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: QiduTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AudioPlayerManager manager, SongModel song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QiduTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Berkas Audio?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Hapus \"${manager.getSongTitle(song)}\" secara permanen dari penyimpanan perangkat? Tindakan ini tidak dapat dibatalkan.",
          style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: QiduTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);

              if (Platform.isAndroid) {
                var manageGranted = await Permission.manageExternalStorage.isGranted;
                if (!manageGranted) {
                  final status = await Permission.manageExternalStorage.request();
                  manageGranted = status.isGranted;
                }

                if (!manageGranted) {
                  var storageGranted = await Permission.storage.isGranted;
                  if (!storageGranted) {
                    final s = await Permission.storage.request();
                    storageGranted = s.isGranted;
                  }
                  manageGranted = storageGranted;
                }

                if (!manageGranted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Izin kelola berkas diperlukan untuk menghapus lagu."),
                      backgroundColor: Colors.redAccent,
                      action: SnackBarAction(
                        label: "Pengaturan",
                        textColor: Colors.white,
                        onPressed: () => openAppSettings(),
                      ),
                    ),
                  );
                  return;
                }
              }

              final success = await manager.deleteSong(song);
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Exit player screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Berhasil menghapus ${manager.getSongTitle(song)}"),
                      backgroundColor: QiduTheme.cardLighter,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Gagal menghapus berkas dari penyimpanan perangkat."),
                      backgroundColor: Colors.redAccent,
                      action: SnackBarAction(
                        label: "Pengaturan",
                        textColor: Colors.white,
                        onPressed: () => openAppSettings(),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
