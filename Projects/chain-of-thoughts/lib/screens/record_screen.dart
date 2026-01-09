import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../controllers/record_controller.dart';
import 'note_detail_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    final recordController = Get.put(RecordController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All recordings live here. Tap one to refine it or play it back.',
                    style: TextStyle(color: Color(0xFFB8B2C7)),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Obx(() {
                      final notes = appController.notes;
                      if (notes.isEmpty) {
                        return const Center(
                          child: Text(
                            'No recordings yet. Tap the mic to begin.',
                            style: TextStyle(color: Color(0xFFB8B2C7)),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: notes.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _NoteCard(
                            title: note.text.isEmpty ? 'Untitled thought' : note.text,
                            subtitle: DateFormat.yMMMd().add_jm().format(note.createdAt),
                            topics: note.topics,
                            onTap: () => Get.to(
                              () => NoteDetailScreen(note: note),
                            ),
                          );
                        },
                      );
                    }),
                  )
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Obx(() {
                final recording = recordController.isRecording.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: recording
                      ? _RecordingBar(
                          key: const ValueKey('recording'),
                          timer: _formatDuration(recordController.elapsedSeconds.value),
                          onStop: recordController.toggleRecording,
                          level: recordController.visualLevel.value,
                        )
                      : Align(
                          key: const ValueKey('fab'),
                          alignment: Alignment.center,
                          child: _RecordFab(onPressed: recordController.toggleRecording),
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.title,
    required this.subtitle,
    required this.topics,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> topics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141320),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFB8B2C7)),
            ),
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics
                    .map(
                      (topic) => Chip(
                        label: Text(topic),
                        backgroundColor: const Color(0xFFFFB454),
                      ),
                    )
                    .toList(),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _RecordFab extends StatelessWidget {
  const _RecordFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFFB454),
      child: const Icon(Icons.mic, color: Color(0xFF1C0F14)),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    super.key,
    required this.timer,
    required this.onStop,
    required this.level,
  });

  final String timer;
  final VoidCallback onStop;
  final double level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141320),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onStop,
            icon: const Icon(Icons.stop_circle, color: Color(0xFFFF5C6A)),
          ),
          const SizedBox(width: 8),
          Text(
            timer,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(child: _VoiceViz(level: level)),
        ],
      ),
    );
  }
}

class _VoiceViz extends StatelessWidget {
  const _VoiceViz({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final clamped = level.clamp(0.1, 1.0);
    return CustomPaint(
      painter: _VoicePainter(amplitude: clamped),
      size: const Size(double.infinity, 40),
    );
  }
}

class _VoicePainter extends CustomPainter {
  _VoicePainter({required this.amplitude});

  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5EF0B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(0, size.height / 2);
    final path = Path();
    path.moveTo(center.dx, center.dy);

    for (double x = 0; x <= size.width; x += 12) {
      final y = center.dy + (amplitude * 18) * (x % 24 == 0 ? 1 : -1);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VoicePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}
