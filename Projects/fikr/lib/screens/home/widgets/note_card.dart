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

    final textBodyColor = isDark
        ? AppPalette.textBodyDark
        : AppPalette.textBodyLight;
    final textLabelColor = isDark
        ? AppPalette.textLabelDark
        : AppPalette.textLabelLight;

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
                : const [
                    BoxShadow(
                      color: Color(0x0F000000), // rgba(0,0,0,0.06)
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0x0D000000), // rgba(0,0,0,0.05)
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
            border: isDark
                ? Border.all(color: AppPalette.outlineDark, width: 1)
                : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isNotEmpty ? note.title : 'Untitled Note',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: textBodyColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TagChip(label: mainTopic, color: bucketColor),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, y').format(note.createdAt),
                    style: AppTypography.labelSmall.copyWith(
                      color: textLabelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
