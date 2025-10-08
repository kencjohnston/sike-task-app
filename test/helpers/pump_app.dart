import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sike/providers/task_provider.dart';
import 'package:sike/services/task_service.dart';

/// Helper function to pump a widget wrapped with necessary providers for testing
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  TaskProvider? taskProvider,
  TaskService? taskService,
}) async {
  // Create default mocks if not provided
  final service = taskService ?? TaskService();
  final provider = taskProvider ?? TaskProvider(service);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: provider),
      ],
      child: MaterialApp(
        home: widget,
      ),
    ),
  );
}

/// Helper function to pump a widget with theme and navigation
Future<void> pumpAppWithNavigation(
  WidgetTester tester,
  Widget widget, {
  TaskProvider? taskProvider,
  TaskService? taskService,
  ThemeData? theme,
}) async {
  final service = taskService ?? TaskService();
  final provider = taskProvider ?? TaskProvider(service);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: provider),
      ],
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(
          body: widget,
        ),
      ),
    ),
  );
}

/// Helper function to pump a screen (full page) with providers
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  TaskProvider? taskProvider,
  TaskService? taskService,
}) async {
  final service = taskService ?? TaskService();
  final provider = taskProvider ?? TaskProvider(service);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: provider),
      ],
      child: MaterialApp(
        home: screen,
      ),
    ),
  );
}

/// Helper to find widgets by key
Finder findByKey(String key) => find.byKey(Key(key));

/// Helper to find widgets by text
Finder findByText(String text) => find.text(text);

/// Helper to find widgets by type
Finder findByType<T>() => find.byType(T);

/// Helper to find widgets by icon
Finder findByIcon(IconData icon) => find.byIcon(icon);

/// Helper to tap a widget and wait for animations
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Helper to enter text and wait for animations
Future<void> enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Helper to scroll until visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  double delta, {
  Finder? scrollable,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
}

/// Helper to long press and wait
Future<void> longPressAndSettle(WidgetTester tester, Finder finder) async {
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

/// Helper to drag and wait
Future<void> dragAndSettle(
  WidgetTester tester,
  Finder finder,
  Offset offset,
) async {
  await tester.drag(finder, offset);
  await tester.pumpAndSettle();
}
