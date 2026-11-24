import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/qidu_theme.dart';
import '../player/widgets/mini_player.dart';
import '../settings/settings_screen.dart';
import 'widgets/metadata_editor_dialog.dart';

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
  int _selectedTabIndex = 0; // 0: Songs, 1: Favorites, 2: Artists, 3: Albums
  String? _selectedArtistFilter;
  String? _selectedAlbumFilter;
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
        final album = (song.album ?? "").toLowerCase();
        return title.contains(lower) || artist.contains(lower) || album.contains(lower);
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
        title: const Text("Hapus Berkas Audio?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Hapus \"${manager.getSongTitle(song)}\" secara permanen dari penyimpanan perangkat?",
          style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: QiduTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
              content: Text("Berhasil menghapus ${manager.getSongTitle(song)}"),
              backgroundColor: QiduTheme.cardLighter,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal menghapus berkas dari penyimpanan perangkat."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _selectedArtistFilter = null;
          _selectedAlbumFilter = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? QiduTheme.accentColor : QiduTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : QiduTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : QiduTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();

    return Scaffold(
      backgroundColor: QiduTheme.backgroundBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
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
                        "Qidu 1.3",
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
                        tooltip: "Pengaturan Audio",
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.arrow_clockwise, color: QiduTheme.accentColor, size: 22),
                        tooltip: "Pindai Ulang Lagu",
                        onPressed: _checkAndRequestPermissions,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
                    hintText: "Cari lagu, artis, atau album...",
                    hintStyle: TextStyle(
                      color: QiduTheme.textSecondary,
                      fontSize: 14,
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

            // Category Tab Pills (Apple Music Navigation)
            Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTabPill(0, "Semua Lagu", CupertinoIcons.music_note_list),
                  _buildTabPill(1, "Favorit", CupertinoIcons.heart_fill),
                  _buildTabPill(2, "Artis", CupertinoIcons.person_2),
                  _buildTabPill(3, "Album", CupertinoIcons.square_stack_3d_down_right),
                ],
              ),
            ),

            // Main Content Area
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
                "Izin Akses Audio Diperlukan",
                style: TextStyle(
                  color: QiduTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Berikan izin untuk memindai dan memutar berkas audio lokal di memori HP Anda.",
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
                child: const Text("Beri Izin Akses"),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedTabIndex) {
      case 1:
        return _buildFavoritesTab(manager);
      case 2:
        return _buildArtistsTab(manager);
      case 3:
        return _buildAlbumsTab(manager);
      case 0:
      default:
        return _buildSongsTab(manager);
    }
  }

  Widget _buildSongsTab(AudioPlayerManager manager) {
    if (_filteredSongs.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada berkas audio ditemukan",
          style: TextStyle(color: QiduTheme.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return _buildSongTile(manager, song, _filteredSongs, index);
      },
    );
  }

  Widget _buildFavoritesTab(AudioPlayerManager manager) {
    final favSongs = _allSongs.where((s) => manager.isFavorite(s.id)).toList();

    if (favSongs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.heart_fill,
                color: Colors.white.withOpacity(0.18),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Belum Ada Lagu Favorit",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ketuk ikon hati pada lagu yang Anda sukai untuk mengumpulkannya di sini.",
                textAlign: TextAlign.center,
                style: TextStyle(color: QiduTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: favSongs.length,
      itemBuilder: (context, index) {
        final song = favSongs[index];
        return _buildSongTile(manager, song, favSongs, index);
      },
    );
  }

  Widget _buildArtistsTab(AudioPlayerManager manager) {
    if (_selectedArtistFilter != null) {
      final artistSongs = _allSongs
          .where((s) => manager.getSongArtist(s) == _selectedArtistFilter)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.chevron_back, color: QiduTheme.accentColor),
                  onPressed: () => setState(() => _selectedArtistFilter = null),
                ),
                Expanded(
                  child: Text(
                    _selectedArtistFilter!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${artistSongs.length} Lagu",
                  style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: artistSongs.length,
              itemBuilder: (context, index) => _buildSongTile(manager, artistSongs[index], artistSongs, index),
            ),
          ),
        ],
      );
    }

    // Group songs by artist
    final Map<String, List<SongModel>> artistsMap = {};
    for (final song in _filteredSongs) {
      final artist = manager.getSongArtist(song);
      artistsMap.putIfAbsent(artist, () => []).add(song);
    }

    final artistList = artistsMap.keys.toList()..sort();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: artistList.length,
      itemBuilder: (context, index) {
        final artist = artistList[index];
        final count = artistsMap[artist]?.length ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QiduTheme.cardDark,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(CupertinoIcons.person, color: QiduTheme.accentColor, size: 22),
          ),
          title: Text(
            artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            "$count Lagu",
            style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 13),
          ),
          trailing: const Icon(CupertinoIcons.chevron_forward, color: QiduTheme.textSecondary, size: 16),
          onTap: () {
            setState(() => _selectedArtistFilter = artist);
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab(AudioPlayerManager manager) {
    if (_selectedAlbumFilter != null) {
      final albumSongs = _allSongs
          .where((s) => manager.getSongAlbum(s) == _selectedAlbumFilter)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.chevron_back, color: QiduTheme.accentColor),
                  onPressed: () => setState(() => _selectedAlbumFilter = null),
                ),
                Expanded(
                  child: Text(
                    _selectedAlbumFilter!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${albumSongs.length} Lagu",
                  style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: albumSongs.length,
              itemBuilder: (context, index) => _buildSongTile(manager, albumSongs[index], albumSongs, index),
            ),
          ),
        ],
      );
    }

    // Group songs by album
    final Map<String, List<SongModel>> albumsMap = {};
    for (final song in _filteredSongs) {
      final album = manager.getSongAlbum(song);
      albumsMap.putIfAbsent(album, () => []).add(song);
    }

    final albumList = albumsMap.keys.toList()..sort();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: albumList.length,
      itemBuilder: (context, index) {
        final album = albumList[index];
        final songs = albumsMap[album]!;
        final firstSong = songs.first;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedAlbumFilter = album);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: QueryArtworkWidget(
                    id: firstSong.id,
                    type: ArtworkType.AUDIO,
                    artworkWidth: double.infinity,
                    artworkHeight: double.infinity,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      color: QiduTheme.cardDark,
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.square_stack_3d_down_right,
                          color: QiduTheme.textSecondary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                manager.getSongArtist(firstSong),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: QiduTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongTile(
    AudioPlayerManager manager,
    SongModel song,
    List<SongModel> playlistContext,
    int index,
  ) {
    final title = manager.getSongTitle(song);
    final artist = manager.getSongArtist(song);
    final isFav = manager.isFavorite(song.id);

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
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: QiduTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        artist,
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
          IconButton(
            icon: Icon(
              isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isFav ? QiduTheme.accentColor : Colors.white24,
              size: 20,
            ),
            tooltip: "Favorit",
            onPressed: () => manager.toggleFavorite(song.id),
          ),
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
              } else if (val == 'edit_tag') {
                showDialog(
                  context: context,
                  builder: (_) => MetadataEditorDialog(song: song),
                );
              } else if (val == 'fav') {
                manager.toggleFavorite(song.id);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'fav',
                child: Row(
                  children: [
                    Icon(
                      isFav ? CupertinoIcons.heart_slash : CupertinoIcons.heart,
                      color: QiduTheme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFav ? "Hapus dari Favorit" : "Tambah ke Favorit",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_tag',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.pencil, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text("Edit Info Lagu", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                    SizedBox(width: 8),
                    Text("Hapus Berkas", style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        manager.setPlaylist(playlistContext, initialIndex: index);
      },
    );
  }
}
