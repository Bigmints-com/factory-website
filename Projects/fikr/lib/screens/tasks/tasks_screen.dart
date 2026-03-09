import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import '../../utils/app_typography.dart';
import '../../widgets/task_tile.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, this.embedded = true});

  /// When true, rendered as a tab body (no Scaffold/AppBar).
  /// When false, rendered as a pushed screen with its own AppBar.
  final bool embedded;

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TasksScreen(embedded: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _TasksContent();
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks'), elevation: 0),
      body: content,
    );
  }
}

class _TasksContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final theme = Theme.of(context);

    return Obx(() {
      final activeItems = controller.todoItems
          .where((t) => !t.isCompleted)
          .toList();
      final completedItems = controller.todoItems
          .where((t) => t.isCompleted)
          .toList();

      if (controller.todoItems.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: AppTypography.headlineSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record a note and Fikr will find\nyour to-dos automatically.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          if (activeItems.isNotEmpty) ...[
            ...activeItems.map(
              (todo) => TaskTile(
                todo: todo,
                onToggle: () => controller.toggleTaskComplete(todo.id),
                showDate: true,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'All tasks completed! 🎉',
                  style: AppTypography.titleMedium.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          if (completedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CompletedSection(
              items: completedItems,
              onToggle: controller.toggleTaskComplete,
            ),
          ],
          const SizedBox(height: 100),
        ],
      );
    });
  }
}

class _CompletedSection extends StatefulWidget {
  const _CompletedSection({required this.items, required this.onToggle});
  final List items;
  final Function(String) onToggle;

  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed (${widget.items.length})',
                  style: AppTypography.titleSmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map(
            (todo) => TaskTile(
              todo: todo,
              onToggle: () => widget.onToggle(todo.id),
              showDate: true,
            ),
          ),
      ],
    );
  }
}
