import 'dart:async';
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

class EqualizerBandInfo {
  final int index;
  final double centerFrequency;
  double gain;

  EqualizerBandInfo({
    required this.index,
    required this.centerFrequency,
    this.gain = 0.0,
  });
}

enum AudioQualityTier {
  highQuality, // High Quality AAC 256 kbps
  lossless, // Lossless up to 24-bit/48 kHz (ALAC/FLAC)
  hiResLossless, // Hi-Res Lossless up to 24-bit/192 kHz
}

class AudioQualityInfo {
  final String badgeText;
  final String formatDescription;
  final String sampleRate;
  final String bitDepth;
  final bool isHiRes;
  final bool isLossless;

  const AudioQualityInfo({
    required this.badgeText,
    required this.formatDescription,
    required this.sampleRate,
    required this.bitDepth,
    required this.isHiRes,
    required this.isLossless,
  });
}

class AudioPlayerManager extends ChangeNotifier {
  late final AudioPlayer _player;
  late final AndroidEqualizer _equalizer;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> _playlist = [];
  int _currentIndex = -1;
  Color _dominantColor = const Color(0xFF1C1C1E);
  Color _secondaryColor = const Color(0xFF000000);

  // Equalizer State - Instant Pre-cached In-Memory Data
  bool _isEqualizerEnabled = true;
  AndroidEqualizerParameters? _equalizerParameters;
  String _currentPresetName = "Flat";
  double _minDecibels = -15.0;
  double _maxDecibels = 15.0;

  List<EqualizerBandInfo> _bands = [
    EqualizerBandInfo(index: 0, centerFrequency: 60.0),
    EqualizerBandInfo(index: 1, centerFrequency: 230.0),
    EqualizerBandInfo(index: 2, centerFrequency: 910.0),
    EqualizerBandInfo(index: 3, centerFrequency: 3600.0),
    EqualizerBandInfo(index: 4, centerFrequency: 14000.0),
  ];

  // Audio Settings
  bool _isSoundCheckEnabled = true;
  bool _isCrossfadeEnabled = false;
  int _crossfadeSeconds = 4;
  bool _isGaplessPlaybackEnabled = true;
  AudioQualityTier _qualityTier = AudioQualityTier.hiResLossless;

  // Sleep Timer
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;
  bool _sleepTimerAtEndOfTrack = false;

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
  String get currentPresetName => _currentPresetName;
  List<EqualizerBandInfo> get bands => _bands;
  double get minDecibels => _minDecibels;
  double get maxDecibels => _maxDecibels;

  bool get isSoundCheckEnabled => _isSoundCheckEnabled;
  bool get isCrossfadeEnabled => _isCrossfadeEnabled;
  int get crossfadeSeconds => _crossfadeSeconds;
  bool get isGaplessPlaybackEnabled => _isGaplessPlaybackEnabled;
  AudioQualityTier get qualityTier => _qualityTier;

  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;
  bool get sleepTimerAtEndOfTrack => _sleepTimerAtEndOfTrack;

  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  bool get isShuffleEnabled => _player.shuffleModeEnabled;

  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  LoopMode get loopMode => _player.loopMode;

  Future<void> _initAudio() async {
    _equalizer = AndroidEqualizer();
    final pipeline = AudioPipeline(androidAudioEffects: [_equalizer]);
    _player = AudioPlayer(audioPipeline: pipeline);

    // Asynchronously connect to hardware equalizer parameters without blocking UI
    _equalizer.setEnabled(_isEqualizerEnabled).then((_) {
      return _equalizer.parameters;
    }).then((params) {
      _equalizerParameters = params;
      _minDecibels = params.minDecibels;
      _maxDecibels = params.maxDecibels;
      if (params.bands.isNotEmpty) {
        _bands = params.bands.asMap().entries.map((entry) {
          return EqualizerBandInfo(
            index: entry.key,
            centerFrequency: entry.value.centerFrequency,
            gain: entry.value.gain,
          );
        }).toList();
        notifyListeners();
      }
    }).catchError((e) {
      debugPrint("Hardware equalizer non-blocking init: $e");
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _extractPalette(_playlist[index]);
        if (_sleepTimerAtEndOfTrack) {
          _player.pause();
          _cancelSleepTimer();
        }
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _sleepTimerAtEndOfTrack) {
        _player.pause();
        _cancelSleepTimer();
      }
      notifyListeners();
    });
  }

  // --- PLAYBACK CONTROLS ---

  void setPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
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

  // --- SHUFFLE & LOOP CONTROLS ---

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  // --- DELETE AUDIO FILE ---

  Future<bool> deleteSong(SongModel song) async {
    try {
      final file = File(song.data);
      if (await file.exists()) {
        await file.delete();
      }

      final indexToRemove = _playlist.indexWhere((s) => s.id == song.id);
      if (indexToRemove != -1) {
        final isCurrent = indexToRemove == _currentIndex;
        _playlist.removeAt(indexToRemove);

        if (_playlist.isEmpty) {
          await _player.stop();
          _currentIndex = -1;
        } else if (isCurrent) {
          if (_currentIndex >= _playlist.length) {
            _currentIndex = _playlist.length - 1;
          }
          final nextSong = _playlist[_currentIndex];
          await _player.setUrl(nextSong.uri ?? nextSong.data);
          _extractPalette(nextSong);
        } else if (indexToRemove < _currentIndex) {
          _currentIndex--;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting audio file: $e");
      return false;
    }
  }

  // --- QUALITY & FORMAT DETECTION ---

  AudioQualityInfo getAudioQualityInfo(SongModel? song) {
    if (song == null) {
      return const AudioQualityInfo(
        badgeText: "HIGH QUALITY",
        formatDescription: "AAC Audio",
        sampleRate: "44.1 kHz",
        bitDepth: "16-bit",
        isHiRes: false,
        isLossless: false,
      );
    }

    final path = song.data.toLowerCase();
    final ext = path.split('.').last;
    final durationSec = (song.duration ?? 0) / 1000;
    final bitrateKbps = durationSec > 0 ? (song.size * 8) / (durationSec * 1000) : 0;

    if (ext == 'flac' || ext == 'alac' || ext == 'wav' || ext == 'aiff' || ext == 'dsd') {
      if (bitrateKbps > 1411 || path.contains('24bit') || path.contains('192k') || path.contains('96k')) {
        return AudioQualityInfo(
          badgeText: "HI-RES LOSSLESS",
          formatDescription: "${ext.toUpperCase()} Hi-Res Audio",
          sampleRate: "192 kHz",
          bitDepth: "24-bit",
          isHiRes: true,
          isLossless: true,
        );
      }
      return AudioQualityInfo(
        badgeText: "LOSSLESS",
        formatDescription: "${ext.toUpperCase()} Lossless Audio",
        sampleRate: "44.1 kHz",
        bitDepth: "16-bit",
        isHiRes: false,
        isLossless: true,
      );
    }

    return AudioQualityInfo(
      badgeText: "HIGH QUALITY",
      formatDescription: ext == 'mp3' ? "MP3 320 kbps" : "AAC 256 kbps",
      sampleRate: "44.1 kHz",
      bitDepth: "16-bit",
      isHiRes: false,
      isLossless: false,
    );
  }

  // --- AUDIO SETTINGS ---

  void setSoundCheck(bool enabled) {
    _isSoundCheckEnabled = enabled;
    _player.setVolume(enabled ? 0.92 : 1.0);
    notifyListeners();
  }

  void setCrossfade(bool enabled, [int? seconds]) {
    _isCrossfadeEnabled = enabled;
    if (seconds != null) _crossfadeSeconds = seconds;
    notifyListeners();
  }

  void setGaplessPlayback(bool enabled) {
    _isGaplessPlaybackEnabled = enabled;
    notifyListeners();
  }

  void setQualityTier(AudioQualityTier tier) {
    _qualityTier = tier;
    notifyListeners();
  }

  // --- SLEEP TIMER ---

  void setSleepTimer(Duration? duration, {bool endOfTrack = false}) {
    _cancelSleepTimer();

    if (endOfTrack) {
      _sleepTimerAtEndOfTrack = true;
      _sleepTimerEndTime = null;
      notifyListeners();
      return;
    }

    if (duration != null) {
      _sleepTimerEndTime = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () {
        _player.pause();
        _cancelSleepTimer();
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void cancelSleepTimer() {
    _cancelSleepTimer();
    notifyListeners();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    _sleepTimerAtEndOfTrack = false;
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

  // --- INSTANT EQUALIZER METHODS ---

  Future<void> toggleEqualizer(bool enabled) async {
    _isEqualizerEnabled = enabled;
    notifyListeners();
    try {
      await _equalizer.setEnabled(enabled);
    } catch (e) {
      debugPrint("Error toggling equalizer: $e");
    }
  }

  void setBandGain(int bandIndex, double gain) {
    if (bandIndex >= 0 && bandIndex < _bands.length) {
      _bands[bandIndex].gain = gain;
      _currentPresetName = "Custom";
      notifyListeners();
    }

    if (_equalizerParameters != null &&
        bandIndex < _equalizerParameters!.bands.length) {
      _equalizerParameters!.bands[bandIndex].setGain(gain).catchError((e) {
        debugPrint("Background setGain error: $e");
      });
    }
  }

  void applyPreset(EqualizerPreset preset) {
    _currentPresetName = preset.name;
    for (int i = 0; i < _bands.length; i++) {
      final gain = (i < preset.gains.length) ? preset.gains[i] : 0.0;
      final clampedGain = gain.clamp(_minDecibels, _maxDecibels);
      _bands[i].gain = clampedGain;

      if (_equalizerParameters != null &&
          i < _equalizerParameters!.bands.length) {
        _equalizerParameters!.bands[i].setGain(clampedGain).catchError((e) {
          debugPrint("Background applyPreset error: $e");
        });
      }
    }
    notifyListeners();
  }

  void resetToFlat() {
    final flatPreset = defaultPresets.firstWhere(
      (p) => p.name == "Flat",
      orElse: () => const EqualizerPreset("Flat", [0.0]),
    );
    applyPreset(flatPreset);
  }

  @override
  void dispose() {
    _cancelSleepTimer();
    _player.dispose();
    super.dispose();
  }
}
