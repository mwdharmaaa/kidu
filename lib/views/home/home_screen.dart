import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/apple_music_theme.dart';
import '../player/widgets/mini_player.dart';

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

    // Permission handling: Android 13+ requires audio permission, older versions require storage
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

    // Also verify with on_audio_query
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

  @override
  Widget build(BuildContext context) {
    final manager = context.read<AudioPlayerManager>();

    return Scaffold(
      backgroundColor: AppleMusicTheme.backgroundBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Apple Music Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Library",
                    style: TextStyle(
                      color: AppleMusicTheme.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                    ),
                  ),
                  TextButton(
                    onPressed: _checkAndRequestPermissions,
                    child: const Text(
                      "Refresh",
                      style: TextStyle(
                        color: AppleMusicTheme.accentRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  color: AppleMusicTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSongs,
                  style: const TextStyle(
                    color: AppleMusicTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Search in library...",
                    hintStyle: TextStyle(
                      color: AppleMusicTheme.textSecondary,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: AppleMusicTheme.textSecondary,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Songs List or Permission Prompt
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
          color: AppleMusicTheme.accentRed,
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
                color: AppleMusicTheme.accentRed,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Access to Music Required",
                style: TextStyle(
                  color: AppleMusicTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please grant permission so we can scan and play your local audio files.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppleMusicTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppleMusicTheme.accentRed,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          "No music files found",
          style: TextStyle(
            color: AppleMusicTheme.textSecondary,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                color: AppleMusicTheme.cardDark,
                child: const Icon(
                  CupertinoIcons.music_note,
                  color: AppleMusicTheme.textSecondary,
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
              color: AppleMusicTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            song.artist ?? "Unknown Artist",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppleMusicTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          trailing: Text(
            _formatDuration(song.duration),
            style: const TextStyle(
              color: AppleMusicTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          onTap: () {
            manager.setPlaylist(_filteredSongs, initialIndex: index);
          },
        );
      },
    );
  }
}
