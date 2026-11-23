import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

class AudioPlayerManager extends ChangeNotifier {
  late final AudioPlayer _player;
  late final AndroidEqualizer _equalizer;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> _playlist = [];
  int _currentIndex = -1;
  Color _dominantColor = const Color(0xFF1C1C1E);
  Color _secondaryColor = const Color(0xFF000000);

  bool _isEqualizerEnabled = true;
  AndroidEqualizerParameters? _equalizerParameters;
  String _currentPresetName = "Flat";

  AudioPlayerManager() {
    _initAudio();
  }

  AudioPlayer get player => _player;
  AndroidEqualizer get equalizer => _equalizer;
  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  SongModel? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  Color get dominantColor => _dominantColor;
  Color get secondaryColor => _secondaryColor;

  bool get isEqualizerEnabled => _isEqualizerEnabled;
  AndroidEqualizerParameters? get equalizerParameters => _equalizerParameters;
  String get currentPresetName => _currentPresetName;

  Future<void> _initAudio() async {
    // 1. Setup hardware equalizer for Android
    _equalizer = AndroidEqualizer();
    final pipeline = AudioPipeline(androidAudioEffects: [_equalizer]);
    _player = AudioPlayer(audioPipeline: pipeline);

    // 2. Enable equalizer by default
    try {
      await _equalizer.setEnabled(_isEqualizerEnabled);
      _equalizerParameters = await _equalizer.parameters;
    } catch (e) {
      debugPrint("Equalizer not supported on this platform: $e");
    }

    // 3. Listen to index change for artwork palette extraction
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _extractPalette(_playlist[index]);
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((_) {
      notifyListeners();
    });
  }

  // --- PLAYBACK METHODS ---

  void setPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    _playlist = songs;
    _currentIndex = initialIndex;

    final audioSources = songs.map((song) {
      return AudioSource.uri(
        Uri.parse(song.uri ?? song.data),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? "Unknown Album",
          title: song.title,
          artist: song.artist ?? "Unknown Artist",
          artUri: Uri.file(song.data), // can point to thumbnail or cache
        ),
      );
    }).toList();

    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        _extractPalette(_playlist[_currentIndex]);
      }
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
    notifyListeners();
  }

  void playPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void skipToNext() {
    if (_player.hasNext) {
      _player.seekToNext();
    }
  }

  void skipToPrevious() {
    if (_player.hasPrevious) {
      _player.seekToPrevious();
    }
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  // --- PALETTE EXTRACTION (Apple Music Dynamic Background) ---

  Future<void> _extractPalette(SongModel song) async {
    try {
      // Query artwork bytes
      final artworkBytes = await _audioQuery.queryArtwork(
        song.id,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      );

      if (artworkBytes != null && artworkBytes.isNotEmpty) {
        final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(artworkBytes),
          maximumColorCount: 16,
        );

        _dominantColor = palette.dominantColor?.color ??
            palette.darkVibrantColor?.color ??
            const Color(0xFF2C2C2E);

        _secondaryColor = palette.darkMutedColor?.color ??
            palette.mutedColor?.color ??
            const Color(0xFF000000);
      } else {
        // Fallback modern dark palette
        _dominantColor = const Color(0xFF202028);
        _secondaryColor = const Color(0xFF0A0A0D);
      }
    } catch (e) {
      _dominantColor = const Color(0xFF202028);
      _secondaryColor = const Color(0xFF0A0A0D);
    }
    notifyListeners();
  }

  // --- EQUALIZER METHODS ---

  Future<void> toggleEqualizer(bool enabled) async {
    _isEqualizerEnabled = enabled;
    try {
      await _equalizer.setEnabled(enabled);
    } catch (e) {
      debugPrint("Error toggling equalizer: $e");
    }
    notifyListeners();
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    if (_equalizerParameters == null) return;
    try {
      final band = _equalizerParameters!.bands[bandIndex];
      await band.setGain(gain);
      _currentPresetName = "Custom";
      notifyListeners();
    } catch (e) {
      debugPrint("Error setting band gain: $e");
    }
  }

  Future<void> applyPreset(AndroidEqualizerPreset preset) async {
    try {
      await _equalizer.setPreset(preset);
      _currentPresetName = preset.name;
      // Refresh parameters
      _equalizerParameters = await _equalizer.parameters;
      notifyListeners();
    } catch (e) {
      debugPrint("Error setting preset: $e");
    }
  }

  Future<void> resetToFlat() async {
    if (_equalizerParameters == null) return;
    try {
      for (final band in _equalizerParameters!.bands) {
        await band.setGain(0.0);
      }
      _currentPresetName = "Flat";
      notifyListeners();
    } catch (e) {
      debugPrint("Error resetting equalizer: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
