import 'package:flutter/material.dart';
import '../../../controllers/theme_controller.dart';
import '../../../models/app_config.dart';
import '../../../models/insights_models.dart';
import '../../../utils/app_typography.dart';
import '../../../widgets/tag_chip.dart';
import '../top_ideas_detail_screen.dart';
import '../highlights_detail_screen.dart';

class TopIdeasSection extends StatefulWidget {
  const TopIdeasSection({super.key, required this.ideaNotes});
  final List<InsightIdeaNote> ideaNotes;

  @override
  State<TopIdeasSection> createState() => _TopIdeasSectionState();
}

class _TopIdeasSectionState extends State<TopIdeasSection> {
  late final ScrollController _scrollController;
  int _currentPage = 0;
  final double _cardWidth = 280;
  final double _spacing = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final page = (_scrollController.offset / (_cardWidth + _spacing)).round();
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPage(int page) {
    _scrollController.animateTo(
      page * (_cardWidth + _spacing),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ideas = widget.ideaNotes.take(5).toList();
    if (ideas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Highlights',
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    TopIdeasDetailScreen.show(context, widget.ideaNotes),
                child: Text(
                  'See All',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppPalette.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 0
                    ? () => _scrollToPage(_currentPage - 1)
                    : null,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < ideas.length - 1
                    ? () => _scrollToPage(_currentPage + 1)
                    : null,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 24),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: ideas.length,
            separatorBuilder: (context, index) => const SizedBox(width: 0),
            itemBuilder: (context, index) {
              final idea = ideas[index];
              final color = AppConfig.getBucketColor(idea.bucket);

              return SizedBox(
                width: 280,
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppPalette.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                    border: isDark
                        ? Border.all(color: AppPalette.outlineDark, width: 1)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          TopIdeasDetailScreen.show(context, widget.ideaNotes),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TagChip(label: idea.bucket, color: color),
                            const SizedBox(height: 12),
                            Text(
                              idea.title,
                              style: AppTypography.titleLarge.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                idea.snippet,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppPalette.textBodyDark
                                      : AppPalette.textBodyLight,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class HighlightTile extends StatelessWidget {
  const HighlightTile({super.key, required this.item, required this.index});
  final InsightHighlight item;
  final int index;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = AppConfig.getBucketColor(item.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => HighlightsDetailScreen.show(context, [item]),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#$index',
                      style: AppTypography.titleSmall.copyWith(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.bucket.isNotEmpty)
                                  TagChip(label: item.bucket, color: color),
                                const SizedBox(height: 4),
                                Text(
                                  item.title,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.citations.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppPalette.primary,
                              ),
                              onPressed: () => _showCitations(context),
                              tooltip: 'Sources',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.detail,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppPalette.textBodyDark
                              : AppPalette.textBodyLight,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCitations(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sources', style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This insight was formed from these notes:',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...item.citations.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c, style: AppTypography.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
