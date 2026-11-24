import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../services/audio_player_manager.dart';
import '../../../theme/qidu_theme.dart';

class MetadataEditorDialog extends StatefulWidget {
  final SongModel song;

  const MetadataEditorDialog({super.key, required this.song});

  @override
  State<MetadataEditorDialog> createState() => _MetadataEditorDialogState();
}

class _MetadataEditorDialogState extends State<MetadataEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;

  @override
  void initState() {
    super.initState();
    final manager = context.read<AudioPlayerManager>();
    _titleController = TextEditingController(text: manager.getSongTitle(widget.song));
    _artistController = TextEditingController(text: manager.getSongArtist(widget.song));
    _albumController = TextEditingController(text: manager.getSongAlbum(widget.song));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: QiduTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white60, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.read<AudioPlayerManager>();

    return AlertDialog(
      backgroundColor: QiduTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: QiduTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.pencil, color: QiduTheme.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "Edit Info Lagu",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ubah judul dan artis agar daftar lagu Anda rapi seperti katalog Apple Music:",
              style: TextStyle(color: QiduTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildField(
              label: "Judul Lagu",
              controller: _titleController,
              icon: CupertinoIcons.music_note,
            ),
            _buildField(
              label: "Nama Artis / Penyanyi",
              controller: _artistController,
              icon: CupertinoIcons.person,
            ),
            _buildField(
              label: "Nama Album",
              controller: _albumController,
              icon: CupertinoIcons.square_stack_3d_down_right,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Batal", style: TextStyle(color: QiduTheme.textSecondary)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: QiduTheme.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Simpan"),
          onPressed: () async {
            await manager.updateSongMetadata(
              widget.song.id,
              title: _titleController.text,
              artist: _artistController.text,
              album: _albumController.text,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Info lagu berhasil diperbarui!"),
                  backgroundColor: QiduTheme.cardLighter,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
