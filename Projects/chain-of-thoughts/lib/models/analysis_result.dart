class AnalysisResult {
  AnalysisResult({
    required this.cleanedText,
    required this.intent,
    required this.topics,
  });

  final String cleanedText;
  final String intent;
  final List<String> topics;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      cleanedText: json['cleanedText'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
