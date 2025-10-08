# Planned Changes for v1.2.0

## Overview

This release focuses on enhancing task discovery, historical tracking, and recurrence capabilities. Building on the solid foundation of v1.1.0's due dates and basic recurring tasks, v1.2.0 adds powerful search functionality, task archiving for historical reference, recurring task analytics, and advanced recurrence patterns.

**Target Version**: v1.2.0  
**Status**: PLANNING  
**Target Release**: TBD

---

## Planned Features

### 1. Task Search

**Priority**: HIGH  
**Complexity**: MEDIUM

#### Description
Comprehensive search functionality enabling users to quickly find tasks across their entire task database using full-text search, metadata filters, and smart suggestions.

#### Key Capabilities
- **Full-text search**: Search across task titles and descriptions
- **Quick filters**: Filter by task type, priority, context, energy level, time estimate
- **Combined search**: Text search + metadata filters simultaneously
- **Search history**: Recent searches for quick access
- **Results highlighting**: Matched text highlighted in results
- **Real-time results**: Search as you type with debouncing

#### Implementation Components

**Data Layer**:
- No new database fields required
- In-memory search indexing for performance
- Case-insensitive text matching

**Service Layer** - `lib/services/search_service.dart` ✨ NEW:
```dart
class SearchService {
  // Full-text search across title and description
  List<Task> searchTasks(String query, List<Task> tasks);
  
  // Combined search with filters
  List<Task> searchWithFilters({
    String? textQuery,
    List<TaskType>? taskTypes,
    List<int>? priorities,
    List<TaskContext>? contexts,
    List<EnergyLevel>? energyLevels,
    List<TimeEstimate>? timeEstimates,
    bool? includeCompleted,
  });
  
  // Save and retrieve search history
  Future<void> saveRecentSearch(String query);
  List<String> getRecentSearches({int limit = 10});
  Future<void> clearSearchHistory();
}
```

**UI Components**:
- `lib/widgets/search_bar.dart` ✨ NEW - Search input with debouncing
- `lib/widgets/search_filters_sheet.dart` ✨ NEW - Advanced filter options
- `lib/widgets/search_results_list.dart` ✨ NEW - Results with highlighting
- `lib/screens/search_screen.dart` ✨ NEW - Dedicated search view

**Provider Updates** - `lib/providers/task_provider.dart`:
- Add `searchQuery` state
- Add `searchFilters` state  
- Add `searchResults` computed property
- Add search-related methods

#### UI/UX Design

**Search Bar**:
- Prominent position in app bar or as floating search button
- Clear/cancel button
- Search icon
- Loading indicator during search
- Recent searches dropdown

**Search Screen**:
- Search input at top
- Filter chips below search bar (removable)
- "Advanced Filters" button
- Results list with match highlighting
- Empty state with search suggestions
- Result count display

**Filter Sheet**:
- Section for each filter category
- Multi-select chips for each option
- "Clear all" and "Apply" buttons
- Live result count as filters change

#### Performance Considerations
- Debounce search input (300ms)
- Limit search results display (first 50-100)
- Lazy loading for large result sets
- Cache search results for same query
- Index tasks for faster searching (optional optimization)

---

### 2. Task Archiving

**Priority**: HIGH  
**Complexity**: MEDIUM

#### Description
Archive completed tasks to remove clutter while preserving historical records. Archived tasks can be searched, viewed, and restored, providing a complete task history without impacting active task performance.

#### Key Capabilities
- **Manual archiving**: Archive any completed task
- **Auto-archiving**: Optionally archive old completed tasks (configurable threshold)
- **Archive view**: Dedicated screen to browse archived tasks
- **Restore capability**: Unarchive tasks back to active list
- **Permanent deletion**: Delete archived tasks permanently
- **Archive search**: Search within archived tasks
- **Archive filters**: Filter archived tasks by date range, type, etc.

#### Implementation Components

**Data Model Updates** - `lib/models/task.dart`:
```dart
class Task {
  // Existing fields...
  
  @HiveField(20)
  bool isArchived; // Default: false
  
  @HiveField(21)
  DateTime? archivedAt; // Timestamp when archived
  
  @HiveField(22)
  DateTime? completedAt; // Track when task was actually completed
}
```

**Service Layer Updates** - `lib/services/task_service.dart`:
```dart
// Archive operations
Future<void> archiveTask(String taskId);
Future<void> unarchiveTask(String taskId);
List<Task> getArchivedTasks();
List<Task> getActiveTasksOnly(); // Excludes archived

// Auto-archive
Future<int> autoArchiveOldCompletedTasks({
  required int daysThreshold, // Archive completed tasks older than N days
});

// Bulk operations
Future<void> archiveMultipleTasks(List<String> taskIds);
Future<void> deleteArchivedTask(String taskId); // Permanent delete
Future<void> clearArchive(); // Delete all archived tasks
```

**Provider Updates** - `lib/providers/task_provider.dart`:
```dart
// Archive state
bool _showArchived = false;
int _archivedTasksCount = 0;

// Methods
void toggleShowArchived();
Future<void> archiveTask(String taskId);
Future<void> unarchiveTask(String taskId);
int get archivedTasksCount;
```

**UI Components**:
- `lib/screens/archive_screen.dart` ✨ NEW - Browse archived tasks
- `lib/widgets/archive_actions_menu.dart` ✨ NEW - Archive-specific actions
- Update `lib/widgets/task_item_enhanced.dart` - Add restore button for archived tasks
- Update `lib/screens/task_list_screen.dart` - Add "View Archive" menu option

#### UI/UX Design

**Archive Actions**:
- Long-press menu on completed task: "Archive" option
- Swipe action for quick archive
- Bulk select mode: "Archive selected" action

**Archive Screen**:
- Similar layout to main task list
- "ARCHIVED" header with count
- Search bar for archived tasks
- Sort/filter options
- Actions: Restore, Delete permanently
- Empty state: "No archived tasks"

**Settings**:
- Auto-archive toggle
- Auto-archive threshold (days) slider: 7, 14, 30, 60, 90 days
- "Clear archive" danger zone option

**Visual Indicators**:
- Archived badge/label on task items
- Grayed-out appearance
- Archive icon (box/filing cabinet)

#### Data Migration
**Version 1.1.0 → 1.2.0**:
- Add new fields with defaults:
  - `isArchived = false`
  - `archivedAt = null`
  - `completedAt = null`
- For existing completed tasks:
  - Set `completedAt = updatedAt` (approximate)
  - Keep `isArchived = false` (don't auto-archive existing tasks)

---

### 3. Recurring Task History

**Priority**: MEDIUM  
**Complexity**: MEDIUM

#### Description
Comprehensive view and analytics for recurring task instances, showing completion history, statistics, and trends. Helps users track their consistency with recurring tasks and identify patterns.

#### Key Capabilities
- **Instance timeline**: Visual timeline of all instances (past and future)
- **Completion tracking**: See which instances were completed and when
- **Statistics**: 
  - Completion rate (% of instances completed)
  - Current streak (consecutive completions)
  - Longest streak
  - Average days between completions
  - On-time completion rate (completed before/on due date)
- **Calendar integration**: Monthly view showing recurring task schedule
- **Skip/reschedule**: Mark specific instance as skipped or reschedule
- **Modify series**: Edit future instances of recurring task

#### Implementation Components

**Data Model Updates** - `lib/models/task.dart`:
```dart
class Task {
  // Existing fields...
  
  @HiveField(23)
  int? currentStreak; // For recurring tasks - consecutive completions
  
  @HiveField(24)
  int? longestStreak; // Historical longest streak
  
  @HiveField(25)
  bool isSkipped; // Mark instance as deliberately skipped (default: false)
}
```

**New Model** - `lib/models/recurring_task_stats.dart` ✨ NEW:
```dart
class RecurringTaskStats {
  final String recurringTaskId;
  final int totalInstances;
  final int completedInstances;
  final int skippedInstances;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> completionDates;
  final double avgDaysBetweenCompletions;
  final double onTimeCompletionRate;
  
  // Constructor and methods...
}
```

**Service Layer** - `lib/services/recurring_task_service.dart` ✨ NEW:
```dart
class RecurringTaskService {
  // Get statistics for a recurring task
  Future<RecurringTaskStats> getRecurringTaskStats(String parentId);
  
  // Get all instances (past and future)
  Future<List<Task>> getAllInstances(String parentId, {
    bool includeFuture = true,
    bool includeCompleted = true,
    bool includeSkipped = true,
  });
  
  // Mark instance as skipped
  Future<void> skipInstance(String instanceId);
  
  // Reschedule single instance
  Future<void> rescheduleInstance(String instanceId, DateTime newDueDate);
  
  // Update all future instances
  Future<void> updateFutureInstances(String parentId, Task updatedTemplate);
  
  // Calculate streaks
  int calculateCurrentStreak(List<Task> instances);
  int calculateLongestStreak(List<Task> instances);
}
```

**UI Components**:
- `lib/screens/recurring_task_detail_screen.dart` ✨ NEW - Detailed view with stats
- `lib/widgets/recurring_task_timeline.dart` ✨ NEW - Visual timeline
- `lib/widgets/recurring_task_stats_card.dart` ✨ NEW - Statistics display
- `lib/widgets/recurring_instance_item.dart` ✨ NEW - Individual instance display

#### UI/UX Design

**Recurring Task Detail Screen**:
- **Header section**:
  - Task title and description
  - Recurrence pattern summary
  - Edit recurrence button
- **Statistics Cards**:
  - Completion rate (with progress bar)
  - Current/longest streak (with fire emoji 🔥)
  - Total instances (completed/total)
  - On-time rate
- **Timeline Section**:
  - Monthly calendar view option
  - List view option (default)
  - Past instances (grayed, with completion date)
  - Current instance (highlighted)
  - Future instances (lighter, with due dates)
- **Actions**:
  - Skip instance
  - Reschedule instance
  - Edit series
  - Stop recurrence

**Access Points**:
- Tap recurring badge on task → Opens recurring task detail
- Long-press menu on recurring task → "View History" option
- New "Recurring Tasks" filter in main screen

#### Performance Considerations
- Lazy load old instances (>100)
- Cache statistics calculations
- Pre-calculate streaks on instance completion
- Efficient date range queries

---

### 4. Advanced Recurrence Patterns

**Priority**: MEDIUM  
**Complexity**: COMPLEX

#### Description
Expand recurrence capabilities beyond simple daily/weekly/monthly patterns to support complex scheduling needs like "every Monday and Wednesday", "first Friday of each month", "last day of month", etc.

#### Key Capabilities
- **Weekday selection**: Choose specific days for weekly patterns
- **Monthly by day**: "First Monday", "Last Friday", "Second Tuesday"
- **Monthly by date**: "Day 15", "Day 25", "Last day" of month
- **Multiple frequencies**: "Twice weekly", "Every other Monday"
- **Exclusions**: Skip specific dates or date ranges (holidays, vacations)
- **Pattern combinations**: Mix different patterns (weekdays only, etc.)

#### Implementation Components

**Data Model Updates** - `lib/models/recurrence_rule.dart`:
```dart
@HiveType(typeId: 8)
class RecurrenceRule {
  // Existing fields...
  @HiveField(0) final RecurrencePattern pattern;
  @HiveField(1) final int? interval;
  @HiveField(2) final DateTime? endDate;
  @HiveField(3) final int? maxOccurrences;
  
  // NEW fields for advanced patterns
  @HiveField(4)
  List<int>? selectedWeekdays; // 1=Monday, 7=Sunday
  
  @HiveField(5)
  MonthlyRecurrenceType? monthlyType; // byWeekday, byDate
  
  @HiveField(6)
  int? weekOfMonth; // 1=first, 2=second, 3=third, 4=fourth, -1=last
  
  @HiveField(7)
  int? dayOfMonth; // 1-31 or -1 for last day
  
  @HiveField(8)
  List<DateTime>? excludedDates; // Specific dates to skip
  
  // Enhanced validation and calculation methods...
}
```

**New Enums** - `lib/models/task_enums.dart`:
```dart
@HiveType(typeId: 9)
enum MonthlyRecurrenceType {
  @HiveField(0) byDate,      // e.g., "Day 15 of month"
  @HiveField(1) byWeekday,   // e.g., "First Monday"
}

@HiveType(typeId: 10)
enum WeekOfMonth {
  @HiveField(0) first,
  @HiveField(1) second,
  @HiveField(2) third,
  @HiveField(3) fourth,
  @HiveField(4) last,
}
```

**Service Layer Updates** - `lib/services/task_service.dart`:
```dart
// Enhanced calculation for advanced patterns
DateTime calculateNextDueDate(RecurrenceRule rule, DateTime currentDueDate) {
  // Existing basic patterns...
  
  // NEW: Handle advanced patterns
  if (rule.pattern == RecurrencePattern.weekly && 
      rule.selectedWeekdays != null) {
    return _calculateNextWeekdayOccurrence(currentDueDate, rule.selectedWeekdays!);
  }
  
  if (rule.pattern == RecurrencePattern.monthly && 
      rule.monthlyType == MonthlyRecurrenceType.byWeekday) {
    return _calculateNextMonthlyByWeekday(
      currentDueDate, 
      rule.weekOfMonth!, 
      rule.selectedWeekdays!.first,
    );
  }
  
  // Handle exclusions
  DateTime next = /* calculated date */;
  while (rule.excludedDates?.contains(next) == true) {
    next = calculateNextDueDate(rule, next);
  }
  
  return next;
}

// NEW helper methods
DateTime _calculateNextWeekdayOccurrence(DateTime current, List<int> weekdays);
DateTime _calculateNextMonthlyByWeekday(DateTime current, int week, int weekday);
DateTime _calculateNextMonthlyByDate(DateTime current, int day);
```

**UI Components**:
- `lib/widgets/advanced_recurrence_picker.dart` ✨ NEW - Complex pattern UI
- `lib/widgets/weekday_selector.dart` ✨ NEW - Multi-select weekdays
- `lib/widgets/monthly_pattern_selector.dart` ✨ NEW - By date/weekday picker
- `lib/widgets/recurrence_preview.dart` ✨ NEW - Show next 5 occurrences
- Update `lib/screens/task_form_screen.dart` - Enhanced recurrence section

#### UI/UX Design

**Advanced Recurrence Picker**:

**Weekly Patterns**:
- Toggle buttons for each day: [M] [T] [W] [T] [F] [S] [S]
- Multi-select enabled
- Visual indicator for selected days
- Example: "Every Monday, Wednesday, Friday"

**Monthly Patterns - By Weekday**:
- Week selector: First, Second, Third, Fourth, Last
- Weekday selector: Monday through Sunday
- Examples:
  - "First Monday of each month"
  - "Last Friday of each month"
  - "Second Tuesday of each month"

**Monthly Patterns - By Date**:
- Day of month number input (1-31)
- "Last day of month" checkbox
- Smart handling: "31st" becomes last day for months with <31 days
- Examples:
  - "Day 15 of each month"
  - "Day 1 of each month"
  - "Last day of each month"

**Recurrence Preview**:
- Show next 5 occurrence dates
- Display in calendar-like format
- Helps users verify pattern is correct
- Update live as pattern changes

**Exclusions** (Optional - can defer to v1.3.0):
- "+ Add excluded dates" button
- Date picker for exclusions
- List of excluded dates with remove option
- Use cases: holidays, vacations

#### Advanced Pattern Examples

**Common Patterns Supported**:
- ✅ Every weekday (Mon-Fri)
- ✅ Every Monday and Wednesday
- ✅ First Monday of each month
- ✅ Last day of each month
- ✅ 15th and 30th of each month (future: multiple dates per month)
- ✅ Every other Friday
- ✅ First and third Thursday (future: multiple weeks)

#### Validation Rules
- Weekly pattern with weekdays: At least one weekday must be selected
- Monthly by weekday: Week and weekday required
- Monthly by date: Date between 1-31 or -1 (last)
- Exclusions: Cannot exclude all future instances
- Due date required for all recurring tasks (existing rule)

---

## Technical Architecture

### Database Schema Changes

**Task Model - New Fields**:
```dart
@HiveField(20) bool isArchived = false;
@HiveField(21) DateTime? archivedAt;
@HiveField(22) DateTime? completedAt;
@HiveField(23) int? currentStreak;
@HiveField(24) int? longestStreak;
@HiveField(25) bool isSkipped = false;
```

**RecurrenceRule Model - New Fields**:
```dart
@HiveField(4) List<int>? selectedWeekdays;
@HiveField(5) MonthlyRecurrenceType? monthlyType;
@HiveField(6) int? weekOfMonth;
@HiveField(7) int? dayOfMonth;
@HiveField(8) List<DateTime>? excludedDates;
```

**New Type IDs**:
- MonthlyRecurrenceType: typeId 9
- WeekOfMonth: typeId 10 (if used as enum)

### Migration Strategy

**Version 1.1.0 → 1.2.0**:

All new fields are nullable or have defaults - **zero-downtime migration**:

1. **Task Model**:
   - `isArchived` defaults to `false`
   - `archivedAt` = `null`
   - `completedAt` = `null` (or could set to `updatedAt` for completed tasks)
   - `currentStreak` = `null`
   - `longestStreak` = `null`
   - `isSkipped` defaults to `false`

2. **RecurrenceRule Model**:
   - All new fields = `null` (existing patterns still work)
   - Backward compatible - old rules function unchanged

3. **No forced migration required** - Users continue seamlessly

**Optional Migration Script**:
```dart
class MigrationService {
  Future<void> migrateToVersion3() async {
    // Optional: Set completedAt for existing completed tasks
    final tasks = await _taskService.getAllTasks();
    for (final task in tasks) {
      if (task.isCompleted && task.completedAt == null) {
        await _taskService.updateTask(task.copyWith(
          completedAt: task.updatedAt,
        ));
      }
    }
  }
}
```

---

## Implementation Phases

### Phase 1: Task Search (Est. 2-3 days)
1. Create `SearchService` class
2. Implement text search algorithm
3. Add filter combinations
4. Build search UI components
5. Integrate with existing filters
6. Add search history persistence
7. Performance optimization
8. Write tests (30+ tests)

### Phase 2: Task Archiving (Est. 2-3 days)
1. Add archive fields to Task model
2. Update data model (build runner)
3. Implement archive service methods
4. Create archive screen
5. Add archive/restore actions
6. Implement auto-archive feature
7. Update existing queries to exclude archived
8. Write tests (25+ tests)

### Phase 3: Recurring Task History (Est. 3-4 days)
1. Add streak fields to Task model
2. Create `RecurringTaskStats` model
3. Build `RecurringTaskService`
4. Implement statistics calculations
5. Create detailed history screen
6. Build timeline visualization
7. Add skip/reschedule functionality
8. Write tests (30+ tests)

### Phase 4: Advanced Recurrence (Est. 4-5 days)
1. Extend RecurrenceRule model
2. Add new enums (MonthlyRecurrenceType, etc.)
3. Enhance date calculation logic
4. Build advanced pattern UI
5. Create weekday selector widget
6. Create monthly pattern selector
7. Add recurrence preview
8. Comprehensive edge case testing
9. Write tests (40+ tests)

### Phase 5: Integration & Polish (Est. 2 days)
1. Integration testing across features
2. Performance optimization
3. UI/UX polish
4. Documentation updates
5. Migration testing

**Total Estimated Time**: 13-17 days

---

## Dependencies

**New Dependencies**:
```yaml
dependencies:
  # Existing dependencies...
  collection: ^1.18.0  # For advanced list operations in search
  
dev_dependencies:
  # Existing...
```

**No breaking dependency changes** - all features work with existing packages.

**Optional Future Dependencies**:
- `flutter_local_notifications` - For task reminders (future version)
- `table_calendar` - For calendar views (alternative to custom implementation)
- `fl_chart` - For recurring task statistics visualizations

---

## Testing Requirements

### Unit Tests
- [ ] Search algorithm accuracy (exact match, partial match, case-insensitive)
- [ ] Search filter combinations
- [ ] Archive/unarchive operations
- [ ] Auto-archive threshold calculations
- [ ] Recurring task statistics calculations
- [ ] Streak calculation logic
- [ ] Advanced recurrence pattern calculations
- [ ] Weekday recurrence logic
- [ ] Monthly by weekday calculations
- [ ] Monthly by date calculations
- [ ] Edge cases for all new features

### Integration Tests
- [ ] Search with live task data
- [ ] Archive workflow (archive → view → restore)
- [ ] Auto-archive execution
- [ ] Complete recurring task with advanced pattern
- [ ] View recurring task history with stats
- [ ] Skip instance workflow
- [ ] Edit future instances

### Widget Tests
- [ ] Search bar component
- [ ] Archive screen rendering
- [ ] Recurring history screen
- [ ] Advanced recurrence picker
- [ ] Weekday selector
- [ ] Monthly pattern selector

**Target Coverage**: 150+ new tests

---

## Success Criteria

### Task Search
- [ ] Search returns results within 200ms for 1000+ tasks
- [ ] Filters work in combination with text search
- [ ] Search history persists across app restarts
- [ ] Empty state shows helpful suggestions

### Task Archiving
- [ ] Archived tasks excluded from active views
- [ ] Archive can be browsed and searched
- [ ] Restore returns task to exact previous state
- [ ] Auto-archive runs without blocking UI
- [ ] Archive size tracked and displayed

### Recurring Task History
- [ ] Statistics accurate to ±1% for all metrics
- [ ] Timeline displays 100+ instances without lag
- [ ] Streak calculations update in real-time
- [ ] Skip/reschedule actions persist correctly

### Advanced Recurrence
- [ ] All new patterns calculate correctly
- [ ] Weekday patterns generate expected dates
- [ ] Monthly by weekday handles month lengths
- [ ] Preview shows next 5 dates accurately
- [ ] Complex patterns remain user-friendly

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Search performance degradation | HIGH | MEDIUM | Implement indexing, pagination, debouncing |
| Archive size growth impacts app | MEDIUM | HIGH | Add archive size limits, cleanup options |
| Complex recurrence UI confusing | HIGH | MEDIUM | Progressive disclosure, pattern preview, examples |
| Statistics calculation slow | MEDIUM | MEDIUM | Cache results, incremental updates |
| Advanced patterns with bugs | HIGH | MEDIUM | Comprehensive testing, preview feature |
| Data migration issues | HIGH | LOW | Thorough testing, rollback plan |
| Breaking existing recurring tasks | CRITICAL | LOW | Backward compatibility testing |

---

## Breaking Changes

**None planned** - Full backward compatibility maintained:
- All new fields are optional/nullable
- Existing recurring tasks continue to work with basic patterns
- Archive feature defaults to showing active tasks
- Search is additive functionality

---

## Performance Targets

- **Search**: <200ms for 1000 tasks
- **Archive view**: Load 100 tasks in <300ms
- **Statistics calculation**: <500ms for 1000 instances
- **Advanced recurrence calc**: <50ms per calculation
- **App startup**: No degradation from v1.1.0

---

## Documentation Updates Required

- [ ] User guide for search functionality
- [ ] Archive usage guide
- [ ] Recurring task history documentation
- [ ] Advanced recurrence pattern examples
- [ ] Migration guide from v1.1.0
- [ ] API documentation for new services
- [ ] Updated screenshots for all new features

---

## Future Enhancements (Post-v1.2.0)

**Deferred to v1.3.0 or later**:
- Export search results
- Saved searches/smart filters
- Archive to external storage
- Recurring task templates
- Batch edit recurrence patterns
- Calendar sync integration
- Notification system
- Task attachments
- Collaboration features

---

## Open Questions

1. **Archive retention**: Should there be a maximum archive size or age limit?
2. **Search indexing**: Implement proper search index or rely on in-memory filtering?
3. **Recurring instances**: Should completed instances be archived automatically after X days?
4. **Complex patterns**: Include exclusions (holidays) in v1.2.0 or defer to v1.3.0?
5. **Statistics persistence**: Cache stats in database or calculate on-demand?

---

**Status**: PLANNED - Awaiting approval to proceed with implementation

**Next Steps**:
1. Review and approve feature specifications
2. Confirm priority ordering
3. Decide on open questions
4. Begin Phase 1 implementation