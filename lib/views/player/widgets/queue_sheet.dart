import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../services/audio_player_manager.dart';
import '../../../theme/qidu_theme.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) return "--:--";
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();
    final playlist = manager.playlist;
    final currentIndex = manager.currentIndex;
    final currentSong = manager.currentSong;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: QiduTheme.cardDark.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Antrean Putar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "${playlist.length} Lagu dalam Antrean",
                          style: const TextStyle(
                            color: QiduTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.shuffle,
                            color: manager.isShuffleEnabled
                                ? QiduTheme.accentColor
                                : Colors.white60,
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
                        IconButton(
                          icon: Icon(
                            manager.loopMode == LoopMode.one
                                ? CupertinoIcons.repeat_1
                                : CupertinoIcons.repeat,
                            color: manager.loopMode != LoopMode.off
                                ? QiduTheme.accentColor
                                : Colors.white60,
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
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Colors.white54,
                            size: 26,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Content Body
              Expanded(
                child: playlist.isEmpty
                    ? const Center(
                        child: Text(
                          "Antrean kosong",
                          style: TextStyle(color: QiduTheme.textSecondary),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        children: [
                          // Now Playing Section
                          if (currentSong != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                "SEDANG DIPUTAR",
                                style: TextStyle(
                                  color: QiduTheme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: QiduTheme.accentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: QiduTheme.accentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: QueryArtworkWidget(
                                    id: currentSong.id,
                                    type: ArtworkType.AUDIO,
                                    artworkWidth: 46,
                                    artworkHeight: 46,
                                    nullArtworkWidget: Container(
                                      width: 46,
                                      height: 46,
                                      color: QiduTheme.cardLighter,
                                      child: const Icon(
                                        CupertinoIcons.music_note,
                                        color: Colors.white60,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  manager.getSongTitle(currentSong),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  manager.getSongArtist(currentSong),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: QiduTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: const Icon(
                                  CupertinoIcons.waveform,
                                  color: QiduTheme.accentColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Up Next Section Header
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text(
                              "BERIKUTNYA",
                              style: TextStyle(
                                color: QiduTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          // Playlist Items (Reorderable)
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: playlist.length,
                            onReorder: (oldIndex, newIndex) {
                              manager.reorderQueue(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final song = playlist[index];
                              final isCurrent = index == currentIndex;

                              return Dismissible(
                                key: ValueKey("${song.id}_$index"),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.redAccent,
                                  child: const Icon(CupertinoIcons.trash, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  manager.removeFromQueue(index);
                                },
                                child: Container(
                                  key: ValueKey("tile_${song.id}_$index"),
                                  color: isCurrent
                                      ? Colors.white.withOpacity(0.04)
                                      : Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 2,
                                    ),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: QueryArtworkWidget(
                                        id: song.id,
                                        type: ArtworkType.AUDIO,
                                        artworkWidth: 42,
                                        artworkHeight: 42,
                                        nullArtworkWidget: Container(
                                          width: 42,
                                          height: 42,
                                          color: QiduTheme.cardLighter,
                                          child: const Icon(
                                            CupertinoIcons.music_note,
                                            color: Colors.white38,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      manager.getSongTitle(song),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCurrent ? QiduTheme.accentColor : Colors.white,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      manager.getSongArtist(song),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: QiduTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatDuration(song.duration),
                                          style: const TextStyle(
                                            color: QiduTheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(
                                            CupertinoIcons.line_horizontal_3,
                                            color: Colors.white38,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      manager.playAtIndex(index);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
