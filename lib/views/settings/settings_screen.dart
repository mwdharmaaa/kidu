import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_manager.dart';
import '../../theme/qidu_theme.dart';
import '../equalizer/equalizer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AudioPlayerManager>();

    return Scaffold(
      backgroundColor: QiduTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          "Settings",
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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section 1: Audio Quality & Lossless
          _buildSectionHeader("AUDIO QUALITY"),
          Container(
            decoration: BoxDecoration(
              color: QiduTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    "Lossless Audio",
                    style: TextStyle(
                      color: QiduTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    "Preserves original studio audio data bit-for-bit",
                    style: TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: CupertinoSwitch(
                    value: manager.qualityTier != AudioQualityTier.highQuality,
                    activeColor: QiduTheme.accentColor,
                    onChanged: (val) {
                      manager.setQualityTier(
                        val ? AudioQualityTier.hiResLossless : AudioQualityTier.highQuality,
                      );
                    },
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.06), height: 1),
                ListTile(
                  title: const Text(
                    "Maximum Quality Resolution",
                    style: TextStyle(color: QiduTheme.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    manager.qualityTier == AudioQualityTier.hiResLossless
                        ? "Hi-Res Lossless (Up to 24-bit/192 kHz)"
                        : manager.qualityTier == AudioQualityTier.lossless
                            ? "Lossless (Up to 24-bit/48 kHz)"
                            : "High Quality (AAC 256 kbps)",
                    style: const TextStyle(color: QiduTheme.hiResGold, fontSize: 12),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.chevron_forward,
                    color: QiduTheme.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _showQualityTierPicker(context, manager),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Audio Playback & Sound Check
          _buildSectionHeader("AUDIO PROCESSING"),
          Container(
            decoration: BoxDecoration(
              color: QiduTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                // Sound Check (Volume Normalization)
                ListTile(
                  title: const Text(
                    "Sound Check",
                    style: TextStyle(
                      color: QiduTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    "Normalizes volume levels across different songs",
                    style: TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: CupertinoSwitch(
                    value: manager.isSoundCheckEnabled,
                    activeColor: QiduTheme.accentColor,
                    onChanged: (val) => manager.setSoundCheck(val),
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.06), height: 1),

                // Crossfade
                ListTile(
                  title: const Text(
                    "Crossfade",
                    style: TextStyle(
                      color: QiduTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    manager.isCrossfadeEnabled
                        ? "${manager.crossfadeSeconds}s smooth transition between tracks"
                        : "Disabled",
                    style: const TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: CupertinoSwitch(
                    value: manager.isCrossfadeEnabled,
                    activeColor: QiduTheme.accentColor,
                    onChanged: (val) => manager.setCrossfade(val),
                  ),
                ),
                if (manager.isCrossfadeEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text("1s", style: TextStyle(color: QiduTheme.textSecondary, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            min: 1,
                            max: 12,
                            divisions: 11,
                            value: manager.crossfadeSeconds.toDouble(),
                            activeColor: QiduTheme.accentColor,
                            onChanged: (val) => manager.setCrossfade(true, val.toInt()),
                          ),
                        ),
                        const Text("12s", style: TextStyle(color: QiduTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
                Divider(color: Colors.white.withOpacity(0.06), height: 1),

                // Gapless Playback
                ListTile(
                  title: const Text(
                    "Gapless Playback",
                    style: TextStyle(
                      color: QiduTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    "Eliminates silence between live or concept album tracks",
                    style: TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: CupertinoSwitch(
                    value: manager.isGaplessPlaybackEnabled,
                    activeColor: QiduTheme.accentColor,
                    onChanged: (val) => manager.setGaplessPlayback(val),
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.06), height: 1),

                // Equalizer Shortcut
                ListTile(
                  title: const Text(
                    "Equalizer",
                    style: TextStyle(
                      color: QiduTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Preset: ${manager.currentPresetName}",
                    style: const TextStyle(color: QiduTheme.accentColor, fontSize: 12),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.chevron_forward,
                    color: QiduTheme.textSecondary,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Sleep Timer
          _buildSectionHeader("SLEEP TIMER"),
          Container(
            decoration: BoxDecoration(
              color: QiduTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: ListTile(
              title: const Text(
                "Stop Playing After",
                style: TextStyle(
                  color: QiduTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                manager.sleepTimerAtEndOfTrack
                    ? "At End of Current Track"
                    : manager.sleepTimerEndTime != null
                        ? "Active until ${_formatTime(manager.sleepTimerEndTime!)}"
                        : "Off",
                style: TextStyle(
                  color: (manager.sleepTimerEndTime != null || manager.sleepTimerAtEndOfTrack)
                      ? QiduTheme.accentColor
                      : QiduTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                CupertinoIcons.chevron_forward,
                color: QiduTheme.textSecondary,
                size: 18,
              ),
              onTap: () => _showSleepTimerPicker(context, manager),
            ),
          ),

          const SizedBox(height: 32),

          // About Section
          Center(
            child: Column(
              children: [
                const Text(
                  "Qidu Audio",
                  style: TextStyle(
                    color: QiduTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Version 1.0.0 • Studio Lossless Player",
                  style: TextStyle(
                    color: QiduTheme.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: QiduTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  void _showQualityTierPicker(BuildContext context, AudioPlayerManager manager) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Audio Quality Tier"),
        message: const Text("Select maximum lossless decoding resolution"),
        actions: [
          CupertinoActionSheetAction(
            child: const Text("Hi-Res Lossless (Up to 24-bit/192 kHz)"),
            onPressed: () {
              manager.setQualityTier(AudioQualityTier.hiResLossless);
              Navigator.pop(ctx);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text("Lossless (Up to 24-bit/48 kHz)"),
            onPressed: () {
              manager.setQualityTier(AudioQualityTier.lossless);
              Navigator.pop(ctx);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text("High Quality (AAC 256 kbps)"),
            onPressed: () {
              manager.setQualityTier(AudioQualityTier.highQuality);
              Navigator.pop(ctx);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _showSleepTimerPicker(BuildContext context, AudioPlayerManager manager) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Sleep Timer"),
        message: const Text("Stop audio playback automatically"),
        actions: [
          CupertinoActionSheetAction(
            child: const Text("15 Minutes"),
            onPressed: () {
              manager.setSleepTimer(const Duration(minutes: 15));
              Navigator.pop(ctx);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text("30 Minutes"),
            onPressed: () {
              manager.setSleepTimer(const Duration(minutes: 30));
              Navigator.pop(ctx);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text("1 Hour"),
            onPressed: () {
              manager.setSleepTimer(const Duration(hours: 1));
              Navigator.pop(ctx);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text("At End of Current Track"),
            onPressed: () {
              manager.setSleepTimer(null, endOfTrack: true);
              Navigator.pop(ctx);
            },
          ),
          if (manager.sleepTimerEndTime != null || manager.sleepTimerAtEndOfTrack)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text("Turn Off Timer"),
              onPressed: () {
                manager.cancelSleepTimer();
                Navigator.pop(ctx);
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}
