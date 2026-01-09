class AppConfig {
  AppConfig({
    required this.provider,
    required this.model,
    required this.transcriptionModel,
    required this.language,
    required this.transcriptStyle,
    required this.multiBucket,
    required this.autoStopSilence,
    required this.silenceSeconds,
    required this.buckets,
    required this.hasApiKey,
  });

  final String provider;
  final String model;
  final String transcriptionModel;
  final String language;
  final String transcriptStyle;
  final bool multiBucket;
  final bool autoStopSilence;
  final int silenceSeconds;
  final List<String> buckets;
  final bool hasApiKey;

  AppConfig copyWith({
    String? provider,
    String? model,
    String? transcriptionModel,
    String? language,
    String? transcriptStyle,
    bool? multiBucket,
    bool? autoStopSilence,
    int? silenceSeconds,
    List<String>? buckets,
    bool? hasApiKey,
  }) {
    return AppConfig(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      transcriptionModel: transcriptionModel ?? this.transcriptionModel,
      language: language ?? this.language,
      transcriptStyle: transcriptStyle ?? this.transcriptStyle,
      multiBucket: multiBucket ?? this.multiBucket,
      autoStopSilence: autoStopSilence ?? this.autoStopSilence,
      silenceSeconds: silenceSeconds ?? this.silenceSeconds,
      buckets: buckets ?? this.buckets,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }

  Map<String, dynamic> toJson({String? encryptedKey}) {
    return {
      'provider': provider,
      'model': model,
      'transcriptionModel': transcriptionModel,
      'language': language,
      'transcriptStyle': transcriptStyle,
      'multiBucket': multiBucket,
      'autoStopSilence': autoStopSilence,
      'silenceSeconds': silenceSeconds,
      'buckets': buckets,
      if (encryptedKey != null) 'apiKey': encryptedKey,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json, {bool hasApiKey = false}) {
    return AppConfig(
      provider: json['provider'] as String? ?? 'OpenAI',
      model: json['model'] as String? ?? 'gpt-5.2',
      transcriptionModel:
          json['transcriptionModel'] as String? ?? 'gpt-4o-mini-transcribe',
      language: json['language'] as String? ?? 'en',
      transcriptStyle: json['transcriptStyle'] as String? ?? 'cleaned',
      multiBucket: json['multiBucket'] as bool? ?? true,
      autoStopSilence: json['autoStopSilence'] as bool? ?? true,
      silenceSeconds: json['silenceSeconds'] as int? ?? 5,
      buckets: (json['buckets'] as List<dynamic>? ?? _defaultBuckets).cast<String>(),
      hasApiKey: hasApiKey,
    );
  }

  static const List<String> _defaultBuckets = [
    'Personal Finance',
    'Mental Health',
    'Physical Health',
    'Project Management',
    'App Ideas',
    'Learning & Research',
    'General'
  ];
}
