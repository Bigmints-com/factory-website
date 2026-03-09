import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'insights/desktop_insights.dart';
import 'insights/mobile_insights.dart';
import 'insights/widgets/insight_components.dart';

import '../utils/app_typography.dart';
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

          if (!useWideLayout) {
            return MobileInsights(
              mainContent: mainContent,
              controller: controller,
            );
          }

          return DesktopInsights(
            mainContent: mainContent,
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
                Text('Updating Insights', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                Text(
                  status.isNotEmpty ? status : 'Analyzing your thoughts...',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
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
              : const EdgeInsets.all(0),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIGHLIGHTS',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your top 3 topics this week.',
                  style: AppTypography.headlineSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
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
      ],
    );
  }
}
