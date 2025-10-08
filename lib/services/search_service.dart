import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/search_query.dart';

/// Service for searching tasks and managing search history
class SearchService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  final SharedPreferences _prefs;

  SearchService(this._prefs);

  /// Basic full-text search across task title, notes (description), and tags
  /// Returns results sorted by relevance (exact title match > partial title > notes)
  List<Task> searchTasks(String query, List<Task> tasks) {
    if (query.trim().isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase().trim();
    final results = <Task, int>{};

    for (final task in tasks) {
      int relevanceScore = 0;

      // Check title
      final lowerTitle = task.title.toLowerCase();
      if (lowerTitle == lowerQuery) {
        relevanceScore = 1000; // Exact match - highest priority
      } else if (lowerTitle.contains(lowerQuery)) {
        relevanceScore = 500; // Partial match in title
      }

      // Check description/notes
      if (task.description != null) {
        final lowerDesc = task.description!.toLowerCase();
        if (lowerDesc.contains(lowerQuery)) {
          relevanceScore += 100; // Match in description
        }
      }

      // Add task to results if any match found
      if (relevanceScore > 0) {
        results[task] = relevanceScore;
      }
    }

    // Sort by relevance score (descending)
    final sortedTasks = results.keys.toList()
      ..sort((a, b) => results[b]!.compareTo(results[a]!));

    return sortedTasks;
  }

  /// Advanced search with multiple filters
  /// All filters use AND logic - tasks must match all specified criteria
  List<Task> searchWithFilters({
    String? text,
    List<TaskType>? taskTypes,
    List<int>? priorities,
    List<TaskContext>? contexts,
    bool? isCompleted,
    bool? isRecurring,
    required List<Task> tasks,
  }) {
    var results = List<Task>.from(tasks);

    // Apply text search first if provided
    if (text != null && text.trim().isNotEmpty) {
      results = searchTasks(text, results);
    }

    // Apply task type filter
    if (taskTypes != null && taskTypes.isNotEmpty) {
      results =
          results.where((task) => taskTypes.contains(task.taskType)).toList();
    }

    // Apply priority filter (0=low, 1=medium, 2=high)
    if (priorities != null && priorities.isNotEmpty) {
      results =
          results.where((task) => priorities.contains(task.priority)).toList();
    }

    // Apply context filter
    if (contexts != null && contexts.isNotEmpty) {
      results =
          results.where((task) => contexts.contains(task.taskContext)).toList();
    }

    // Apply completion status filter
    if (isCompleted != null) {
      results =
          results.where((task) => task.isCompleted == isCompleted).toList();
    }

    // Apply recurring filter
    if (isRecurring != null) {
      results =
          results.where((task) => task.isRecurring == isRecurring).toList();
    }

    return results;
  }

  /// Save a search query to history
  /// Maintains max 10 recent searches
  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final searches = await getRecentSearches();

    // Remove if already exists (to move to front)
    searches
        .removeWhere((q) => q.text.toLowerCase() == query.toLowerCase().trim());

    // Add to front
    searches.insert(
        0,
        SearchQuery(
          text: query.trim(),
          timestamp: DateTime.now(),
        ));

    // Limit to max recent searches
    if (searches.length > _maxRecentSearches) {
      searches.removeRange(_maxRecentSearches, searches.length);
    }

    // Save to preferences
    final jsonList = searches.map((q) => q.toJson()).toList();
    await _prefs.setString(_recentSearchesKey, json.encode(jsonList));
  }

  /// Get recent searches from history
  Future<List<SearchQuery>> getRecentSearches({int limit = 10}) async {
    final jsonString = _prefs.getString(_recentSearchesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final searches = jsonList
          .map((json) => SearchQuery.fromJson(json as Map<String, dynamic>))
          .take(limit)
          .toList();
      return searches;
    } catch (e) {
      // If there's an error parsing, clear the corrupted data
      await clearSearchHistory();
      return [];
    }
  }

  /// Clear all search history
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_recentSearchesKey);
  }
}
