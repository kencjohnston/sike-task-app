import 'task_enums.dart';

/// Model representing a search query with filters
class SearchQuery {
  final String text;
  final List<TaskType>? taskTypes;
  final List<int>? priorities;
  final List<TaskContext>? contexts;
  final bool? isCompleted;
  final bool? isRecurring;
  final DateTime timestamp;

  SearchQuery({
    required this.text,
    this.taskTypes,
    this.priorities,
    this.contexts,
    this.isCompleted,
    this.isRecurring,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'taskTypes': taskTypes?.map((t) => t.index).toList(),
      'priorities': priorities,
      'contexts': contexts?.map((c) => c.index).toList(),
      'isCompleted': isCompleted,
      'isRecurring': isRecurring,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SearchQuery.fromJson(Map<String, dynamic> json) {
    return SearchQuery(
      text: json['text'] as String,
      taskTypes: (json['taskTypes'] as List<dynamic>?)
          ?.map((i) => TaskType.values[i as int])
          .toList(),
      priorities:
          (json['priorities'] as List<dynamic>?)?.map((i) => i as int).toList(),
      contexts: (json['contexts'] as List<dynamic>?)
          ?.map((i) => TaskContext.values[i as int])
          .toList(),
      isCompleted: json['isCompleted'] as bool?,
      isRecurring: json['isRecurring'] as bool?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with updated values
  SearchQuery copyWith({
    String? text,
    List<TaskType>? taskTypes,
    List<int>? priorities,
    List<TaskContext>? contexts,
    bool? isCompleted,
    bool? isRecurring,
    DateTime? timestamp,
  }) {
    return SearchQuery(
      text: text ?? this.text,
      taskTypes: taskTypes ?? this.taskTypes,
      priorities: priorities ?? this.priorities,
      contexts: contexts ?? this.contexts,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if any filters are active
  bool get hasFilters {
    return (taskTypes != null && taskTypes!.isNotEmpty) ||
        (priorities != null && priorities!.isNotEmpty) ||
        (contexts != null && contexts!.isNotEmpty) ||
        isCompleted != null ||
        isRecurring != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchQuery &&
        other.text == text &&
        _listEquals(other.taskTypes, taskTypes) &&
        _listEquals(other.priorities, priorities) &&
        _listEquals(other.contexts, contexts) &&
        other.isCompleted == isCompleted &&
        other.isRecurring == isRecurring &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        (taskTypes?.hashCode ?? 0) ^
        (priorities?.hashCode ?? 0) ^
        (contexts?.hashCode ?? 0) ^
        (isCompleted?.hashCode ?? 0) ^
        (isRecurring?.hashCode ?? 0) ^
        timestamp.hashCode;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SearchQuery(text: $text, taskTypes: $taskTypes, priorities: $priorities, contexts: $contexts, isCompleted: $isCompleted, isRecurring: $isRecurring, timestamp: $timestamp)';
  }
}
