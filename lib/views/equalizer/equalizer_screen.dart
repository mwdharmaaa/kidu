import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/qidu_theme.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  String _formatFreq(double hz) {
    if (hz >= 1000) {
      return "${(hz / 1000).toStringAsFixed(1).replaceAll('.0', '')} kHz";
    }
    return "${hz.toInt()} Hz";
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();
    final minDb = manager.minDecibels;
    final maxDb = manager.maxDecibels;
    final bands = manager.bands;
    const presets = AudioPlayerManager.defaultPresets;

    return Scaffold(
      backgroundColor: QiduTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          "Equalizer",
          style: TextStyle(
            color: QiduTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: QiduTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => manager.resetToFlat(),
            child: const Text(
              "Reset",
              style: TextStyle(
                color: QiduTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Equalizer Enable/Disable Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: QiduTheme.cardDark,
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
                        color: QiduTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Studio Hardware Signal Processing",
                      style: TextStyle(
                        color: QiduTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                CupertinoSwitch(
                  value: manager.isEqualizerEnabled,
                  activeColor: QiduTheme.accentColor,
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
                color: QiduTheme.textSecondary,
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
                  selectedColor: QiduTheme.accentColor,
                  backgroundColor: QiduTheme.cardDark,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : QiduTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? QiduTheme.accentColor
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
                color: QiduTheme.textSecondary,
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
              color: QiduTheme.cardDark,
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
                        color: QiduTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      "0 dB",
                      style: TextStyle(
                        color: QiduTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${minDb.toInt()} dB",
                      style: const TextStyle(
                        color: QiduTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Sliders Row - 0ms Instant Response
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: bands.asMap().entries.map((entry) {
                      final bandIndex = entry.key;
                      final band = entry.value;
                      final currentGain = band.gain.clamp(minDb, maxDb);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gain readout
                          Text(
                            "${currentGain >= 0 ? '+' : ''}${currentGain.toStringAsFixed(1)}",
                            style: TextStyle(
                              color: currentGain != 0.0
                                  ? QiduTheme.accentColor
                                  : QiduTheme.textSecondary,
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
                                  activeTrackColor: QiduTheme.accentColor,
                                  inactiveTrackColor:
                                      QiduTheme.sliderTrackInactive,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
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
                              color: QiduTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
