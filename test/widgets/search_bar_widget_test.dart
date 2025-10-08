import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sike/widgets/search_bar_widget.dart';

void main() {
  group('SearchBarWidget', () {
    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              hintText: 'Search tasks...',
            ),
          ),
        ),
      );

      expect(find.text('Search tasks...'), findsOneWidget);
    });

    testWidgets('displays custom hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              hintText: 'Custom hint',
            ),
          ),
        ),
      );

      expect(find.text('Custom hint'), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialValue: 'test query',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('test query'), findsOneWidget);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialValue: 'test',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('does not show clear button when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('calls onChanged with debounce', (tester) async {
      String? lastValue;
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (value) {
                lastValue = value;
                callCount++;
              },
              debounceDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');

      // Verify onChanged is not called immediately
      expect(callCount, 0);

      // Wait for debounce duration
      await tester.pump(const Duration(milliseconds: 100));

      // Verify onChanged is called after debounce
      expect(callCount, 1);
      expect(lastValue, 'test');
    });

    testWidgets('clears text when clear button is pressed', (tester) async {
      String? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialValue: 'test',
              onChanged: (value) {
                lastValue = value;
              },
            ),
          ),
        ),
      );

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Verify text is cleared
      expect(find.text('test'), findsNothing);

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastValue, '');
    });

    testWidgets('calls onClear when clear button is pressed', (tester) async {
      bool onClearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              initialValue: 'test',
              onChanged: (_) {},
              onClear: () {
                onClearCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(onClearCalled, true);
    });

    testWidgets('debounces rapid text changes', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {
                callCount++;
              },
              debounceDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Enter text rapidly
      await tester.enterText(find.byType(TextField), 't');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(find.byType(TextField), 'te');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(find.byType(TextField), 'tes');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(find.byType(TextField), 'test');

      // Should not be called yet
      expect(callCount, 0);

      // Wait for debounce duration
      await tester.pump(const Duration(milliseconds: 100));

      // Should be called only once
      expect(callCount, 1);
    });
  });
}
