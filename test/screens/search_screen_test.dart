import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/providers/task_provider.dart';
import 'package:sike/services/task_service.dart';
import 'package:sike/screens/search_screen.dart';

void main() {
  group('SearchScreen', () {
    late TaskService taskService;
    late TaskProvider taskProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Initialize Hive for tests
      Hive.init('./test/hive_test');

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TaskTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(RequiredResourceAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TaskContextAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(EnergyLevelAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(TimeEstimateAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(DueDateStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(RecurrencePatternAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(RecurrenceRuleAdapter());
      }

      taskService = TaskService();
      await taskService.init();
      taskProvider = TaskProvider(taskService);

      // Add test tasks
      final now = DateTime.now();
      await taskProvider.addTask(Task(
        id: '1',
        title: 'Buy groceries',
        description: 'Get milk and bread',
        createdAt: now,
        updatedAt: now,
      ));
      await taskProvider.addTask(Task(
        id: '2',
        title: 'Write report',
        description: 'Complete quarterly report',
        createdAt: now,
        updatedAt: now,
        taskType: TaskType.administrative,
      ));
    });

    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays advanced filters button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Advanced Filters'), findsOneWidget);
    });

    testWidgets('shows recent searches when no query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Recent Searches'), findsOneWidget);
    });

    testWidgets('performs search and displays results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'groceries');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should display results
      expect(find.textContaining('result'), findsOneWidget);
    });

    testWidgets('displays empty state when no results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text that won't match
      await tester.enterText(find.byType(TextField), 'nonexistent');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should display empty state
      expect(find.textContaining('No results found'), findsOneWidget);
    });

    testWidgets('clears search when clear button is pressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: taskProvider,
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Press clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should show recent searches again
      expect(find.textContaining('Recent Searches'), findsOneWidget);
    });
  });
}
