import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/note.dart';
import 'note_detail_screen.dart';

class NewHomeScreen extends StatelessWidget {
  const NewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Obx(() {
          if (appController.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
            );
          }

          final notes = appController.notes;
          final buckets = appController.config.value.buckets;
          final bucketCounts = <String, int>{'All': notes.length};
          for (final bucket in buckets) {
            bucketCounts[bucket] = 0;
          }
          for (final note in notes) {
            if (note.topics.isEmpty) {
              bucketCounts['General'] = (bucketCounts['General'] ?? 0) + 1;
              continue;
            }
            for (final topic in note.topics) {
              bucketCounts[topic] = (bucketCounts[topic] ?? 0) + 1;
            }
          }

          Widget emptyState = Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x141F1B2E),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1EAFB),
                      border: Border.all(color: const Color(0xFFE6DEFF)),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      size: 32,
                      color: Color(0xFF7B61FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Start your first note',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1B2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the record button to capture ideas, tasks, or a quick thought.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B657A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (!wide) {
            if (notes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: emptyState,
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return _NoteCard(
                    note: note,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NoteDetailScreen(note: note),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          if (notes.isEmpty) {
            return emptyState;
          }

          final gridCount = constraints.maxWidth >= 1200 ? 3 : 2;
          return Row(
            children: [
              _BucketsPanel(bucketCounts: bucketCounts),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1B2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notes.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.15,
                              ),
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return _NoteCard(
                              note: note,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NoteDetailScreen(note: note),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColors = [
      const Color(0xFF7B61FF),
      const Color(0xFFFF9DB5),
      const Color(0xFFFCCB7E),
      const Color(0xFF9BE8D8),
    ];
    final accent = accentColors[note.hashCode % accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B1A2B)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.1))
                : null,
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x141F1B2E),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(isDark ? 0.15 : 0.18),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFF5F1EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('MMM d, h:mm a').format(note.createdAt),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF6B657A),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (note.topics.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            note.topics.first,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.text.isNotEmpty ? note.text : note.transcript,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white : const Color(0xFF1F1B2E),
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

class _BucketsPanel extends StatelessWidget {
  const _BucketsPanel({required this.bucketCounts});

  final Map<String, int> bucketCounts;

  @override
  Widget build(BuildContext context) {
    final entries = bucketCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F6),
        border: Border(right: BorderSide(color: Color(0xFFE7E1DA))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buckets',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1B2E),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: entry.key == 'All'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: entry.key == 'All'
                          ? Border.all(color: const Color(0xFFE7E1DA))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: const Color(0xFF6B657A),
                              fontWeight: entry.key == 'All'
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1B2E),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
