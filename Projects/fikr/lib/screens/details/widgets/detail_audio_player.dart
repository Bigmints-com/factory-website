import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../note_detail_controller.dart';

class DetailAudioPlayer extends StatelessWidget {
  const DetailAudioPlayer({super.key, required this.controller});

  final NoteDetailController controller;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (controller.note.audioPath == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      final duration = controller.duration.value;
      final position = controller.position.value;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              width: 1,
            ),
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: controller.togglePlayback,
              icon: FaIcon(
                isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                size: 14,
              ),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.05,
                ),
                foregroundColor: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 8,
                      ),
                      activeTrackColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                      inactiveTrackColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.05),
                      thumbColor: theme.colorScheme.onSurface,
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble(),
                      max: duration.inSeconds.toDouble().clamp(
                        0.1,
                        double.infinity,
                      ),
                      onChanged: (value) async {
                        await controller.audioPlayer.seek(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
