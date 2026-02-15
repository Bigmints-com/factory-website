import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/app_config.dart';
import '../note_detail_controller.dart';

class DetailContent extends StatelessWidget {
  const DetailContent({super.key, required this.controller});

  final NoteDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final topics = controller.topics;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Row
          Row(
            children: [
              Text(
                DateFormat(
                  'MMM d, yyyy',
                ).format(controller.note.createdAt).toUpperCase(),
                style: textTheme.labelSmall,
              ),
              const _Dot(),
              Text(
                DateFormat(
                  'h:mm a',
                ).format(controller.note.createdAt).toUpperCase(),
                style: textTheme.labelSmall,
              ),
              if (topics.isNotEmpty) ...[
                const _Dot(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppConfig.getBucketColor(topics.first),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(topics.first.toUpperCase(), style: textTheme.labelSmall),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // Title Header
          TextField(
            controller: controller.titleController,
            readOnly: !isEditing,
            style: textTheme.headlineMedium,
            decoration: const InputDecoration(
              hintText: 'Note Title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
          ),
          const SizedBox(height: 24),

          // Transcript Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRANSCRIPT', style: textTheme.labelSmall),
              if (!isEditing)
                GestureDetector(
                  onTap: () => controller.isEditing.value = true,
                  child: FaIcon(
                    FontAwesomeIcons.penToSquare,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Area
          if (isEditing)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 16),
              child: TextField(
                controller: controller.textController,
                maxLines: null,
                style: textTheme.bodyLarge,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing your thoughts...',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            )
          else
            Text(
              controller.textController.text.isNotEmpty
                  ? controller.textController.text
                  : 'No content available.',
              style: textTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 48),

          // Tags Area
          if (topics.length > 1) ...[
            Text(
              'TAGS',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.skip(1).map((topic) {
                final color = AppConfig.getBucketColor(topic);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        topic.toLowerCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => controller.removeTag(topic),
                          child: FaIcon(
                            FontAwesomeIcons.xmark,
                            size: 10,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.tagController,
                      decoration: InputDecoration(
                        hintText: 'Add a tag...',
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => controller.addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => controller.addTag(),
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
