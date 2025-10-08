import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/widgets/search_result_item.dart';

void main() {
  group('SearchResultItem', () {
    late Task testTask;

    setUp(() {
      final now = DateTime.now();
      testTask = Task(
        id: '1',
        title: 'Test task with keyword',
        description: 'This is a test description',
        createdAt: now,
        updatedAt: now,
        priority: 1,
        taskType: TaskType.administrative,
      );
    });

    testWidgets('displays task title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {},
            ),
          ),
        ),
      );

      // The title is displayed in RichText, so we look for that
      expect(find.byType(RichText), findsWidgets);
      // Or check that the widget tree contains the text
      final richTextWidget =
          tester.widgetList<RichText>(find.byType(RichText)).first;
      expect(richTextWidget.text.toPlainText(), contains('Test task'));
    });

    testWidgets('highlights search query in title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'keyword',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find RichText widget containing the title
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('displays match context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Match in:'), findsOneWidget);
    });

    testWidgets('shows task type chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(TaskType.administrative.displayLabel), findsOneWidget);
    });

    testWidgets('displays priority indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('shows description when match is in description',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'description',
              onTap: () {},
            ),
          ),
        ),
      );

      // Description is also in RichText
      final richTexts =
          tester.widgetList<RichText>(find.byType(RichText)).toList();
      final hasDescription = richTexts
          .any((rt) => rt.text.toPlainText().contains('test description'));
      expect(hasDescription, true);
    });

    testWidgets('shows due date when present', (tester) async {
      final now = DateTime.now();
      final taskWithDueDate = Task(
        id: '1',
        title: 'Task with due date',
        createdAt: now,
        updatedAt: now,
        dueDate: now.add(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: taskWithDueDate,
              searchQuery: 'task',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('shows recurring indicator for recurring tasks',
        (tester) async {
      final now = DateTime.now();
      final recurringTask = Task(
        id: '1',
        title: 'Recurring task',
        createdAt: now,
        updatedAt: now,
        dueDate: now,
        recurrenceRule: RecurrenceRule(pattern: RecurrencePattern.daily),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: recurringTask,
              searchQuery: 'recurring',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Recurring'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool onTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {
                onTapCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(onTapCalled, true);
    });

    testWidgets('displays checkbox for completed status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('displays navigation arrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              task: testTask,
              searchQuery: 'test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}
