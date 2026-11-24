import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../services/audio_player_manager.dart';
import '../../../theme/qidu_theme.dart';

class LyricsSheet extends StatefulWidget {
  final SongModel song;

  const LyricsSheet({super.key, required this.song});

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  List<LyricLine> _lyrics = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    setState(() => _isLoading = true);
    final manager = context.read<AudioPlayerManager>();
    final loaded = await manager.loadLyrics(widget.song);
    if (mounted) {
      setState(() {
        _lyrics = loaded;
        _isLoading = false;
      });
    }
  }

  int _findCurrentIndex(Duration position) {
    if (_lyrics.isEmpty) return -1;
    for (int i = _lyrics.length - 1; i >= 0; i--) {
      if (position >= _lyrics[i].time) {
        return i;
      }
    }
    return 0;
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0 || index >= _lyrics.length) return;
    final targetOffset = (index * 68.0) - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _showAddLyricsDialog(BuildContext context, AudioPlayerManager manager) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QiduTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Tempel Lirik (.lrc)",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tempelkan teks lirik berformat timestamp [mm:ss.xx] lirik:",
              style: TextStyle(color: QiduTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: "[00:12.50] Baris pertama lirik...\n[00:16.80] Baris kedua lirik...",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: QiduTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: QiduTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Simpan Lirik"),
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                try {
                  final filePath = widget.song.data;
                  final dot = filePath.lastIndexOf('.');
                  final lrcPath = dot != -1 ? '${filePath.substring(0, dot)}.lrc' : '$filePath.lrc';
                  final file = File(lrcPath);
                  await file.writeAsString(content);
                  Navigator.pop(ctx);
                  _loadLyrics();
                } catch (e) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal menyimpan file .lrc: $e")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();
    final title = manager.getSongTitle(widget.song);
    final artist = manager.getSongArtist(widget.song);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: manager.dominantColor.withOpacity(0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            children: [
              // Sheet Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: QiduTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.pencil, color: Colors.white70, size: 20),
                      tooltip: "Edit / Tambah Lirik",
                      onPressed: () => _showAddLyricsDialog(context, manager),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white54, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Lyrics Body
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: QiduTheme.accentColor),
                      )
                    : _lyrics.isEmpty
                        ? _buildEmptyState(manager)
                        : _buildLyricsList(manager),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AudioPlayerManager manager) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
              child: const Icon(
                CupertinoIcons.quote_bubble,
                color: Colors.white60,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Lirik Belum Tersedia",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Simpan file teks .lrc dengan nama yang sama di folder lagu Anda, atau ketuk tombol di bawah untuk memasukkan lirik secara manual.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: QiduTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text("Tempel / Tulis Lirik .lrc"),
              style: ElevatedButton.styleFrom(
                backgroundColor: QiduTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _showAddLyricsDialog(context, manager),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsList(AudioPlayerManager manager) {
    return StreamBuilder<Duration>(
      stream: manager.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final activeIndex = _findCurrentIndex(position);

        if (activeIndex != _lastActiveIndex && activeIndex != -1) {
          _lastActiveIndex = activeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToIndex(activeIndex);
          });
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          itemCount: _lyrics.length,
          itemBuilder: (context, index) {
            final line = _lyrics[index];
            final isActive = index == activeIndex;

            return GestureDetector(
              onTap: () {
                manager.seek(line.time);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  line.text,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.32),
                    fontSize: isActive ? 24 : 19,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: -0.4,
                    height: 1.3,
                    shadows: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
