import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/search_service.dart';

void main() {
  group('SearchService', () {
    late SearchService searchService;
    late List<Task> testTasks;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      searchService = SearchService(prefs);

      // Create test tasks
      final now = DateTime.now();
      testTasks = [
        Task(
          id: '1',
          title: 'Buy groceries',
          description: 'Get milk and bread from the store',
          createdAt: now,
          updatedAt: now,
          priority: 1,
        ),
        Task(
          id: '2',
          title: 'Write report',
          description: 'Complete the quarterly report',
          createdAt: now,
          updatedAt: now,
          priority: 2,
          taskType: TaskType.administrative,
        ),
        Task(
          id: '3',
          title: 'Fix bug in login',
          description: 'Debug authentication issue',
          createdAt: now,
          updatedAt: now,
          priority: 2,
          taskType: TaskType.technical,
        ),
        Task(
          id: '4',
          title: 'Design new logo',
          description: 'Create a modern logo design',
          createdAt: now,
          updatedAt: now,
          priority: 0,
          taskType: TaskType.creative,
        ),
        Task(
          id: '5',
          title: 'Call client',
          description: 'Discuss project requirements',
          createdAt: now,
          updatedAt: now,
          priority: 1,
          taskType: TaskType.communication,
          isCompleted: true,
        ),
      ];
    });

    group('Basic Search', () {
      test('searches by title', () {
        final results = searchService.searchTasks('groceries', testTasks);
        expect(results.length, 1);
        expect(results[0].title, 'Buy groceries');
      });

      test('searches by description', () {
        final results = searchService.searchTasks('quarterly', testTasks);
        expect(results.length, 1);
        expect(results[0].title, 'Write report');
      });

      test('is case-insensitive', () {
        final results1 = searchService.searchTasks('GROCERIES', testTasks);
        final results2 = searchService.searchTasks('groceries', testTasks);
        final results3 = searchService.searchTasks('GrOcErIeS', testTasks);

        expect(results1.length, 1);
        expect(results2.length, 1);
        expect(results3.length, 1);
        expect(results1[0].id, results2[0].id);
        expect(results2[0].id, results3[0].id);
      });

      test('performs partial word matching', () {
        final results = searchService.searchTasks('repo', testTasks);
        expect(results.length, 1);
        expect(results[0].title, 'Write report');
      });

      test('returns empty list for no matches', () {
        final results = searchService.searchTasks('nonexistent', testTasks);
        expect(results, isEmpty);
      });

      test('returns empty list for empty query', () {
        final results = searchService.searchTasks('', testTasks);
        expect(results, isEmpty);
      });

      test('returns empty list for whitespace query', () {
        final results = searchService.searchTasks('   ', testTasks);
        expect(results, isEmpty);
      });
    });

    group('Search Relevance', () {
      test('prioritizes exact title matches', () {
        final results = searchService.searchTasks('report', testTasks);
        expect(results.isNotEmpty, true);
        // Exact match in title should come before description match
        expect(results[0].title, contains('report'));
      });

      test('ranks title matches higher than description matches', () {
        final now = DateTime.now();
        final tasks = [
          Task(
            id: '1',
            title: 'Test document',
            description: 'Some text',
            createdAt: now,
            updatedAt: now,
          ),
          Task(
            id: '2',
            title: 'Other task',
            description: 'Test content here',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final results = searchService.searchTasks('test', tasks);
        expect(results.length, 2);
        // Task with 'test' in title should come first
        expect(results[0].title, 'Test document');
      });
    });

    group('Advanced Filtering', () {
      test('filters by task type', () {
        final results = searchService.searchWithFilters(
          taskTypes: [TaskType.technical],
          tasks: testTasks,
        );
        expect(results.length, 1);
        expect(results[0].taskType, TaskType.technical);
      });

      test('filters by multiple task types', () {
        final results = searchService.searchWithFilters(
          taskTypes: [TaskType.technical, TaskType.creative],
          tasks: testTasks,
        );
        expect(results.length, 2);
        expect(
          results.every(
            (t) =>
                t.taskType == TaskType.technical ||
                t.taskType == TaskType.creative,
          ),
          true,
        );
      });

      test('filters by priority', () {
        final results = searchService.searchWithFilters(
          priorities: [2],
          tasks: testTasks,
        );
        expect(results.length, 2);
        expect(results.every((t) => t.priority == 2), true);
      });

      test('filters by multiple priorities', () {
        final results = searchService.searchWithFilters(
          priorities: [0, 1],
          tasks: testTasks,
        );
        expect(results.length, 3);
        expect(results.every((t) => t.priority == 0 || t.priority == 1), true);
      });

      test('filters by context', () {
        final now = DateTime.now();
        final tasks = [
          Task(
            id: '1',
            title: 'Home task',
            createdAt: now,
            updatedAt: now,
            taskContext: TaskContext.home,
          ),
          Task(
            id: '2',
            title: 'Office task',
            createdAt: now,
            updatedAt: now,
            taskContext: TaskContext.office,
          ),
        ];

        final results = searchService.searchWithFilters(
          contexts: [TaskContext.home],
          tasks: tasks,
        );
        expect(results.length, 1);
        expect(results[0].taskContext, TaskContext.home);
      });

      test('filters by completion status', () {
        final results = searchService.searchWithFilters(
          isCompleted: true,
          tasks: testTasks,
        );
        expect(results.length, 1);
        expect(results[0].isCompleted, true);
      });

      test('filters by recurring status', () {
        final now = DateTime.now();
        final tasks = List<Task>.from(testTasks);
        tasks.add(Task(
          id: '6',
          title: 'Weekly meeting',
          createdAt: now,
          updatedAt: now,
          dueDate: now,
          recurrenceRule: RecurrenceRule(
            pattern: RecurrencePattern.weekly,
          ),
        ));

        final results = searchService.searchWithFilters(
          isRecurring: true,
          tasks: tasks,
        );
        expect(results.length, 1);
        expect(results[0].isRecurring, true);
      });

      test('combines text search with filters', () {
        final results = searchService.searchWithFilters(
          text: 'report',
          taskTypes: [TaskType.administrative],
          tasks: testTasks,
        );
        expect(results.length, 1);
        expect(results[0].title, 'Write report');
        expect(results[0].taskType, TaskType.administrative);
      });

      test('combines multiple filters (AND logic)', () {
        final results = searchService.searchWithFilters(
          priorities: [2],
          taskTypes: [TaskType.technical],
          tasks: testTasks,
        );
        expect(results.length, 1);
        expect(results[0].title, 'Fix bug in login');
      });

      test('returns empty when no tasks match all filters', () {
        final results = searchService.searchWithFilters(
          priorities: [2],
          taskTypes: [TaskType.creative],
          tasks: testTasks,
        );
        expect(results, isEmpty);
      });
    });

    group('Recent Search History', () {
      test('saves recent search', () async {
        await searchService.saveRecentSearch('test query');
        final searches = await searchService.getRecentSearches();
        expect(searches.length, 1);
        expect(searches[0].text, 'test query');
      });

      test('does not save empty searches', () async {
        await searchService.saveRecentSearch('');
        final searches = await searchService.getRecentSearches();
        expect(searches, isEmpty);
      });

      test('does not save whitespace searches', () async {
        await searchService.saveRecentSearch('   ');
        final searches = await searchService.getRecentSearches();
        expect(searches, isEmpty);
      });

      test('retrieves searches in reverse chronological order', () async {
        await searchService.saveRecentSearch('first');
        await Future.delayed(const Duration(milliseconds: 10));
        await searchService.saveRecentSearch('second');
        await Future.delayed(const Duration(milliseconds: 10));
        await searchService.saveRecentSearch('third');

        final searches = await searchService.getRecentSearches();
        expect(searches.length, 3);
        expect(searches[0].text, 'third');
        expect(searches[1].text, 'second');
        expect(searches[2].text, 'first');
      });

      test('limits history to 10 entries', () async {
        for (int i = 0; i < 15; i++) {
          await searchService.saveRecentSearch('query $i');
        }

        final searches = await searchService.getRecentSearches();
        expect(searches.length, 10);
        expect(searches[0].text, 'query 14'); // Most recent
        expect(searches[9].text, 'query 5'); // 10th most recent
      });

      test('removes duplicates and moves to front', () async {
        await searchService.saveRecentSearch('first');
        await searchService.saveRecentSearch('second');
        await searchService.saveRecentSearch('first'); // Duplicate

        final searches = await searchService.getRecentSearches();
        expect(searches.length, 2);
        expect(searches[0].text, 'first'); // Should be at front
        expect(searches[1].text, 'second');
      });

      test('respects limit parameter in getRecentSearches', () async {
        for (int i = 0; i < 10; i++) {
          await searchService.saveRecentSearch('query $i');
        }

        final searches = await searchService.getRecentSearches(limit: 5);
        expect(searches.length, 5);
      });

      test('clears search history', () async {
        await searchService.saveRecentSearch('first');
        await searchService.saveRecentSearch('second');

        await searchService.clearSearchHistory();

        final searches = await searchService.getRecentSearches();
        expect(searches, isEmpty);
      });

      test('handles corrupted history data gracefully', () async {
        // Manually corrupt the data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('recent_searches', 'invalid json');

        final searches = await searchService.getRecentSearches();
        expect(searches, isEmpty);

        // Should be able to save new searches after corruption
        await searchService.saveRecentSearch('new query');
        final newSearches = await searchService.getRecentSearches();
        expect(newSearches.length, 1);
      });
    });

    group('Performance', () {
      test('searches 1000 tasks in under 200ms', () {
        // Create 1000 test tasks
        final now = DateTime.now();
        final largeTasks = List<Task>.generate(
          1000,
          (i) => Task(
            id: 'task_$i',
            title: 'Task number $i with some text',
            description: 'Description for task $i with more content',
            createdAt: now,
            updatedAt: now,
            priority: i % 3,
            taskType: TaskType.values[i % TaskType.values.length],
          ),
        );

        final stopwatch = Stopwatch()..start();
        final results = searchService.searchTasks('task', largeTasks);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        expect(results.length, 1000); // All tasks should match
      });

      test('filters 1000 tasks in under 200ms', () {
        final now = DateTime.now();
        final largeTasks = List<Task>.generate(
          1000,
          (i) => Task(
            id: 'task_$i',
            title: 'Task $i',
            createdAt: now,
            updatedAt: now,
            priority: i % 3,
            taskType: TaskType.values[i % TaskType.values.length],
          ),
        );

        final stopwatch = Stopwatch()..start();
        final results = searchService.searchWithFilters(
          priorities: [2],
          taskTypes: [TaskType.technical],
          tasks: largeTasks,
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        expect(results.isNotEmpty, true);
      });
    });
  });
}
