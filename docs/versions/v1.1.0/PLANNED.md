# Planned Changes for v1.1.0

## Overview

This release focuses on enhancing task management capabilities with two major features: due dates for tasks and subtasks, and repeating tasks functionality. These additions will help users better organize time-sensitive tasks and automate recurring task management.

## Planned Features

### Due Dates for Tasks and Subtasks

- **Description**: Add support for setting due dates on both tasks and subtasks, with visual indicators for overdue, due today, and upcoming items. Include date picker UI and sorting/filtering by due date.
- **Priority**: HIGH
- **Dependencies**: 
  - `intl` package (already in dependencies) for date formatting
  - May need date picker package or use Flutter's built-in `showDatePicker`
- **Implementation Files**:
  - `lib/models/task.dart` - Add `dueDate` field to Task model
  - `lib/models/subtask.dart` - Add `dueDate` field to Subtask model (if separate model exists)
  - `lib/widgets/task_list_item.dart` - Display due date badges/indicators
  - `lib/widgets/task_detail_screen.dart` - Add due date picker and display
  - `lib/widgets/subtask_item.dart` - Display due date for subtasks
  - `lib/services/task_service.dart` - Add sorting and filtering by due date
  - `lib/services/notification_service.dart` (new file) - Optional: notifications for due dates
- **Estimated Complexity**: MEDIUM
  - Data model updates: Simple
  - UI components: Medium (date picker integration, visual indicators)
  - Sorting/filtering logic: Medium (date comparisons, overdue detection)
  - Persistence: Simple (Hive already handles DateTime serialization)

### Repeating Tasks

- **Description**: Enable tasks to repeat on configurable schedules (daily, weekly, monthly, custom intervals). When a repeating task is completed, automatically create the next instance based on the recurrence pattern.
- **Priority**: HIGH
- **Dependencies**:
  - No new external dependencies required
  - May consider `rrule` package for complex recurrence patterns (optional)
- **Implementation Files**:
  - `lib/models/task.dart` - Add recurrence fields (pattern, interval, end date)
  - `lib/models/recurrence_rule.dart` (new file) - Define recurrence patterns and logic
  - `lib/widgets/task_detail_screen.dart` - Add recurrence configuration UI
  - `lib/widgets/recurrence_picker.dart` (new file) - Custom widget for selecting recurrence patterns
  - `lib/services/task_service.dart` - Handle task completion and next instance creation
  - `lib/services/recurrence_service.dart` (new file) - Calculate next occurrence dates
- **Estimated Complexity**: COMPLEX
  - Data model: Medium (recurrence pattern representation)
  - Recurrence logic: Complex (date calculations, various patterns, edge cases)
  - UI components: Medium (recurrence picker with multiple options)
  - Task generation: Medium (creating next instance, handling exceptions)

## Technical Considerations

### Data Model Changes

**Task Model Updates:**
```dart
class Task {
  // Existing fields...
  DateTime? dueDate;
  RecurrenceRule? recurrence;
  String? parentRecurringTaskId; // Link to original recurring task
  bool isRecurring;
  DateTime? recurrenceEndDate;
  // ...
}
```

**New Recurrence Model:**
```dart
class RecurrenceRule {
  RecurrencePattern pattern; // daily, weekly, monthly, yearly, custom
  int interval; // repeat every X days/weeks/months
  List<int>? weekdays; // for weekly patterns (Mon=1, Sun=7)
  int? monthDay; // for monthly patterns (1-31)
  DateTime? endDate; // optional end date for recurrence
  int? occurrenceCount; // or end after N occurrences
}

enum RecurrencePattern { daily, weekly, monthly, yearly, custom }
```

### UI/UX Considerations

**Due Date Display:**
- Color-coded indicators:
  - Red: Overdue
  - Orange: Due today
  - Yellow: Due within 3 days
  - Green: Due within a week
  - Gray: No due date or future
- Compact date display format in task list
- Detailed date picker in task detail view

**Recurrence Configuration:**
- Simple presets: Daily, Weekly, Monthly
- Advanced options: Custom intervals, specific weekdays, end conditions
- Clear visual feedback showing next occurrence date
- Option to edit or delete single instance vs. entire series

### Data Persistence

**Hive Considerations:**
- `DateTime` is supported natively by Hive
- May need custom TypeAdapter for `RecurrenceRule` class
- Consider migration strategy for existing tasks (all fields nullable/optional)

**Storage Strategy:**
- Store complete recurrence rule with task
- Don't pre-generate future instances (generate on-demand)
- Track completed instances to prevent duplication

### Business Logic

**Due Date Logic:**
- Sort order: Overdue → Due today → Upcoming → No date
- Filter options: All, Overdue, Due today, This week, This month, No date
- Optional notifications for due dates (can be phase 2)

**Recurrence Logic:**
- When completing a recurring task:
  1. Mark current instance as complete
  2. Calculate next occurrence date based on pattern
  3. Create new task instance if within recurrence period
  4. Maintain link to parent recurring task ID
- Handle edge cases:
  - Recurrence ending (by date or count)
  - Skipped occurrences (incomplete tasks)
  - Timezone considerations
  - Daylight saving time transitions
  - Month-end dates (e.g., Jan 31 → Feb 28/29)

**Performance Considerations:**
- Efficient date comparison for sorting
- Caching of calculated next occurrence dates
- Lazy loading of recurring task instances
- Index by due date for faster filtering

### Breaking Changes

None anticipated. All new fields will be optional/nullable to maintain backward compatibility with existing task data.

### Migration Strategy

**Version 1.0.0 → 1.1.0:**
- No data migration required (all fields optional)
- Existing tasks will have `dueDate = null` and `recurrence = null`
- No changes to existing Hive boxes structure
- Backward compatible with v1.0.0 data

### Testing Requirements

**Unit Tests:**
- [ ] RecurrenceRule date calculation logic
- [ ] Due date comparison and sorting
- [ ] Next occurrence generation
- [ ] Edge cases (month-end, leap years, DST)
- [ ] Task completion with recurrence

**Integration Tests:**
- [ ] Create task with due date
- [ ] Edit task due date
- [ ] Complete recurring task and verify next instance
- [ ] Delete recurring task (single vs. series)
- [ ] Filter tasks by due date
- [ ] Sort tasks by due date

**Manual Testing:**
- [ ] Date picker UI on various screen sizes
- [ ] Recurrence picker all patterns
- [ ] Visual indicators for due dates
- [ ] Task list sorting with mixed due dates
- [ ] Complete recurring task multiple times
- [ ] Edge case dates (Feb 29, Dec 31, etc.)

### Future Enhancements (Post-v1.1.0)

- [ ] Push notifications for due dates
- [ ] Snooze functionality
- [ ] Recurring task templates
- [ ] Bulk edit due dates
- [ ] Calendar view integration
- [ ] iCalendar import/export
- [ ] Time-of-day for due dates (currently date-only)
- [ ] Recurring subtasks

### Known Limitations

1. **Time Precision**: Due dates will be date-only (no time-of-day) in v1.1.0
2. **Timezone**: All dates stored in device local time (not UTC)
3. **Recurrence Patterns**: Limited to basic patterns initially (daily, weekly, monthly)
4. **No Notifications**: Push notifications for due dates deferred to future version
5. **Single-Device**: No sync consideration for recurring task instances across devices

### Dependencies Impact

**No new dependencies required** - all functionality can be implemented with existing packages:
- `intl` (already included) - date formatting
- `hive` (already included) - data persistence
- Built-in Flutter date picker widgets

Optional future additions:
- `flutter_local_notifications` - for due date reminders
- `rrule` - for advanced recurrence patterns (RFC 5545 compliance)

---

## Implementation Phases

### Phase 1: Due Dates (Estimated: 2-3 days)
1. Update data models (Task, Subtask)
2. Implement date picker UI
3. Add due date display in task list
4. Implement sorting by due date
5. Add filtering by due date
6. Update storage service
7. Write tests

### Phase 2: Repeating Tasks (Estimated: 4-5 days)
1. Design RecurrenceRule model
2. Implement recurrence calculation logic
3. Create recurrence picker UI
4. Handle task completion with recurrence
5. Add series editing options (single vs. all)
6. Update storage service with TypeAdapter
7. Write comprehensive tests
8. Handle edge cases

### Phase 3: Polish and Testing (Estimated: 1-2 days)
1. Visual polish for due date indicators
2. Comprehensive manual testing
3. Performance optimization
4. Documentation updates
5. User acceptance testing

**Total Estimated Time**: 7-10 days

---

## Success Criteria

- [ ] Users can set due dates on tasks and subtasks
- [ ] Due dates are visually indicated with appropriate color coding
- [ ] Tasks can be sorted and filtered by due date
- [ ] Users can configure repeating tasks with daily, weekly, or monthly patterns
- [ ] Completing a recurring task creates the next instance automatically
- [ ] All data persists correctly across app restarts
- [ ] No breaking changes to existing functionality
- [ ] All unit and integration tests passing
- [ ] Performance remains smooth with 100+ tasks including recurring ones

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Date calculation bugs | HIGH | MEDIUM | Comprehensive unit tests, edge case testing |
| UI complexity for recurrence | MEDIUM | MEDIUM | Iterative design, user testing |
| Performance with many recurring tasks | MEDIUM | LOW | Lazy loading, efficient algorithms |
| Data migration issues | HIGH | LOW | Thorough testing, backward compatibility |
| Timezone/DST edge cases | MEDIUM | MEDIUM | Test with various timezones, document limitations |

---

**Target Release Date**: TBD (pending implementation start date)

**Status**: PLANNED - Awaiting implementation approval