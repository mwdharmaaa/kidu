import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

class EqualizerPreset {
  final String name;
  final List<double> gains;
  const EqualizerPreset(this.name, this.gains);
}

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

  static const List<EqualizerPreset> defaultPresets = [
    EqualizerPreset("Flat", [0.0, 0.0, 0.0, 0.0, 0.0]),
    EqualizerPreset("Bass Booster", [5.0, 3.5, 0.0, 0.0, 0.0]),
    EqualizerPreset("Bass Reducer", [-5.0, -3.5, 0.0, 0.0, 0.0]),
    EqualizerPreset("Classical", [4.0, 2.5, -1.0, 2.5, 3.5]),
    EqualizerPreset("Electronic", [4.5, 2.5, 0.0, 2.0, 4.0]),
    EqualizerPreset("Hip-Hop", [5.5, 3.0, 0.0, 1.5, 3.0]),
    EqualizerPreset("Pop", [-1.5, 2.0, 4.5, 2.0, -1.0]),
    EqualizerPreset("Rock", [4.5, 2.5, -1.5, 2.5, 4.5]),
    EqualizerPreset("Vocal Booster", [-2.5, 2.0, 5.0, 3.0, 0.0]),
  ];

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
    _equalizer = AndroidEqualizer();
    final pipeline = AudioPipeline(androidAudioEffects: [_equalizer]);
    _player = AudioPlayer(audioPipeline: pipeline);

    try {
      await _equalizer.setEnabled(_isEqualizerEnabled);
      _equalizerParameters = await _equalizer.parameters;
    } catch (e) {
      debugPrint("Equalizer not supported on this platform: $e");
    }

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
          artUri: Uri.file(song.data),
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

  // --- PALETTE EXTRACTION ---

  Future<void> _extractPalette(SongModel song) async {
    try {
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

  Future<void> applyPreset(EqualizerPreset preset) async {
    if (_equalizerParameters == null) return;
    try {
      _currentPresetName = preset.name;
      final bands = _equalizerParameters!.bands;
      for (int i = 0; i < bands.length; i++) {
        final gain = (i < preset.gains.length) ? preset.gains[i] : 0.0;
        final clampedGain = gain.clamp(
          _equalizerParameters!.minDecibels,
          _equalizerParameters!.maxDecibels,
        );
        await bands[i].setGain(clampedGain);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error applying preset: $e");
    }
  }

  Future<void> resetToFlat() async {
    final flatPreset = defaultPresets.firstWhere(
      (p) => p.name == "Flat",
      orElse: () => const EqualizerPreset("Flat", [0.0]),
    );
    await applyPreset(flatPreset);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
