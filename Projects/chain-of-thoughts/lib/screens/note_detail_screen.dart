import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../controllers/app_controller.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  bool _isEditing = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.note.text.isNotEmpty
        ? widget.note.text
        : widget.note.transcript;
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.note.audioPath != null) {
      try {
        await _audioPlayer.setFilePath(widget.note.audioPath!);
        _audioPlayer.durationStream.listen((duration) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        });
        _audioPlayer.positionStream.listen((position) {
          setState(() {
            _position = position;
          });
        });
        _audioPlayer.playerStateStream.listen((state) {
          setState(() {
            _isPlaying = state.playing;
          });
        });
      } catch (e) {
        // Handle audio loading error
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _saveEdit() async {
    final controller = Get.find<AppController>();
    final updated = widget.note.copyWith(
      text: _textController.text,
      updatedAt: DateTime.now(),
    );
    await controller.updateNote(updated);
    setState(() {
      _isEditing = false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7F3F0), Color(0xFFF1EAFB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE3EB).withOpacity(0.7),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x141F1B2E),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1F1B2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Note Detail',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1B2E),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_isEditing) {
                              _saveEdit();
                            } else {
                              setState(() {
                                _isEditing = true;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? const Color(0xFF1F1B2E)
                                  : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _isEditing ? 'Save' : 'Edit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isEditing
                                    ? Colors.white
                                    : const Color(0xFF1F1B2E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF6B657A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'MMMM d, yyyy • h:mm a',
                            ).format(widget.note.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF6B657A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.note.topics.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.note.topics.map((topic) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EAFB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              topic,
                              style: const TextStyle(
                                color: Color(0xFF7B61FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    if (widget.note.audioPath != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x141F1B2E),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _togglePlayback,
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF1EAFB),
                                  border: Border.all(
                                    color: const Color(0xFFE6DEFF),
                                  ),
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 28,
                                  color: const Color(0xFF7B61FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 12,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _position.inSeconds.toDouble(),
                                      max: _duration.inSeconds.toDouble(),
                                      onChanged: (value) async {
                                        await _audioPlayer.seek(
                                          Duration(seconds: value.toInt()),
                                        );
                                      },
                                      activeColor: const Color(0xFF7B61FF),
                                      inactiveColor: const Color(0xFFE9E4EF),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B657A),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B657A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Transcript',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F1B2E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isEditing
                              ? const Color(0xFF7B61FF).withOpacity(0.3)
                              : Colors.transparent,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x141F1B2E),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _isEditing
                          ? TextField(
                              controller: _textController,
                              maxLines: null,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF1F1B2E),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Edit transcription...',
                              ),
                            )
                          : Text(
                              _textController.text,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF1F1B2E),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
