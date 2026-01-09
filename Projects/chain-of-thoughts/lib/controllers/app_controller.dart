import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/analysis_result.dart';
import '../models/app_config.dart';
import '../models/note.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

class AppController extends GetxController {
  AppController({StorageService? storageService, OpenAIService? openAIService})
    : storage = storageService ?? StorageService(),
      openAI = openAIService ?? OpenAIService();

  final StorageService storage;
  final OpenAIService openAI;
  final AudioPlayer _player = AudioPlayer();

  final Rx<AppConfig> config = AppConfig(
    provider: 'OpenAI',
    model: 'gpt-5.2',
    transcriptionModel: 'gpt-4o-mini-transcribe',
    language: 'en',
    transcriptStyle: 'cleaned',
    multiBucket: true,
    autoStopSilence: true,
    silenceSeconds: 5,
    buckets: const [
      'Personal Finance',
      'Mental Health',
      'Physical Health',
      'Project Management',
      'App Ideas',
      'Learning & Research',
      'General',
    ],
    hasApiKey: false,
  ).obs;

  final RxList<Note> notes = <Note>[].obs;
  final RxBool loading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> initialize() async {
    await storage.init();
    final loadedConfig = await storage.loadConfig();
    config.value = loadedConfig;
    notes.value = (await storage.loadNotes())
        .where((note) => !note.archived)
        .toList();
  }

  Future<void> updateConfig(AppConfig next, {String? apiKey}) async {
    await storage.saveConfig(next, apiKey: apiKey);
    final storedKey = await storage.getApiKey();
    config.value = next.copyWith(
      hasApiKey: storedKey != null && storedKey.isNotEmpty,
    );
    errorMessage.value = '';
  }

  bool isValidApiKeyFormat(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    final basic = RegExp(r'^sk-[A-Za-z0-9]{16,}$');
    final project = RegExp(r'^sk-proj-[A-Za-z0-9]{16,}$');
    return basic.hasMatch(trimmed) || project.hasMatch(trimmed);
  }

  Future<bool> validateAndSaveApiKey(String key) async {
    errorMessage.value = '';
    final trimmed = key.trim();
    if (!isValidApiKeyFormat(trimmed)) {
      errorMessage.value = 'That key does not look like a valid OpenAI key.';
      return false;
    }
    loading.value = true;
    try {
      final ok = await openAI.validateApiKey(trimmed);
      if (!ok) {
        errorMessage.value = 'API key validation failed.';
        return false;
      }
      await updateConfig(config.value, apiKey: trimmed);
      return true;
    } catch (error) {
      errorMessage.value = 'API key validation failed.';
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<void> saveNotes() async {
    await storage.saveNotes(notes.toList());
  }

  Future<void> addNoteFromAudio(File tempAudioFile) async {
    errorMessage.value = '';
    final apiKey = await storage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      errorMessage.value = 'Missing API key.';
      return;
    }
    loading.value = true;
    try {
      final id = const Uuid().v4();
      final timestamp = DateTime.now();
      final audioPath = await _persistAudio(tempAudioFile, id);
      final transcript = await openAI.transcribeAudio(
        audioFile: File(audioPath),
        config: config.value,
        apiKey: apiKey,
      );
      final analysis = await openAI.analyzeTranscript(
        transcript: transcript,
        config: config.value,
        apiKey: apiKey,
      );
      final cleanedText = config.value.transcriptStyle == 'cleaned'
          ? analysis.cleanedText
          : transcript;

      final note = Note(
        id: id,
        createdAt: timestamp,
        updatedAt: timestamp,
        text: cleanedText,
        transcript: transcript,
        intent: analysis.intent,
        topics: _normalizeTopics(analysis),
        audioPath: audioPath,
        archived: false,
      );
      _ensureBuckets(note.topics);
      notes.insert(0, note);
      await saveNotes();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<String> _persistAudio(File tempAudioFile, String id) async {
    final extension = tempAudioFile.path.split('.').last;
    final destination = File('${storage.audioDirPath}/$id.$extension');
    await destination.writeAsBytes(await tempAudioFile.readAsBytes());
    return destination.path;
  }

  List<String> _normalizeTopics(AnalysisResult analysis) {
    if (analysis.topics.isEmpty) return ['General'];
    if (!config.value.multiBucket) return [analysis.topics.first];
    return analysis.topics;
  }

  Future<void> updateNote(Note updated) async {
    final index = notes.indexWhere((note) => note.id == updated.id);
    if (index == -1) return;
    notes[index] = updated;
    await saveNotes();
  }

  Future<void> archiveNote(String id) async {
    final index = notes.indexWhere((note) => note.id == id);
    if (index == -1) return;
    notes[index] = notes[index].copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );
    notes.removeAt(index);
    await saveNotes();
  }

  Future<void> deleteNote(String id) async {
    notes.removeWhere((note) => note.id == id);
    await saveNotes();
  }

  Future<void> playAudio(Note note) async {
    if (note.audioPath == null) return;
    try {
      await _player.setFilePath(note.audioPath!);
      await _player.play();
    } catch (_) {}
  }

  Future<String?> pickExportDirectory() async {
    if (Platform.isMacOS || Platform.isWindows) {
      return getDirectoryPath();
    }
    final docs = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final exportDir = Directory(
      p.join(docs.path, 'voice-to-thoughts', timestamp),
    );
    await exportDir.create(recursive: true);
    return exportDir.path;
  }

  Future<String?> exportAll(String directoryPath) async {
    final allNotes = await storage.loadNotes();
    if (allNotes.isEmpty) return null;
    final exportDir = Directory(directoryPath);
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final txt = _exportNotesContent(allNotes, isMarkdown: false);
    final md = _exportNotesContent(allNotes, isMarkdown: true);

    await File(p.join(exportDir.path, 'notes.txt')).writeAsString(txt);
    await File(p.join(exportDir.path, 'notes.md')).writeAsString(md);
    await File(
      p.join(exportDir.path, 'notes.json'),
    ).writeAsString(Note.listToJson(allNotes));

    final audioOut = Directory(p.join(exportDir.path, 'audio'));
    if (!await audioOut.exists()) {
      await audioOut.create(recursive: true);
    }
    for (final note in allNotes) {
      final audioPath = note.audioPath;
      if (audioPath == null) continue;
      final source = File(audioPath);
      if (!await source.exists()) continue;
      final destination = File(p.join(audioOut.path, p.basename(audioPath)));
      await source.copy(destination.path);
    }

    return exportDir.path;
  }

  Future<void> clearAll() async {
    await storage.clearAll();
    notes.clear();
  }

  void _ensureBuckets(List<String> topics) {
    if (topics.isEmpty) return;
    final existing = Set<String>.from(config.value.buckets);
    final next = [...config.value.buckets];
    for (final topic in topics) {
      if (topic.trim().isEmpty) continue;
      if (!existing.contains(topic)) {
        existing.add(topic);
        next.add(topic);
      }
    }
    if (next.length != config.value.buckets.length) {
      updateConfig(config.value.copyWith(buckets: next));
    }
  }

  String _exportNotesContent(List<Note> notes, {required bool isMarkdown}) {
    final grouped = <String, List<Note>>{};
    for (final note in notes) {
      final topic = note.topics.isNotEmpty ? note.topics.first : 'General';
      grouped.putIfAbsent(topic, () => []).add(note);
    }
    final buffer = StringBuffer();
    final topics = grouped.keys.toList()..sort();
    for (final topic in topics) {
      buffer.writeln(isMarkdown ? '## $topic' : topic.toUpperCase());
      for (final note in grouped[topic]!) {
        final dateLabel = DateFormat.yMMMd().add_jm().format(note.createdAt);
        if (isMarkdown) {
          buffer.writeln('### $dateLabel');
        } else {
          buffer.writeln('[$dateLabel]');
        }
        buffer.writeln(note.text.isNotEmpty ? note.text : note.transcript);
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
