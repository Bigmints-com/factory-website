import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_config.dart';
import '../models/note.dart';

class StorageService {
  StorageService();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late Directory _baseDir;
  late Directory _audioDir;
  late File _notesFile;
  late File _configFile;

  String get audioDirPath => _audioDir.path;

  Future<void> init() async {
    _baseDir = await getApplicationSupportDirectory();
    _audioDir = Directory(p.join(_baseDir.path, 'audio'));
    if (!await _audioDir.exists()) {
      await _audioDir.create(recursive: true);
    }
    _notesFile = File(p.join(_baseDir.path, 'notes.json'));
    _configFile = File(p.join(_baseDir.path, 'config.json'));
  }

  Future<AppConfig> loadConfig() async {
    final hasConfig = await _configFile.exists();
    Map<String, dynamic> data = {};
    if (hasConfig) {
      data = _decodeJson(await _configFile.readAsString());
    }
    final apiKey = await _secureStorage.read(key: 'apiKey');
    return AppConfig.fromJson(data, hasApiKey: apiKey?.isNotEmpty ?? false);
  }

  Future<void> saveConfig(AppConfig config, {String? apiKey}) async {
    if (apiKey != null) {
      if (apiKey.isEmpty) {
        await _secureStorage.delete(key: 'apiKey');
      } else {
        await _secureStorage.write(key: 'apiKey', value: apiKey);
      }
    }
    await _configFile.writeAsString(jsonEncode(config.toJson()));
  }

  Future<String?> getApiKey() => _secureStorage.read(key: 'apiKey');

  Future<List<Note>> loadNotes() async {
    if (!await _notesFile.exists()) {
      return [];
    }
    final raw = await _notesFile.readAsString();
    return Note.listFromJson(raw);
  }

  Future<void> saveNotes(List<Note> notes) async {
    await _notesFile.writeAsString(Note.listToJson(notes));
  }

  Future<void> clearAll() async {
    if (await _notesFile.exists()) {
      await _notesFile.delete();
    }
    if (await _audioDir.exists()) {
      await _audioDir.delete(recursive: true);
    }
    await _audioDir.create(recursive: true);
  }

  Map<String, dynamic> _decodeJson(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
