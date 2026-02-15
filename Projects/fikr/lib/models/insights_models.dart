import 'dart:convert';

class InsightIdeaNote {
  final String title;
  final String snippet;
  final String bucket;
  final List<String> topics;

  const InsightIdeaNote({
    required this.title,
    required this.snippet,
    required this.bucket,
    required this.topics,
  });
}

class FocusArea {
  final String topic;
  final int count;

  const FocusArea({required this.topic, required this.count});
}

class TodoItem {
  final String id;
  final String title;
  final String source;
  final String status;

  const TodoItem({
    required this.id,
    required this.title,
    required this.source,
    required this.status,
  });

  TodoItem copyWith({String? status}) {
    return TodoItem(
      id: id,
      title: title,
      source: source,
      status: status ?? this.status,
    );
  }
}

class InsightHighlight {
  final String title;
  final String detail;
  final String bucket;
  final String icon;
  final List<String> citations;

  const InsightHighlight({
    required this.title,
    required this.detail,
    required this.bucket,
    required this.icon,
    this.citations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'detail': detail,
      'bucket': bucket,
      'icon': icon,
      'citations': citations,
    };
  }

  factory InsightHighlight.fromJson(Map<String, dynamic> json) {
    return InsightHighlight(
      title: json['title'] as String? ?? 'Untitled',
      detail: json['detail'] as String? ?? '',
      bucket: json['bucket'] as String? ?? 'General',
      icon: json['icon'] as String? ?? 'idea',
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class GeneratedInsights {
  final String title;
  final String summary;
  final List<InsightHighlight> highlights;
  final List<String> focus;
  final List<String> nextSteps;
  final List<String> risks;
  final List<String> questions;
  final List<String> workSummaries;

  const GeneratedInsights({
    required this.title,
    required this.summary,
    required this.highlights,
    required this.focus,
    required this.nextSteps,
    required this.risks,
    required this.questions,
    required this.workSummaries,
  });

  factory GeneratedInsights.fromJson(Map<String, dynamic> json) {
    final highlights = (json['highlights'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(InsightHighlight.fromJson)
        .toList();
    return GeneratedInsights(
      title: json['title'] as String? ?? 'Insights',
      summary: json['summary'] as String? ?? '',
      highlights: highlights,
      focus: (json['focus'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      nextSteps: (json['next_steps'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      risks: (json['risks'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      workSummaries: (json['work_summaries'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class InsightEdition {
  final String id;
  final DateTime createdAt;
  final String summary;
  final List<InsightHighlight> highlights;
  final List<String> buckets;

  const InsightEdition({
    required this.id,
    required this.createdAt,
    required this.summary,
    required this.highlights,
    required this.buckets,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'summary': summary,
      'highlights': highlights.map((item) => item.toJson()).toList(),
      'buckets': buckets,
    };
  }

  factory InsightEdition.fromJson(Map<String, dynamic> json) {
    final highlightList = (json['highlights'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(InsightHighlight.fromJson)
        .toList();
    return InsightEdition(
      id: json['id'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      summary: json['summary'] as String? ?? '',
      highlights: highlightList,
      buckets: (json['buckets'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  static List<InsightEdition> listFromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(InsightEdition.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<InsightEdition> editions) {
    return jsonEncode(editions.map((item) => item.toJson()).toList());
  }
}

class LocalInsights {
  final List<String> topWords;
  final List<InsightIdeaNote> ideaNotes;
  final List<FocusArea> focus;
  final List<TodoItem> actions;
  final String editorial;

  const LocalInsights({
    required this.topWords,
    required this.ideaNotes,
    required this.focus,
    required this.actions,
    required this.editorial,
  });
}
