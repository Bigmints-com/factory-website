import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/record_controller.dart';
import '../../models/app_config.dart';
import '../../models/note.dart';
import '../note_detail_screen.dart';
import '../../utils/layout.dart';
import 'widgets/note_card.dart';

class MobileHome extends StatelessWidget {
  const MobileHome({
    super.key,
    required this.notes,
    required this.allNotes,
    required this.emptyState,
  });

  final List<Note> notes;
  final List<Note> allNotes;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    // Show empty state inside the list if we have no notes
    // But we always want to show filters and banner.
    // So we treat empty notes as just an empty list in grouping.

    final appController = Get.find<AppController>();
    final isDesktop = context.isDesktop;
    final buckets = appController.config.value.buckets;
    final bucketCounts = <String, int>{'All': allNotes.length};
    for (final bucket in buckets) {
      bucketCounts[bucket] = 0;
    }
    for (final note in allNotes) {
      final bucket = note.bucket;
      bucketCounts[bucket] = (bucketCounts[bucket] ?? 0) + 1;
    }

    // Filter buckets: Always show 'All' and selected, hide others if count is 0
    final entries =
        bucketCounts.entries
            .where(
              (e) =>
                  e.key == 'All' ||
                  e.key == appController.selectedBucket.value ||
                  e.value > 0,
            )
            .toList()
          ..sort((a, b) {
            if (a.key == 'All') return -1;
            if (b.key == 'All') return 1;
            return b.value.compareTo(a.value);
          });

    final groupedNotes = _groupNotes(notes, appController.groupBy.value);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: const _HeroBanner()),
        notes.isEmpty
            ? SliverToBoxAdapter()
            : SliverToBoxAdapter(
                child: Padding(
                  padding: isDesktop
                      ? const EdgeInsets.all(0)
                      : const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;
                        final entry = entries[index];
                        final selected =
                            entry.key == appController.selectedBucket.value;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry.key != 'All') ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppConfig.getBucketColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(entry.key),
                            ],
                          ),
                          selected: selected,
                          onSelected: (_) {
                            appController.selectedBucket.value = entry.key;
                          },
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: selected
                                ? (isDark ? Colors.black : Colors.white)
                                : theme.colorScheme.onSurface,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 12,
                          ),
                          selectedColor: isDark ? Colors.white : Colors.black,
                          backgroundColor: Colors.transparent,
                          shape: const StadiumBorder(
                            side: BorderSide(style: BorderStyle.none),
                          ),
                          side: BorderSide(
                            color: selected
                                ? (isDark ? Colors.white : Colors.black)
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                            width: 1,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
        if (notes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: emptyState,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = groupedNotes[index];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                } else if (item is Note) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NoteCard(
                      note: item,
                      onTap: () => NoteDetailScreen.show(context, item),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }, childCount: groupedNotes.length),
            ),
          ),
      ],
    );
  }

  List<dynamic> _groupNotes(List<Note> notes, String groupBy) {
    if (notes.isEmpty) return [];
    if (groupBy == 'none') return notes;

    final grouped = <String, List<Note>>{};
    for (final note in notes) {
      String key;
      final date = note.createdAt;
      final now = DateTime.now();

      if (groupBy == 'day') {
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          key = 'Today';
        } else if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day - 1) {
          key = 'Yesterday';
        } else {
          key = DateFormat('MMMM d, y').format(date);
        }
      } else if (groupBy == 'week') {
        final diff = now.difference(date).inDays;
        if (diff < 7) {
          key = 'This Week';
        } else if (diff < 14) {
          key = 'Last Week';
        } else {
          key = 'Older';
        }
      } else {
        key = DateFormat('MMMM y').format(date);
      }
      grouped.putIfAbsent(key, () => []).add(note);
    }

    final result = <dynamic>[];
    for (final entry in grouped.entries) {
      result.add(entry.key.toUpperCase());
      result.addAll(entry.value);
    }
    return result;
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final recordController = Get.find<RecordController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 280, // Fixed height for better control over the background logo
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background Styling
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                    : [const Color(0xFF111827), const Color(0xFF1F2937)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),

          // Faded Background Logo
          Positioned(
            right: -40,
            bottom: -40,
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                width: 220,
                height: 220,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'Capture your\nthoughts instantly.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to record a voice note.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      final isRecording = recordController.isRecording.value;
                      return GestureDetector(
                        onTap: recordController.toggleRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isRecording ? Colors.red : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              if (isRecording)
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                isRecording
                                    ? FontAwesomeIcons.stop
                                    : FontAwesomeIcons.microphone,
                                color: isRecording
                                    ? Colors.white
                                    : Colors.black,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRecording ? 'Stop Recording' : 'Record Now',
                                style: TextStyle(
                                  color: isRecording
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
