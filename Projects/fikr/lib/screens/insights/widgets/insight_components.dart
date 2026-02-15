import 'package:flutter/material.dart';
import '../../../models/app_config.dart';
import '../../../models/insights_models.dart';
import '../../../utils/layout.dart';
import '../../../widgets/tag_chip.dart';

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
    final ideas = widget.ideaNotes.take(5).toList();
    final isDesktop = isDesktopWidth(context);
    final isTablet = isTabletWidth(context);
    if (ideas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: isDesktop || isTablet
          ? const EdgeInsets.all(0)
          : const EdgeInsets.all(16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Top Ideas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
            const SizedBox(height: 0),
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
                  final isDark = theme.brightness == Brightness.dark;
                  return SizedBox(
                    width: 280,
                    child: Card(
                      color: color.withValues(alpha: isDark ? 0.08 : 0.4),
                      margin: const EdgeInsets.only(left: 16, right: 0),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: color, width: 4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TagChip(label: idea.bucket, color: color),
                              const SizedBox(height: 12),
                              Text(
                                idea.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                idea.snippet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
        ),
      ),
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
    final color = AppConfig.getBucketColor(item.title);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                              TagChip(label: item.bucket, color: color),
                              Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () => _showCitations(context),
                            tooltip: 'Sources',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          title: const Text('Sources'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This insight was formed from these notes:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...item.citations.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c, style: const TextStyle(fontSize: 13)),
                      ),
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
