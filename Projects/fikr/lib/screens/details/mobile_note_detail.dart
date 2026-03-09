import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:get/get.dart';
import 'note_detail_controller.dart';
import 'widgets/detail_audio_player.dart';
import 'widgets/detail_content.dart';

class MobileNoteDetail extends StatelessWidget {
  const MobileNoteDetail({super.key, required this.controller, this.onClose});

  final NoteDetailController controller;
  final VoidCallback? onClose;

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: 'note-${controller.note.id}',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 44,
          scrolledUnderElevation: 0,
          actions: [
            Obx(
              () => _HeaderButton(
                icon: controller.isEditing.value
                    ? FeatherIcons.check
                    : FeatherIcons.edit2,
                size: 16,
                color: controller.isEditing.value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                onPressed: () {
                  if (controller.isEditing.value) {
                    controller.saveEdit();
                  } else {
                    controller.isEditing.value = true;
                  }
                },
              ),
            ),

            _HeaderButton(
              icon: FeatherIcons.trash2,
              size: 15,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
              onPressed: () async {
                final confirmed = await _showDeleteDialog(context);
                if (confirmed == true) {
                  await controller.deleteNote();
                  if (context.mounted) _close(context);
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailContent(controller: controller),
                      const SizedBox(height: 32),
                      DetailAudioPlayer(controller: controller),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// A compact header icon button with no extra padding.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
