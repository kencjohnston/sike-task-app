# v1.2.0 Data Model Specifications

## Overview

This document details all data model changes for v1.2.0, including field additions, new models, and migration strategy.

---

## Task Model Updates

### Current v1.1.0 Task Model (Fields 0-19)
```dart
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String title;
  @HiveField(2) String? description;
  @HiveField(3) bool isCompleted;
  @HiveField(4) final DateTime createdAt;
  @HiveField(5) DateTime updatedAt;
  @HiveField(6) int priority;
  @HiveField(7) String? parentTaskId;
  @HiveField(8) List<String> subtaskIds;
  @HiveField(9) int nestingLevel;
  @HiveField(10) int sortOrder;
  @HiveField(11) TaskType taskType;
  @HiveField(12) List<RequiredResource> requiredResources;
  @HiveField(13) TaskContext taskContext;
  @HiveField(14) EnergyLevel energyRequired;
  @HiveField(15) TimeEstimate timeEstimate;
  @HiveField(16) DateTime? dueDate;
  @HiveField(17) RecurrenceRule? recurrenceRule;
  @HiveField(18) String? parentRecurringTaskId;
  @HiveField(19) DateTime? originalDueDate;
}
```

### New Fields for v1.2.0 (Fields 20-25)

#### Archiving Fields
```dart
@HiveField(20)
bool isArchived;
// Description: Marks if task is archived
// Default: false
// Purpose: Separates completed historical tasks from active tasks
// Impact: Archive screen filtering, performance optimization

@HiveField(21)
DateTime? archivedAt;
// Description: Timestamp when task was archived
// Default: null
// Purpose: Track archive age for auto-cleanup policies
// Impact: Archive sorting, age-based filtering

@HiveField(22)
DateTime? completedAt;
// Description: Timestamp when task was marked complete
// Default: null (on existing tasks), DateTime.now() when completing
// Purpose: Accurate completion tracking vs. last modified time
// Impact: Statistics, completion rate calculations, archive sorting
// Note: Different from updatedAt which changes on any edit
```

#### Recurring Task Analytics Fields
```dart
@HiveField(23)
int? currentStreak;
// Description: Number of consecutive completions for recurring tasks
// Default: null (non-recurring), 0 (new recurring)
// Purpose: Gamification, motivation tracking
// Impact: Recurring task history display
// Update trigger: On instance completion (increment) or miss (reset to 0)

@HiveField(24)
int? longestStreak;
// Description: Historical longest consecutive completion streak
// Default: null (non-recurring), 0 (new recurring)
// Purpose: Achievement tracking
// Impact: Statistics dashboard
// Update trigger: When currentStreak exceeds longestStreak

@HiveField(25)
bool isSkipped;
// Description: Marks instance as deliberately skipped (not forgotten)
// Default: false
// Purpose: Distinguish intentional skips from missed instances
// Impact: Statistics (excluded from completion rate), visual indicator
// Note: Only meaningful for recurring task instances
```

### Updated Task Constructor
```dart
Task({
  // Required fields
  required this.id,
  required this.title,
  required this.createdAt,
  required this.updatedAt,
  
  // Optional fields with defaults
  this.description,
  this.isCompleted = false,
  this.priority = 0,
  this.parentTaskId,
  List<String>? subtaskIds,
  this.nestingLevel = 0,
  this.sortOrder = 0,
  this.taskType = TaskType.administrative,
  List<RequiredResource>? requiredResources,
  this.taskContext = TaskContext.anywhere,
  this.energyRequired = EnergyLevel.medium,
  this.timeEstimate = TimeEstimate.medium,
  this.dueDate,
  this.recurrenceRule,
  this.parentRecurringTaskId,
  this.originalDueDate,
  
  // NEW v1.2.0 fields
  this.isArchived = false,
  this.archivedAt,
  this.completedAt,
  this.currentStreak,
  this.longestStreak,
  this.isSkipped = false,
}) : subtaskIds = subtaskIds ?? [],
     requiredResources = requiredResources ?? [];
```

### New Computed Properties
```dart
// Archive-related
bool get isActive => !isArchived;
Duration? get timeSinceArchived => 
    archivedAt != null ? DateTime.now().difference(archivedAt!) : null;
Duration? get timeSinceCompleted => 
    completedAt != null ? DateTime.now().difference(completedAt!) : null;

// Streak-related  
bool get hasActiveStreak => (currentStreak ?? 0) > 0;
bool get hasStreakRecord => (longestStreak ?? 0) > 0;

// Search-related (helper for indexing)
String get searchableText => '$title ${description ?? ''}'.toLowerCase();
```

### Updated Methods
```dart
// copyWith - add new parameters
Task copyWith({
  // Existing parameters...
  bool? isArchived,
  DateTime? archivedAt,
  DateTime? completedAt,
  int? currentStreak,
  int? longestStreak,
  bool? isSkipped,
});

// toMap - add new fields
Map<String, dynamic> toMap() {
  return {
    // Existing fields...
    'isArchived': isArchived,
    'archivedAt': archivedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'isSkipped': isSkipped,
  };
}

// fromMap - handle new fields
factory Task.fromMap(Map<String, dynamic> map) {
  return Task(
    // Existing fields...
    isArchived: map['isArchived'] as bool? ?? false,
    archivedAt: map['archivedAt'] != null 
        ? DateTime.parse(map['archivedAt'] as String) 
        : null,
    completedAt: map['completedAt'] != null 
        ? DateTime.parse(map['completedAt'] as String) 
        : null,
    currentStreak: map['currentStreak'] as int?,
    longestStreak: map['longestStreak'] as int?,
    isSkipped: map['isSkipped'] as bool? ?? false,
  );
}
```

---

## RecurrenceRule Model Updates

### Current v1.1.0 RecurrenceRule (Fields 0-3)
```dart
@HiveType(typeId: 8)
class RecurrenceRule extends HiveObject {
  @HiveField(0) final RecurrencePattern pattern;
  @HiveField(1) final int? interval;
  @HiveField(2) final DateTime? endDate;
  @HiveField(3) final int? maxOccurrences;
}
```

### New Fields for v1.2.0 (Fields 4-8)

```dart
@HiveField(4)
List<int>? selectedWeekdays;
// Description: Weekdays for weekly recurrence (1=Mon, 7=Sun)
// Default: null (uses current weekday for basic weekly)
// Purpose: Enable "every Monday and Wednesday" patterns
// Validation: Must contain 1-7, no duplicates
// Example: [1, 3, 5] = Monday, Wednesday, Friday

@HiveField(5)
MonthlyRecurrenceType? monthlyType;
// Description: How monthly recurrence is calculated
// Default: null (uses basic monthly by date)
// Values: byDate, byWeekday
// Purpose: Support "first Monday" vs "15th of month" patterns

@HiveField(6)
int? weekOfMonth;
// Description: Which week of month (1-4 or -1 for last)
// Default: null
// Purpose: For "first Monday", "last Friday" patterns
// Validation: 1-4 or -1
// Used when: monthlyType == byWeekday

@HiveField(7)
int? dayOfMonth;
// Description: Day of month for monthly patterns (1-31 or -1)
// Default: null (uses current day)
// Purpose: Explicit day-of-month specification
// Validation: 1-31 or -1 (last day)
// Used when: monthlyType == byDate
// Note: -1 = last day of month (handles varying month lengths)

@HiveField(8)
List<DateTime>? excludedDates;
// Description: Specific dates to skip in recurrence
// Default: null (no exclusions)
// Purpose: Skip holidays, vacations, etc.
// Storage: Date-only (time ignored)
// Impact: Date calculations, instance creation
```

### Updated RecurrenceRule Constructor
```dart
RecurrenceRule({
  required this.pattern,
  this.interval,
  this.endDate,
  this.maxOccurrences,
  
  // NEW v1.2.0 fields
  this.selectedWeekdays,
  this.monthlyType,
  this.weekOfMonth,
  this.dayOfMonth,
  this.excludedDates,
}) {
  // EXISTING validations
  if (pattern == RecurrencePattern.custom && (interval == null || interval! < 1)) {
    throw ArgumentError('Custom recurrence pattern requires a valid interval');
  }
  
  if (endDate != null && maxOccurrences != null) {
    throw ArgumentError('Cannot set both endDate and maxOccurrences');
  }
  
  // NEW validations
  if (selectedWeekdays != null) {
    if (selectedWeekdays!.isEmpty) {
      throw ArgumentError('selectedWeekdays cannot be empty');
    }
    if (selectedWeekdays!.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Weekdays must be between 1 (Monday) and 7 (Sunday)');
    }
  }
  
  if (monthlyType == MonthlyRecurrenceType.byWeekday) {
    if (weekOfMonth == null || selectedWeekdays == null || selectedWeekdays!.isEmpty) {
      throw ArgumentError('byWeekday requires weekOfMonth and selectedWeekdays');
    }
    if (weekOfMonth! < -1 || weekOfMonth! == 0 || weekOfMonth! > 4) {
      throw ArgumentError('weekOfMonth must be 1-4 or -1 (last)');
    }
  }
  
  if (monthlyType == MonthlyRecurrenceType.byDate) {
    if (dayOfMonth == null) {
      throw ArgumentError('byDate requires dayOfMonth');
    }
    if (dayOfMonth! < -1 || dayOfMonth! == 0 || dayOfMonth! > 31) {
      throw ArgumentError('dayOfMonth must be 1-31 or -1 (last)');
    }
  }
}
```

### Enhanced Display String
```dart
String getDisplayString() {
  final buffer = StringBuffer();
  
  // Basic pattern
  if (pattern == RecurrencePattern.weekly && selectedWeekdays != null) {
    buffer.write('Every ');
    buffer.write(_formatWeekdays(selectedWeekdays!));
  } else if (pattern == RecurrencePattern.monthly && monthlyType != null) {
    if (monthlyType == MonthlyRecurrenceType.byWeekday) {
      buffer.write(_formatMonthlyByWeekday(weekOfMonth!, selectedWeekdays!.first));
    } else {
      buffer.write(_formatMonthlyByDate(dayOfMonth!));
    }
  } else {
    buffer.write(pattern.getDescription(interval));
  }
  
  // End condition
  if (endDate != null) {
    buffer.write(' until ${_formatDate(endDate!)}');
  } else if (maxOccurrences != null) {
    buffer.write(' for $maxOccurrences occurrence${maxOccurrences! > 1 ? 's' : ''}');
  }
  
  // Exclusions
  if (excludedDates != null && excludedDates!.isNotEmpty) {
    buffer.write(' (${excludedDates!.length} excluded dates)');
  }
  
  return buffer.toString();
}

String _formatWeekdays(List<int> weekdays) {
  // Convert to names: [1, 3, 5] -> "Monday, Wednesday, and Friday"
  // Implementation details...
}

String _formatMonthlyByWeekday(int week, int weekday) {
  // "First Monday of each month"
  // "Last Friday of each month"
  // Implementation details...
}

String _formatMonthlyByDate(int day) {
  // "Day 15 of each month"
  // "Last day of each month"
  // Implementation details...
}
```

---

## New Models

### RecurringTaskStats Model

**File**: `lib/models/recurring_task_stats.dart` ✨ NEW

```dart
/// Statistics and analytics for a recurring task series
/// This is a computed model - not stored in database
class RecurringTaskStats {
  /// Parent recurring task ID
  final String recurringTaskId;
  
  /// Parent recurring task
  final Task parentTask;
  
  /// Total instances created (including original)
  final int totalInstances;
  
  /// Number of completed instances
  final int completedInstances;
  
  /// Number of skipped instances
  final int skippedInstances;
  
  /// Number of pending instances (not completed, not skipped)
  final int pendingInstances;
  
  /// Completion rate (0.0 - 1.0)
  /// Formula: completedInstances / (totalInstances - skippedInstances)
  final double completionRate;
  
  /// Current consecutive completion streak
  final int currentStreak;
  
  /// Longest historical streak
  final int longestStreak;
  
  /// List of completion dates (for trend analysis)
  final List<DateTime> completionDates;
  
  /// Average days between completions
  /// Formula: total days / number of completions
  final double? avgDaysBetweenCompletions;
  
  /// On-time completion rate (completed before/on due date)
  /// Formula: onTimeCompletions / completedInstances
  final double onTimeCompletionRate;
  
  /// Number of overdue instances (incomplete past due date)
  final int overdueInstances;
  
  /// Next scheduled instance
  final Task? nextInstance;
  
  /// Most recent completed instance
  final Task? lastCompletedInstance;
  
  const RecurringTaskStats({
    required this.recurringTaskId,
    required this.parentTask,
    required this.totalInstances,
    required this.completedInstances,
    required this.skippedInstances,
    required this.pendingInstances,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionDates,
    this.avgDaysBetweenCompletions,
    required this.onTimeCompletionRate,
    required this.overdueInstances,
    this.nextInstance,
    this.lastCompletedInstance,
  });
  
  /// Factory constructor to calculate stats from task instances
  factory RecurringTaskStats.fromInstances(
    Task parentTask,
    List<Task> instances,
  ) {
    // Calculate all statistics from instance list
    // Implementation details...
  }
  
  /// Check if recurring task is active (has future instances)
  bool get isActive => nextInstance != null;
  
  /// Check if user is maintaining streak
  bool get hasActiveStreak => currentStreak > 0;
  
  /// Get completion percentage as integer (0-100)
  int get completionPercentage => (completionRate * 100).round();
}
```

**Usage**:
```dart
// NOT stored in database - computed on-demand
final stats = await recurringTaskService.getRecurringTaskStats(taskId);

// Display in UI
Text('${stats.completionPercentage}% completion rate');
Text('${stats.currentStreak} day streak');
```

### SearchQuery Model

**File**: `lib/models/search_query.dart` ✨ NEW

```dart
/// Represents a search query with filters
/// Used for search history and saved searches (future)
class SearchQuery {
  /// Search text
  final String? text;
  
  /// Filter by task types
  final List<TaskType>? taskTypes;
  
  /// Filter by priorities
  final List<int>? priorities;
  
  /// Filter by contexts
  final List<TaskContext>? contexts;
  
  /// Filter by energy levels
  final List<EnergyLevel>? energyLevels;
  
  /// Filter by time estimates
  final List<TimeEstimate>? timeEstimates;
  
  /// Include completed tasks in results
  final bool includeCompleted;
  
  /// Include archived tasks in results
  final bool includeArchived;
  
  /// Timestamp when search was performed (for history)
  final DateTime? searchedAt;
  
  const SearchQuery({
    this.text,
    this.taskTypes,
    this.priorities,
    this.contexts,
    this.energyLevels,
    this.timeEstimates,
    this.includeCompleted = false,
    this.includeArchived = false,
    this.searchedAt,
  });
  
  /// Check if query has any filters
  bool get hasFilters => 
      taskTypes != null || 
      priorities != null || 
      contexts != null || 
      energyLevels != null || 
      timeEstimates != null;
  
  /// Check if query is empty
  bool get isEmpty => text == null && !hasFilters;
  
  /// Serialization for saving search history
  Map<String, dynamic> toMap();
  factory SearchQuery.fromMap(Map<String, dynamic> map);
  
  /// Create copy with updated fields
  SearchQuery copyWith({...});
  
  /// Display string for search history
  String toDisplayString() {
    if (text != null && text!.isNotEmpty) return text!;
    if (hasFilters) return 'Filtered search';
    return 'All tasks';
  }
}
```

**Storage**: Stored in SharedPreferences (not Hive) as JSON array of recent searches.

---

## New Enums

### MonthlyRecurrenceType

**File**: `lib/models/task_enums.dart`

```dart
@HiveType(typeId: 9)
enum MonthlyRecurrenceType {
  @HiveField(0) byDate,      // Day 15, Day 30, Last day
  @HiveField(1) byWeekday,   // First Monday, Last Friday
}

extension MonthlyRecurrenceTypeExtension on MonthlyRecurrenceType {
  String get displayLabel {
    switch (this) {
      case MonthlyRecurrenceType.byDate:
        return 'By Date';
      case MonthlyRecurrenceType.byWeekday:
        return 'By Day of Week';
    }
  }
  
  String get description {
    switch (this) {
      case MonthlyRecurrenceType.byDate:
        return 'Specific day number each month';
      case MonthlyRecurrenceType.byWeekday:
        return 'Day of week in specific week';
    }
  }
}
```

---

## Data Model Changes Summary

### Task Model - Field Mapping

| Field # | Name | Type | Added In | Required | Default | Purpose |
|---------|------|------|----------|----------|---------|---------|
| 0 | id | String | v1.0.0 | ✅ | - | Unique identifier |
| 1 | title | String | v1.0.0 | ✅ | - | Task name |
| 2 | description | String? | v1.0.0 | ❌ | null | Details |
| 3 | isCompleted | bool | v1.0.0 | ❌ | false | Completion status |
| 4 | createdAt | DateTime | v1.0.0 | ✅ | - | Creation timestamp |
| 5 | updatedAt | DateTime | v1.0.0 | ✅ | - | Last modified |
| 6 | priority | int | v1.0.0 | ❌ | 0 | Priority level |
| 7 | parentTaskId | String? | v1.0.0 | ❌ | null | Parent task link |
| 8 | subtaskIds | List<String> | v1.0.0 | ❌ | [] | Subtask links |
| 9 | nestingLevel | int | v1.0.0 | ❌ | 0 | Hierarchy depth |
| 10 | sortOrder | int | v1.0.0 | ❌ | 0 | Display order |
| 11 | taskType | TaskType | v1.0.0 | ❌ | administrative | Task category |
| 12 | requiredResources | List<RequiredResource> | v1.0.0 | ❌ | [] | Needed resources |
| 13 | taskContext | TaskContext | v1.0.0 | ❌ | anywhere | Location |
| 14 | energyRequired | EnergyLevel | v1.0.0 | ❌ | medium | Energy needed |
| 15 | timeEstimate | TimeEstimate | v1.0.0 | ❌ | medium | Duration |
| 16 | dueDate | DateTime? | v1.1.0 | ❌ | null | Due date |
| 17 | recurrenceRule | RecurrenceRule? | v1.1.0 | ❌ | null | Recurrence config |
| 18 | parentRecurringTaskId | String? | v1.1.0 | ❌ | null | Recurring parent |
| 19 | originalDueDate | DateTime? | v1.1.0 | ❌ | null | First due date |
| **20** | **isArchived** | **bool** | **v1.2.0** | ❌ | **false** | **Archive status** |
| **21** | **archivedAt** | **DateTime?** | **v1.2.0** | ❌ | **null** | **Archive time** |
| **22** | **completedAt** | **DateTime?** | **v1.2.0** | ❌ | **null** | **Completion time** |
| **23** | **currentStreak** | **int?** | **v1.2.0** | ❌ | **null** | **Active streak** |
| **24** | **longestStreak** | **int?** | **v1.2.0** | ❌ | **null** | **Best streak** |
| **25** | **isSkipped** | **bool** | **v1.2.0** | ❌ | **false** | **Skip marker** |

**Total Fields**: 26  
**New in v1.2.0**: 6 fields

### RecurrenceRule Model - Field Mapping

| Field # | Name | Type | Added In | Required | Default | Purpose |
|---------|------|------|----------|----------|---------|---------|
| 0 | pattern | RecurrencePattern | v1.1.0 | ✅ | - | Pattern type |
| 1 | interval | int? | v1.1.0 | ❌ | null | Custom interval |
| 2 | endDate | DateTime? | v1.1.0 | ❌ | null | End date |
| 3 | maxOccurrences | int? | v1.1.0 | ❌ | null | Max count |
| **4** | **selectedWeekdays** | **List<int>?** | **v1.2.0** | ❌ | **null** | **Weekday selection** |
| **5** | **monthlyType** | **MonthlyRecurrenceType?** | **v1.2.0** | ❌ | **null** | **Monthly method** |
| **6** | **weekOfMonth** | **int?** | **v1.2.0** | ❌ | **null** | **Week selector** |
| **7** | **dayOfMonth** | **int?** | **v1.2.0** | ❌ | **null** | **Day selector** |
| **8** | **excludedDates** | **List<DateTime>?** | **v1.2.0** | ❌ | **null** | **Skip dates** |

**Total Fields**: 9  
**New in v1.2.0**: 5 fields

### Hive Type IDs

**Existing**:
- 0: Task
- 1: TaskType
- 2: RequiredResource
- 3: TaskContext
- 4: EnergyLevel
- 5: TimeEstimate
- 6: DueDateStatus
- 7: RecurrencePattern
- 8: RecurrenceRule

**New in v1.2.0**:
- **9: MonthlyRecurrenceType**

**Reserved for future use**: 10-19

---

## Migration Specifications

### Automatic Migration on App Startup

**File**: `lib/services/migration_service.dart`

```dart
class MigrationService {
  static const int CURRENT_VERSION = 3; // v1.2.0 = version 3
  
  static Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt('schema_version') ?? 1;
    return currentVersion < CURRENT_VERSION;
  }
  
  static Future<void> migrateToVersion3() async {
    AppLogger.info('Starting migration to version 3 (v1.2.0)...');
    
    final tasksBox = await Hive.openBox<Task>('tasks');
    final tasks = tasksBox.values.toList();
    
    int migratedCount = 0;
    
    for (final task in tasks) {
      bool needsUpdate = false;
      Task updatedTask = task;
      
      // Set completedAt for existing completed tasks (if not set)
      if (task.isCompleted && task.completedAt == null) {
        updatedTask = updatedTask.copyWith(
          completedAt: task.updatedAt, // Use last update as approximation
        );
        needsUpdate = true;
      }
      
      // Initialize streak fields for recurring tasks
      if (task.isRecurring && task.currentStreak == null) {
        updatedTask = updatedTask.copyWith(
          currentStreak: 0,
          longestStreak: 0,
        );
        needsUpdate = true;
      }
      
      // Ensure archive fields have defaults (should already be false/null)
      // This is defensive - fields should auto-default
      
      if (needsUpdate) {
        await tasksBox.put(task.id, updatedTask);
        migratedCount++;
      }
    }
    
    // Mark migration as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('schema_version', CURRENT_VERSION);
    await prefs.setBool('v3_migration_completed', true);
    
    AppLogger.info('Migration to version 3 completed. Migrated $migratedCount tasks.');
  }
}
```

### Field Default Behaviors

**On App Upgrade**:
1. Hive automatically handles new fields with defaults
2. `isArchived` → `false` (all existing tasks remain active)
3. `archivedAt` → `null`
4. `completedAt` → `null` initially, set during migration for completed tasks
5. `currentStreak` → `null` for non-recurring, `0` for recurring
6. `longestStreak` → `null` for non-recurring, `0` for recurring
7. `isSkipped` → `false`

**On New Task Creation** (v1.2.0+):
```dart
Task.create({...}) {
  return Task(
    // Required fields...
    isArchived: false,           // Explicitly false
    archivedAt: null,            // Null until archived
    completedAt: null,           // Null until completed
    currentStreak: isRecurring ? 0 : null,  // Initialize for recurring
    longestStreak: isRecurring ? 0 : null,  // Initialize for recurring
    isSkipped: false,            // Explicitly false
  );
}
```

**On Task Completion**:
```dart
completeTask(Task task) {
  final now = DateTime.now();
  
  return task.copyWith(
    isCompleted: true,
    completedAt: now,            // NEW: Record completion time
    updatedAt: now,
    currentStreak: _calculateNewStreak(task),  // Update if recurring
    longestStreak: _updateLongestStreak(task), // Update if new record
  );
}
```

**On Task Archive**:
```dart
archiveTask(Task task) {
  return task.copyWith(
    isArchived: true,
    archivedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
```

---

## Backward Compatibility Guarantees

### ✅ Data Compatibility
- All v1.1.0 task data loads correctly in v1.2.0
- New fields auto-populate with safe defaults
- Existing queries continue to work
- No data loss during upgrade

### ✅ API Compatibility
- All v1.1.0 service methods unchanged
- New methods are additive only
- Provider interface extends (doesn't break)
- Widget interfaces backward compatible

### ✅ Storage Compatibility
- Hive box format unchanged
- Type adapter versioning supported
- Database file format compatible
- Can downgrade from v1.2.0 to v1.1.0 if needed (new fields ignored)

---

## Performance Impact Analysis

### Storage Impact
- **Per-task overhead**: +6 fields ≈ 50-100 bytes
- **100 tasks**: +5-10 KB
- **1000 tasks**: +50-100 KB
- **Impact**: Negligible (within normal app growth)

### Query Performance
- **Archive filtering**: Minimal (boolean check)
- **Search**: Linear scan O(n) initially, can optimize with indexing
- **Statistics calculation**: O(n) per recurring task, cached result
- **Overall**: No degradation expected for <10,000 tasks

### Memory Impact
- **Additional in-memory data**: ~100-200 KB for typical usage
- **Search indexing**: ~1-2 MB for 1000 tasks (if implemented)
- **Statistics cache**: ~10-20 KB per recurring task
- **Total overhead**: <5 MB for typical use

---

## Testing Requirements

### Data Model Tests
- [ ] Task model with all new fields
- [ ] Task serialization/deserialization
- [ ] RecurrenceRule with advanced patterns
- [ ] Field default values
- [ ] copyWith with new fields
- [ ] Equality and hashCode with new fields

### Migration Tests
- [ ] v1.1.0 data loads correctly
- [ ] Migration script executes without errors
- [ ] completedAt set correctly for existing tasks
- [ ] Streak fields initialized for recurring tasks
- [ ] Migration idempotency (can run multiple times safely)

### Edge Case Tests
- [ ] Archive/unarchive preserves all fields
- [ ] Streak calculations across gaps
- [ ] Advanced recurrence with month-end dates
- [ ] Weekday patterns across year boundary
- [ ] Excluded dates handling
- [ ] Monthly by weekday edge cases (5th week months)

**Target**: 80+ new tests for data models

---

## Build Runner Updates

### Type Adapter Generation

After model changes, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Expected outputs**:
- `lib/models/task.g.dart` (updated - 6 new fields)
- `lib/models/recurrence_rule.g.dart` (updated - 5 new fields)
- `lib/models/task_enums.g.dart` (updated - new enum)

### Verification Commands

```bash
# 1. Analyze code
flutter analyze

# 2. Generate adapters
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run tests
flutter test

# 4. Build app
flutter build apk --debug
```

---

## Rollback Plan

### If Issues Arise During Migration

1. **Schema Version Check**: App checks schema version on startup
2. **Graceful Degradation**: If migration fails, app continues with v1.1.0 features
3. **User Notification**: Alert user if migration incomplete
4. **Manual Migration**: Admin menu option to retry migration
5. **Data Backup**: Recommend users backup before upgrading (user responsibility)

### Downgrade Support

If user needs to downgrade from v1.2.0 → v1.1.0:
- All v1.1.0 fields preserved
- New v1.2.0 fields ignored by v1.1.0 adapters
- No data corruption
- Archive status lost (tasks show as active again)
- Streak data lost (can't be reconstructed)
- Advanced recurrence patterns revert to basic patterns

---

## Summary

**Data Model Changes**:
- ✅ 6 new Task fields (backward compatible)
- ✅ 5 new RecurrenceRule fields (backward compatible)
- ✅ 1 new enum type
- ✅ 2 new computed models (not stored)
- ✅ Zero breaking changes

**Migration Complexity**: **LOW**
- Automatic on app upgrade
- No user intervention required
- Falls back gracefully if issues occur
- Can run multiple times safely (idempotent)

**Risk Level**: **LOW**
- All changes additive
- Comprehensive test coverage planned
- Rollback path available
- Proven pattern from v1.1.0

---

**Status**: SPECIFICATION COMPLETE - Ready for implementation