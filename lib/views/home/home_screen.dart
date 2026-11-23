import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/qidu_theme.dart';
import '../player/widgets/mini_player.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;
  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() => _isLoading = true);

    bool granted = false;
    if (await Permission.audio.status.isGranted ||
        await Permission.storage.status.isGranted) {
      granted = true;
    } else {
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) {
        granted = true;
      } else {
        final storageStatus = await Permission.storage.request();
        granted = storageStatus.isGranted;
      }
    }

    if (!granted) {
      granted = await _audioQuery.permissionsRequest();
    }

    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      _loadLocalSongs();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLocalSongs() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      setState(() {
        _allSongs = songs;
        _filteredSongs = songs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error querying songs: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSongs = _allSongs);
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      _filteredSongs = _allSongs.where((song) {
        final title = song.title.toLowerCase();
        final artist = (song.artist ?? "").toLowerCase();
        return title.contains(lower) || artist.contains(lower);
      }).toList();
    });
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) return "--:--";
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }

  void _deleteSong(AudioPlayerManager manager, SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QiduTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Audio File?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Permanently delete \"${song.title}\" from your device storage? This cannot be undone.",
          style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: QiduTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await manager.deleteSong(song);
      if (mounted) {
        if (success) {
          setState(() {
            _allSongs.removeWhere((s) => s.id == song.id);
            _filteredSongs.removeWhere((s) => s.id == song.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Deleted ${song.title}"),
              backgroundColor: QiduTheme.cardLighter,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete file from device storage."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.read<AudioPlayerManager>();

    return Scaffold(
      backgroundColor: QiduTheme.backgroundBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icon/logo.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Qidu 1.2",
                        style: TextStyle(
                          color: QiduTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.gear_alt, color: QiduTheme.textPrimary, size: 24),
                        tooltip: "Settings",
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.arrow_clockwise, color: QiduTheme.accentColor, size: 22),
                        tooltip: "Refresh Library",
                        onPressed: _checkAndRequestPermissions,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: QiduTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSongs,
                  style: const TextStyle(
                    color: QiduTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Search songs, artists...",
                    hintStyle: TextStyle(
                      color: QiduTheme.textSecondary,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: QiduTheme.textSecondary,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Songs List
            Expanded(
              child: _buildBody(manager),
            ),

            // Docked Mini Player
            const MiniPlayer(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AudioPlayerManager manager) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: QiduTheme.accentColor,
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.folder_badge_minus,
                color: QiduTheme.accentColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Access to Audio Required",
                style: TextStyle(
                  color: QiduTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Grant permission to scan and play high-fidelity local audio files on your device.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: QiduTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QiduTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _checkAndRequestPermissions,
                child: const Text("Allow Access"),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredSongs.isEmpty) {
      return const Center(
        child: Text(
          "No local audio files found",
          style: TextStyle(
            color: QiduTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkWidth: 48,
              artworkHeight: 48,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(
                width: 48,
                height: 48,
                color: QiduTheme.cardDark,
                child: const Icon(
                  CupertinoIcons.music_note,
                  color: QiduTheme.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: QiduTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            song.artist ?? "Unknown Artist",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: QiduTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(song.duration),
                style: const TextStyle(
                  color: QiduTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.ellipsis, color: QiduTheme.textSecondary, size: 18),
                color: QiduTheme.cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'delete') {
                    _deleteSong(manager, song);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            manager.setPlaylist(_filteredSongs, initialIndex: index);
          },
        );
      },
    );
  }
}
