import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Map<String, int> _bucketCounts(AppController controller) {
    final buckets = controller.config.value.buckets;
    final counts = <String, int>{};
    for (final bucket in buckets) {
      counts[bucket] = 0;
    }
    for (final note in controller.notes) {
      if (note.topics.isEmpty) {
        counts['General'] = (counts['General'] ?? 0) + 1;
        continue;
      }
      for (final topic in note.topics) {
        counts[topic] = (counts[topic] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Obx(() {
            final counts = _bucketCounts(controller);
            final buckets = counts.keys.toList();
            final totalNotes = controller.notes.length;
            final totalBuckets = buckets.length;

            Widget grid = GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buckets.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                final bucket = buckets[index];
                final count = counts[bucket] ?? 0;
                return _InsightCard(
                  title: bucket,
                  count: count,
                );
              },
            );

            if (!wide) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewCard(
                      totalNotes: totalNotes,
                      totalBuckets: totalBuckets,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Buckets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1B2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    grid,
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      _OverviewCard(
                        totalNotes: totalNotes,
                        totalBuckets: totalBuckets,
                      ),
                      const SizedBox(height: 16),
                      _BucketListCard(counts: counts),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bucket Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1B2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        grid,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.totalNotes,
    required this.totalBuckets,
  });

  final int totalNotes;
  final int totalBuckets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E1DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141F1B2E),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(label: 'Notes', value: totalNotes.toString()),
              const SizedBox(width: 12),
              _MetricChip(label: 'Buckets', value: totalBuckets.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _BucketListCard extends StatelessWidget {
  const _BucketListCard({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E1DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141F1B2E),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Buckets',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Color(0xFF6B657A)),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1B2E),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B657A),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E1DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141F1B2E),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const Spacer(),
          Text(
            '$count notes',
            style: const TextStyle(
              color: Color(0xFF6B657A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
