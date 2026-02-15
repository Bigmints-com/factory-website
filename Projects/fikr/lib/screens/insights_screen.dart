import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'insights/desktop_insights.dart';
import 'insights/mobile_insights.dart';
import 'insights/widgets/insight_components.dart';

import '../utils/layout.dart';

import '../controllers/app_controller.dart';
import '../models/insights_models.dart';
import '../widgets/empty_state.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.isDesktop;
        final isTablet = constraints.isTablet;
        final useWideLayout = isDesktop || isTablet;
        return Obx(() {
          if (controller.insightsUpdating.value) {
            return _InsightUpdateCard(
              status: controller.insightsUpdateStatus.value,
            );
          }

          if (controller.notes.isEmpty) {
            return const EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'Your intellectual journey awaits',
              description:
                  'Every profound realization begins with a single thought. Record your first note and watch your tapestry of wisdom unfold.',
            );
          }

          if (controller.notes.length < 5) {
            return EmptyState(
              icon: Icons.eco_outlined,
              title: 'Gathering the seeds of wisdom',
              description:
                  'You\'ve started something beautiful. Capture at least 5 notes (${controller.notes.length}/5) to help our AI begin weaving your thoughts into meaningful patterns and insights.',
            );
          }

          final localInsights = controller.buildLocalInsights(controller.notes);
          final generated = controller.generatedInsights.value;

          if (generated == null && localInsights.ideaNotes.isEmpty) {
            return EmptyState(
              icon: Icons.insights_outlined,
              title: 'Let your thoughts talk to each other',
              description:
                  'Your mind has been busy. Let our AI uncover the beautiful connections between your ideas and reveal the wisdom you\'ve already captured.',
              action: FilledButton.icon(
                onPressed: () => controller.captureInsightsEdition(),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Discover My Insights'),
              ),
            );
          }

          final ideaNotes = localInsights.ideaNotes;
          final highlightFallback = ideaNotes.take(3).toList();
          final highlightItems =
              generated?.highlights.take(3).toList() ?? <InsightHighlight>[];

          final mainContent = _InsightsMainContent(
            localInsights: localInsights,
            generatedInsights: generated,
            ideaNotes: ideaNotes,
            highlightFallback: highlightFallback,
            highlightItems: highlightItems,
            selectedBuckets: controller.selectedInsightBuckets,
            isDesktop: useWideLayout,
          );

          final todoPanel = _TodoPanel(
            todoItems: controller.todoItems,
            onCycle: controller.cycleTodoStatus,
          );

          if (!useWideLayout) {
            return MobileInsights(
              mainContent: mainContent,
              todoPanel: todoPanel,
              controller: controller,
            );
          }

          return DesktopInsights(
            mainContent: mainContent,
            todoPanel: todoPanel,
            controller: controller,
          );
        });
      },
    );
  }
}

class _InsightUpdateCard extends StatelessWidget {
  const _InsightUpdateCard({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Updating Insights',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  status.isNotEmpty ? status : 'Analyzing your thoughts...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsMainContent extends StatelessWidget {
  const _InsightsMainContent({
    required this.localInsights,
    required this.generatedInsights,
    required this.ideaNotes,
    required this.highlightFallback,
    required this.highlightItems,
    required this.selectedBuckets,
    required this.isDesktop,
  });

  final LocalInsights localInsights;
  final GeneratedInsights? generatedInsights;
  final List<InsightIdeaNote> ideaNotes;
  final List<InsightIdeaNote> highlightFallback;
  final List<InsightHighlight> highlightItems;
  final List<String> selectedBuckets;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TopIdeasSection(ideaNotes: ideaNotes),
        SizedBox(height: isDesktop ? 24 : 0),
        Padding(
          padding: isDesktop
              ? const EdgeInsets.all(0)
              : const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HIGHLIGHTS', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Three things you talked about the most.',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    generatedInsights?.summary.isNotEmpty == true
                        ? generatedInsights!.summary
                        : localInsights.editorial,
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),
                  if (highlightItems.isNotEmpty)
                    ...highlightItems.asMap().entries.map(
                      (e) => HighlightTile(item: e.value, index: e.key + 1),
                    )
                  else if (highlightFallback.isNotEmpty)
                    ...highlightFallback.asMap().entries.map(
                      (e) => HighlightTile(
                        item: InsightHighlight(
                          title: e.value.title,
                          detail: e.value.snippet,
                          icon: 'idea',
                          bucket: '',
                        ),
                        index: e.key + 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodoPanel extends StatelessWidget {
  const _TodoPanel({required this.todoItems, required this.onCycle});
  final List<TodoItem> todoItems;
  final Function(String) onCycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeItems = todoItems.where((t) => t.status != 'done').toList();
    final completedItems = todoItems.where((t) => t.status == 'done').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.listCheck, size: 16),
                const SizedBox(width: 12),
                Text('Tasks', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (completedItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        _showCompletedTasks(context, completedItems),
                    icon: const Icon(Icons.history, size: 16),
                    label: Text(
                      '${completedItems.length} Completed',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 32,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No pending tasks. Great job!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeItems.map(
                (todo) => CheckboxListTile(
                  value: false,
                  title: Text(todo.title),
                  subtitle: Text(
                    todo.source,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  onChanged: (_) => onCycle(todo.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCompletedTasks(BuildContext context, List<TodoItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CompletedTasksModal(items: items, onCycle: onCycle),
    );
  }
}

class _CompletedTasksModal extends StatelessWidget {
  const _CompletedTasksModal({required this.items, required this.onCycle});
  final List<TodoItem> items;
  final Function(String) onCycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Completed Tasks', style: theme.textTheme.titleMedium),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final todo = items[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    todo.title,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    todo.source,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      onCycle(todo.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Reopen'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
