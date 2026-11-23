import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/apple_music_theme.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  String _formatFreq(double hz) {
    if (hz >= 1000) {
      return "${(hz / 1000).toStringAsFixed(1).replaceAll('.0', '')} kHz";
    }
    return "${hz.toInt()} Hz";
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();
    final equalizer = manager.equalizer;

    return Scaffold(
      backgroundColor: AppleMusicTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          "Equalizer",
          style: TextStyle(
            color: AppleMusicTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppleMusicTheme.accentRed),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => manager.resetToFlat(),
            child: const Text(
              "Reset",
              style: TextStyle(
                color: AppleMusicTheme.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<AndroidEqualizerParameters>(
        future: equalizer.parameters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppleMusicTheme.accentRed,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: AppleMusicTheme.textSecondary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Hardware Equalizer Not Available on this device or emulator.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppleMusicTheme.textSecondary.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final params = snapshot.data!;
          final minDb = params.minDecibels;
          final maxDb = params.maxDecibels;
          final bands = params.bands;
          const presets = AudioPlayerManager.defaultPresets;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Equalizer Enable/Disable Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppleMusicTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Audio Equalizer",
                          style: TextStyle(
                            color: AppleMusicTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Apple Music 10-Band Hardware Processing",
                          style: TextStyle(
                            color: AppleMusicTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: manager.isEqualizerEnabled,
                      activeColor: AppleMusicTheme.accentRed,
                      onChanged: (val) => manager.toggleEqualizer(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Presets Selector (Horizontal Scrolling Pills)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "PRESETS",
                  style: TextStyle(
                    color: AppleMusicTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    final isSelected =
                        manager.currentPresetName.toLowerCase() ==
                            preset.name.toLowerCase();

                    return ChoiceChip(
                      label: Text(preset.name),
                      selected: isSelected,
                      selectedColor: AppleMusicTheme.accentRed,
                      backgroundColor: AppleMusicTheme.cardDark,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppleMusicTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppleMusicTheme.accentRed
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          manager.applyPreset(preset);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 3. Graphic Equalizer Sliders Container
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "GRAPHIC EQUALIZER",
                  style: TextStyle(
                    color: AppleMusicTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                height: 310,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: AppleMusicTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Decibel markers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "+${maxDb.toInt()} dB",
                          style: const TextStyle(
                            color: AppleMusicTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          "0 dB",
                          style: TextStyle(
                            color: AppleMusicTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${minDb.toInt()} dB",
                          style: const TextStyle(
                            color: AppleMusicTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Sliders Row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: bands.asMap().entries.map((entry) {
                          final bandIndex = entry.key;
                          final band = entry.value;

                          return StreamBuilder<double>(
                            stream: band.gainStream,
                            builder: (context, gainSnapshot) {
                              final currentGain =
                                  (gainSnapshot.data ?? 0.0).clamp(minDb, maxDb);

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Gain readout
                                  Text(
                                    "${currentGain >= 0 ? '+' : ''}${currentGain.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      color: currentGain != 0.0
                                          ? AppleMusicTheme.accentRed
                                          : AppleMusicTheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  // Vertical Slider
                                  Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbColor: Colors.white,
                                          activeTrackColor:
                                              AppleMusicTheme.accentRed,
                                          inactiveTrackColor: AppleMusicTheme
                                              .sliderTrackInactive,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                            enabledThumbRadius: 6,
                                          ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                        ),
                                        child: Slider(
                                          min: minDb,
                                          max: maxDb,
                                          value: currentGain,
                                          onChanged: manager.isEqualizerEnabled
                                              ? (newGain) {
                                                  manager.setBandGain(
                                                      bandIndex, newGain);
                                                }
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Center Frequency Label (e.g., 60 Hz, 1 kHz)
                                  Text(
                                    _formatFreq(band.centerFrequency),
                                    style: const TextStyle(
                                      color: AppleMusicTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
