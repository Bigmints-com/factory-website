import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/theme_controller.dart';
import '../../../models/app_config.dart';
import '../../../models/note.dart';
import '../../../utils/app_typography.dart';
import '../../../widgets/tag_chip.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainTopic = note.bucket;
    final bucketColor = AppConfig.getBucketColor(mainTopic);

    final textBodyColor =
        isDark ? AppPalette.textBodyDark : AppPalette.textBodyLight;
    final textLabelColor =
        isDark ? AppPalette.textLabelDark : AppPalette.textLabelLight;

    return Hero(
      tag: 'note-${note.id}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppPalette.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
            border: isDark
                ? Border.all(color: AppPalette.outlineDark, width: 1)
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TagChip(label: mainTopic, color: bucketColor),
              const SizedBox(height: 12),
              Text(
                note.title.isNotEmpty ? note.title : 'Untitled Note',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, y').format(note.createdAt).toUpperCase(),
                style: AppTypography.labelSmall.copyWith(color: textLabelColor),
              ),
              const SizedBox(height: 16),
              Text(
                note.snippet,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: textBodyColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
