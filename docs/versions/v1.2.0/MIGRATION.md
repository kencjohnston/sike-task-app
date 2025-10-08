# v1.2.0 Migration Strategy

## Overview

This document outlines the complete migration strategy from v1.1.0 to v1.2.0, ensuring zero-downtime upgrades and data safety.

---

## Migration Summary

**Schema Version**: 1 → 2 → **3**
- v1.0.0 = Schema version 1
- v1.1.0 = Schema version 2  
- v1.2.0 = Schema version 3

**Migration Type**: Automatic, on-demand
**User Impact**: None (transparent upgrade)
**Data Loss Risk**: Zero
**Rollback Support**: Yes (with limitations)

---

## Pre-Migration Checklist

### Development Environment
- [ ] All tests passing on v1.1.0
- [ ] Build runner executed successfully
- [ ] No linting errors
- [ ] Database backup strategy documented
- [ ] Rollback procedure tested

### Data Validation
- [ ] Verify all v1.1.0 data loads correctly
- [ ] Test with various data states:
  - Empty database
  - Only old v1.0.0 tasks
  - Mix of v1.0.0 and v1.1.0 tasks
  - Large dataset (1000+ tasks)
  - All recurrence patterns present

### Version Control
- [ ] Create v1.1.0 release tag
- [ ] Branch for v1.2.0 development
- [ ] Backup production database (if applicable)

---

## Migration Architecture

### Schema Version Tracking

**Storage**: SharedPreferences  
**Key**: `schema_version`  
**Values**: 
- `1` = v1.0.0 (baseline)
- `2` = v1.1.0 (due dates + basic recurrence)
- `3` = v1.2.0 (search, archive, advanced recurrence)

**Additional Flags**:
- `v2_migration_completed` (boolean)
- `v3_migration_completed` (boolean)
- `last_migration_date` (ISO8601 string)
- `migration_v3_task_count` (int)

### Migration Service Architecture

**File**: `lib/services/migration_service.dart` (existing, enhanced)

```dart
class MigrationService {
  static const int CURRENT_VERSION = 3;
  static const String VERSION_KEY = 'schema_version';
  static const String MIGRATION_PREFIX = 'v';
  
  /// Check if any migration is needed
  static Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(VERSION_KEY) ?? 1;
    return currentVersion < CURRENT_VERSION;
  }
  
  /// Get current schema version
  static Future<int> getCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(VERSION_KEY) ?? 1;
  }
  
  /// Run all pending migrations
  static Future<void> runMigrations() async {
    final currentVersion = await getCurrentVersion();
    
    AppLogger.info('Current schema version: $currentVersion');
    AppLogger.info('Target schema version: $CURRENT_VERSION');
    
    // Run migrations sequentially
    if (currentVersion < 2) {
      await migrateToVersion2(); // v1.0.0 → v1.1.0
    }
    
    if (currentVersion < 3) {
      await migrateToVersion3(); // v1.1.0 → v1.2.0
    }
    
    AppLogger.info('All migrations completed successfully');
  }
  
  /// Migrate from v1.1.0 to v1.2.0 (version 2 → 3)
  static Future<void> migrateToVersion3() async {
    AppLogger.info('Starting migration to version 3 (v1.2.0)...');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check if already migrated
    if (prefs.getBool('v3_migration_completed') == true) {
      AppLogger.info('Migration already completed. Skipping.');
      return;
    }
    
    final tasksBox = await Hive.openBox<Task>('tasks');
    final tasks = tasksBox.values.toList();
    
    AppLogger.info('Found ${tasks.length} tasks to migrate');
    
    int migratedCount = 0;
    int errorCount = 0;
    
    for (final task in tasks) {
      try {
        bool needsUpdate = false;
        Task updatedTask = task;
        
        // 1. Set completedAt for existing completed tasks
        if (task.isCompleted && task.completedAt == null) {
          updatedTask = updatedTask.copyWith(
            completedAt: task.updatedAt,
          );
          needsUpdate = true;
        }
        
        // 2. Initialize streak fields for recurring tasks
        if (task.isRecurring && task.currentStreak == null) {
          // Calculate initial streak from existing instances
          final stats = await _calculateInitialStreak(task);
          updatedTask = updatedTask.copyWith(
            currentStreak: stats['current'],
            longestStreak: stats['longest'],
          );
          needsUpdate = true;
        }
        
        // 3. Ensure new boolean fields have proper defaults
        // Note: Hive should auto-default these, but be defensive
        if (task.isArchived == null) {
          updatedTask = updatedTask.copyWith(isArchived: false);
          needsUpdate = true;
        }
        
        if (task.isSkipped == null && task.isRecurringInstance) {
          updatedTask = updatedTask.copyWith(isSkipped: false);
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          await tasksBox.put(task.id, updatedTask);
          migratedCount++;
        }
      } catch (e, stackTrace) {
        errorCount++;
        AppLogger.error('Error migrating task ${task.id}', e, stackTrace);
        // Continue with other tasks
      }
    }
    
    // Validate task integrity after migration
    await validateTaskIntegrity();
    
    // Mark migration as complete
    await prefs.setInt(VERSION_KEY, CURRENT_VERSION);
    await prefs.setBool('v3_migration_completed', true);
    await prefs.setString('last_migration_date', DateTime.now().toIso8601String());
    await prefs.setInt('migration_v3_task_count', tasks.length);
    
    AppLogger.info('Migration to version 3 completed.');
    AppLogger.info('Migrated: $migratedCount tasks');
    if (errorCount > 0) {
      AppLogger.warning('Errors during migration: $errorCount tasks');
    }
  }
  
  /// Calculate initial streak for existing recurring task
  static Future<Map<String, int>> _calculateInitialStreak(Task recurringTask) async {
    final taskService = TaskService();
    final instances = await taskService.getRecurringTaskInstances(
      recurringTask.parentRecurringTaskId ?? recurringTask.id,
    );
    
    // Sort by due date
    instances.sort((a, b) => 
      (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now())
    );
    
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    
    // Calculate streaks from completed instances
    for (final instance in instances.reversed) {
      if (instance.isCompleted) {
        tempStreak++;
        currentStreak = tempStreak; // Keep updating current
      } else if (!instance.isSkipped) {
        // Reset streak on missed instance
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 0;
      }
      // Skipped instances don't break streak
    }
    
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }
    
    return {
      'current': currentStreak,
      'longest': longestStreak,
    };
  }
  
  /// Validate and fix task data integrity after migration
  static Future<void> validateTaskIntegrity() async {
    // Reuse existing validation logic from v1.1.0
    // Check for orphaned tasks, circular references, etc.
    // Already implemented in current migration_service.dart
  }
  
  /// Reset migration flag (for testing/debugging)
  static Future<void> resetMigrationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('v3_migration_completed');
    AppLogger.info('Migration flag reset successfully');
  }
  
  /// Get migration status information
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(VERSION_KEY) ?? 1;
    
    return {
      'current_version': currentVersion,
      'target_version': CURRENT_VERSION,
      'needs_migration': currentVersion < CURRENT_VERSION,
      'v2_completed': prefs.getBool('v2_migration_completed') ?? false,
      'v3_completed': prefs.getBool('v3_migration_completed') ?? false,
      'last_migration_date': prefs.getString('last_migration_date'),
      'task_count': prefs.getInt('migration_v3_task_count'),
    };
  }
}
```

---

## Migration Steps

### Step 1: Version Detection
**When**: App startup (in `main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  // Register adapters...
  await Hive.openBox<Task>('tasks');
  
  // Check for migrations BEFORE initializing app
  try {
    if (await MigrationService.needsMigration()) {
      AppLogger.info('Migration required...');
      await MigrationService.runMigrations();
    }
  } catch (e, stackTrace) {
    AppLogger.error('Migration failed', e, stackTrace);
    // App can still start with existing data
    // Show user notification about incomplete migration
  }
  
  // Continue with normal app initialization...
  final taskService = TaskService();
  await taskService.init();
  
  runApp(MyApp(taskService: taskService));
}
```

### Step 2: Data Migration
**For each task in database**:

#### Archive Fields
```dart
// All new fields default correctly via Hive
// No action needed for:
// - isArchived (defaults to false)
// - archivedAt (defaults to null)
// - isSkipped (defaults to false)

// Only set completedAt for completed tasks
if (task.isCompleted && task.completedAt == null) {
  task = task.copyWith(completedAt: task.updatedAt);
}
```

#### Recurring Task Fields
```dart
// Initialize streaks for recurring tasks
if (task.isRecurring && task.currentStreak == null) {
  // Option 1: Start fresh (simpler)
  task = task.copyWith(
    currentStreak: 0,
    longestStreak: 0,
  );
  
  // Option 2: Calculate from history (more accurate)
  final stats = await _calculateInitialStreak(task);
  task = task.copyWith(
    currentStreak: stats['current'],
    longestStreak: stats['longest'],
  );
}
```

#### RecurrenceRule Advanced Fields
```dart
// New fields auto-default to null
// Existing basic patterns continue to work
// No migration needed - backward compatible
```

### Step 3: Validation
**After migration**:
- Validate all tasks loaded correctly
- Check task counts match pre-migration
- Verify no null pointer exceptions
- Test basic operations (create, read, update, delete)

### Step 4: Completion Marking
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('schema_version', 3);
await prefs.setBool('v3_migration_completed', true);
await prefs.setString('last_migration_date', DateTime.now().toIso8601String());
```

---

## Migration Scenarios

### Scenario 1: Fresh Install (v1.2.0)
**State**: No existing data  
**Action**: No migration needed  
**Result**: All new tasks created with v1.2.0 schema

### Scenario 2: Upgrade from v1.0.0
**State**: Tasks with fields 0-10 only  
**Action**: Run migrations v1→v2→v3  
**Result**: All fields populated with defaults

**Migration chain**:
1. v1 → v2: Add fields 11-19 (batch metadata, due dates, recurrence)
2. v2 → v3: Add fields 20-25 (archive, streaks)

### Scenario 3: Upgrade from v1.1.0 (Most Common)
**State**: Tasks with fields 0-19  
**Action**: Run migration v2→v3  
**Result**: Fields 20-25 added

**Tasks affected**:
- All tasks get archive fields (default: not archived)
- Completed tasks get `completedAt` timestamp
- Recurring tasks get streak tracking initialized

### Scenario 4: Downgrade from v1.2.0 to v1.1.0
**State**: Tasks with fields 0-25  
**Action**: None (v1.1.0 ignores fields 20-25)  
**Result**: App works normally, new data lost

**Data loss on downgrade**:
- ❌ Archive status (all tasks show as active)
- ❌ Archived timestamps
- ❌ Completion timestamps
- ❌ Streak data
- ❌ Skip markers
- ❌ Advanced recurrence patterns (revert to basic)
- ✅ All v1.1.0 data preserved

---

## Field-by-Field Migration

### Task Model Fields

| Field | Migration Action | Complexity |
|-------|-----------------|------------|
| 20. isArchived | Auto-default to `false` | Trivial |
| 21. archivedAt | Auto-default to `null` | Trivial |
| 22. completedAt | Set to `updatedAt` if completed | Simple |
| 23. currentStreak | Calculate from instances or set to 0 | Medium |
| 24. longestStreak | Calculate from instances or set to 0 | Medium |
| 25. isSkipped | Auto-default to `false` | Trivial |

### RecurrenceRule Model Fields

| Field | Migration Action | Complexity |
|-------|-----------------|------------|
| 4. selectedWeekdays | Auto-default to `null` | Trivial |
| 5. monthlyType | Auto-default to `null` | Trivial |
| 6. weekOfMonth | Auto-default to `null` | Trivial |
| 7. dayOfMonth | Auto-default to `null` | Trivial |
| 8. excludedDates | Auto-default to `null` | Trivial |

**Note**: All RecurrenceRule fields are nullable and optional. Existing basic patterns (daily, weekly, monthly with no advanced options) continue to work without modification.

---

## Migration Implementation

### Complete Migration Function

```dart
static Future<void> migrateToVersion3() async {
  final stopwatch = Stopwatch()..start();
  AppLogger.info('Starting migration to version 3 (v1.2.0)...');
  
  final prefs = await SharedPreferences.getInstance();
  
  // Safety check - prevent duplicate migration
  if (prefs.getBool('v3_migration_completed') == true) {
    AppLogger.info('Migration already completed. Skipping.');
    return;
  }
  
  final tasksBox = await Hive.openBox<Task>('tasks');
  final tasks = tasksBox.values.toList();
  final totalTasks = tasks.length;
  
  AppLogger.info('Found $totalTasks tasks to migrate');
  
  int migratedCount = 0;
  int skippedCount = 0;
  int errorCount = 0;
  final List<String> errors = [];
  
  // Phase 1: Migrate basic fields
  for (final task in tasks) {
    try {
      bool needsUpdate = false;
      Task updatedTask = task;
      
      // Set completedAt for completed tasks
      if (task.isCompleted && task.completedAt == null) {
        updatedTask = updatedTask.copyWith(
          completedAt: task.updatedAt,
        );
        needsUpdate = true;
        AppLogger.info('Set completedAt for task: ${task.id}');
      }
      
      // Initialize recurring task fields
      if (task.isRecurring && task.currentStreak == null) {
        updatedTask = updatedTask.copyWith(
          currentStreak: 0,
          longestStreak: 0,
        );
        needsUpdate = true;
        AppLogger.info('Initialized streaks for recurring task: ${task.id}');
      }
      
      if (needsUpdate) {
        await tasksBox.put(task.id, updatedTask);
        migratedCount++;
      } else {
        skippedCount++;
      }
      
    } catch (e, stackTrace) {
      errorCount++;
      errors.add('Task ${task.id}: $e');
      AppLogger.error('Error migrating task ${task.id}', e, stackTrace);
    }
  }
  
  // Phase 2: Calculate accurate streaks for recurring tasks
  final recurringTasks = tasks.where((t) => t.isRecurring).toList();
  AppLogger.info('Calculating streaks for ${recurringTasks.length} recurring tasks...');
  
  for (final recurringTask in recurringTasks) {
    try {
      final parentId = recurringTask.parentRecurringTaskId ?? recurringTask.id;
      final stats = await _calculateInitialStreak(recurringTask);
      
      final updated = await tasksBox.get(recurringTask.id);
      if (updated != null) {
        final withStreaks = updated.copyWith(
          currentStreak: stats['current'],
          longestStreak: stats['longest'],
        );
        await tasksBox.put(recurringTask.id, withStreaks);
        AppLogger.info('Updated streaks for ${recurringTask.id}: '
            'current=${stats['current']}, longest=${stats['longest']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating streak for ${recurringTask.id}', 
          e, stackTrace);
    }
  }
  
  // Phase 3: Validate task integrity
  AppLogger.info('Validating task integrity...');
  await validateTaskIntegrity();
  
  // Phase 4: Mark migration complete
  await prefs.setInt(VERSION_KEY, CURRENT_VERSION);
  await prefs.setBool('v3_migration_completed', true);
  await prefs.setString('last_migration_date', DateTime.now().toIso8601String());
  await prefs.setInt('migration_v3_task_count', totalTasks);
  
  // Save migration stats
  await prefs.setInt('migration_v3_migrated', migratedCount);
  await prefs.setInt('migration_v3_skipped', skippedCount);
  await prefs.setInt('migration_v3_errors', errorCount);
  
  stopwatch.stop();
  final duration = stopwatch.elapsedMilliseconds;
  
  AppLogger.info('Migration to version 3 completed in ${duration}ms');
  AppLogger.info('Total: $totalTasks tasks');
  AppLogger.info('Migrated: $migratedCount tasks');
  AppLogger.info('Skipped: $skippedCount tasks (no changes needed)');
  
  if (errorCount > 0) {
    AppLogger.warning('Errors: $errorCount tasks');
    AppLogger.warning('Error details: ${errors.join(', ')}');
  }
}
```

---

## Migration Testing

### Unit Tests

**File**: `test/unit/services/migration_service_v3_test.dart` ✨ NEW

```dart
group('MigrationService v1.2.0', () {
  group('migrateToVersion3', () {
    test('should set completedAt for completed tasks', () async {
      // Arrange
      final task = TestHelpers.createSampleTask(
        isCompleted: true,
        completedAt: null,
      );
      await tasksBox.put(task.id, task);
      
      // Act
      await MigrationService.migrateToVersion3();
      
      // Assert
      final migrated = tasksBox.get(task.id);
      expect(migrated!.completedAt, isNotNull);
      expect(migrated.completedAt, equals(task.updatedAt));
    });
    
    test('should initialize streaks for recurring tasks', () async {
      // Test implementation...
    });
    
    test('should skip migration if already completed', () async {
      // Test idempotency...
    });
    
    test('should handle empty task box', () async {
      // Test edge case...
    });
    
    test('should preserve existing task data during migration', () async {
      // Test data integrity...
    });
    
    test('should calculate accurate streaks from instances', () async {
      // Test streak calculation...
    });
    
    test('should handle migration errors gracefully', () async {
      // Test error handling...
    });
  });
  
  group('getCurrentVersion', () {
    test('should return version 1 for fresh install', () async {
      // Test...
    });
    
    test('should return current version after migration', () async {
      // Test...
    });
  });
  
  group('needsMigration', () {
    test('should return true when version < 3', () async {
      // Test...
    });
    
    test('should return false when version == 3', () async {
      // Test...
    });
  });
});
```

**Expected**: 15+ tests for migration logic

### Integration Tests

**File**: `test/integration/migration_integration_test.dart` ✨ NEW

Test complete migration workflows:
1. v1.0.0 data → v1.2.0 (two-step migration)
2. v1.1.0 data → v1.2.0 (single-step migration)
3. Empty database → v1.2.0
4. Large dataset (1000 tasks) → v1.2.0
5. Mixed versions → v1.2.0

### Manual Testing Checklist

Before release:
- [ ] Fresh install creates v1.2.0 schema
- [ ] Upgrade from v1.0.0 succeeds
- [ ] Upgrade from v1.1.0 succeeds
- [ ] Migration is idempotent (can run multiple times)
- [ ] Completed tasks get completedAt timestamp
- [ ] Recurring tasks get streak data
- [ ] All existing task data preserved
- [ ] No crashes during or after migration
- [ ] Performance acceptable (migration < 5s for 1000 tasks)
- [ ] Rollback to v1.1.0 works (with expected data loss)

---

## Error Handling

### Migration Failures

#### Scenario 1: Database Locked
**Error**: `HiveError: Box is already open`  
**Handling**: 
- Retry migration after 1s delay
- Max retries: 3
- If still failing, continue app launch with warning

#### Scenario 2: Corrupted Task Data
**Error**: `FormatException` during task deserialization  
**Handling**:
- Log error with task ID
- Skip that task
- Continue with remaining tasks
- Show count of errors at end

#### Scenario 3: Insufficient Storage
**Error**: `FileSystemException: No space left on device`  
**Handling**:
- Abort migration
- Restore to pre-migration state
- Notify user of storage issue
- Suggest clearing archive or deleting tasks

#### Scenario 4: Crash During Migration
**Error**: App terminated mid-migration  
**Handling**:
- On restart, detect incomplete migration (version < 3 but partial updates)
- Rollback partial changes OR re-run migration (safe because idempotent)
- Validate data integrity after restart

### Recovery Procedures

```dart
static Future<void> recoverFromFailedMigration() async {
  AppLogger.warning('Attempting migration recovery...');
  
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt(VERSION_KEY) ?? 1;
  
  if (currentVersion < CURRENT_VERSION) {
    // Incomplete migration - try again
    try {
      await runMigrations();
      AppLogger.info('Migration recovery successful');
    } catch (e) {
      AppLogger.error('Migration recovery failed', e);
      // Continue with app in degraded mode
      // v1.2.0 features may not work, but v1.1.0 features will
    }
  }
}
```

---

## Rollback Procedure

### When to Rollback

Rollback from v1.2.0 to v1.1.0 if:
- Critical bugs in v1.2.0 features
- Performance degradation
- User preference
- Compatibility issues

### Rollback Steps

#### Step 1: Install v1.1.0 App
- User downloads v1.1.0 APK/IPA
- Installs over v1.2.0 (data preserved)

#### Step 2: Schema Compatibility
- v1.1.0 Hive adapters ignore fields 20-25
- v1.1.0 RecurrenceRule adapter ignores fields 4-8
- **No errors or crashes** - unknown fields safely ignored by Hive

#### Step 3: Data State After Rollback

**Preserved**:
- ✅ All tasks (active and archived shown as active)
- ✅ Titles, descriptions, priorities
- ✅ Hierarchy (parents, subtasks)
- ✅ Due dates
- ✅ Basic recurrence patterns
- ✅ Completion status

**Lost**:
- ❌ Archive status (all tasks active)
- ❌ Archive timestamps
- ❌ Completion timestamps
- ❌ Streak data
- ❌ Skip markers
- ❌ Advanced recurrence (reverts to basic)

#### Step 4: Schema Version Reset

**Optional** - Reset to v1.1.0 version:
```dart
// In v1.1.0 migration service
static Future<void> downgradeFromV3() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('schema_version', 2);
  await prefs.remove('v3_migration_completed');
  AppLogger.info('Downgraded to schema version 2');
}
```

### Rollback Testing

Before v1.2.0 release:
- [ ] Install v1.2.0 with data
- [ ] Install v1.1.0 over it
- [ ] Verify app launches
- [ ] Verify all tasks visible
- [ ] Verify no crashes
- [ ] Document what users lose on rollback

---

## Performance Considerations

### Migration Performance Targets

| Task Count | Migration Time | Memory Usage |
|-----------|---------------|--------------|
| 10 | <100ms | <1 MB |
| 100 | <500ms | <5 MB |
| 1,000 | <3s | <20 MB |
| 10,000 | <30s | <100 MB |

### Optimization Strategies

#### Batch Processing
```dart
// Process tasks in batches to avoid memory spikes
const BATCH_SIZE = 100;

for (int i = 0; i < tasks.length; i += BATCH_SIZE) {
  final batch = tasks.sublist(
    i, 
    min(i + BATCH_SIZE, tasks.length)
  );
  
  for (final task in batch) {
    // Process task...
  }
  
  // Allow GC between batches
  await Future.delayed(Duration(milliseconds: 10));
}
```

#### Progress Indication
```dart
// Show progress for large migrations
void _showMigrationProgress(int current, int total) {
  if (total > 100) {
    final percent = (current / total * 100).round();
    AppLogger.info('Migration progress: $percent% ($current/$total)');
    // Update UI progress bar if shown
  }
}
```

#### Background Migration
```dart
// For very large datasets, consider background migration
static Future<void> migrateInBackground() async {
  // Use compute() to run in isolate
  final result = await compute(_migrationWorker, migrationParams);
  // Handle result...
}

static Future<MigrationResult> _migrationWorker(MigrationParams params) async {
  // Migration logic runs in separate isolate
  // Returns result when complete
}
```

---

## Data Integrity Validation

### Pre-Migration Snapshot

```dart
static Future<Map<String, dynamic>> createPreMigrationSnapshot() async {
  final tasks = await _getAllTasks();
  
  return {
    'task_count': tasks.length,
    'completed_count': tasks.where((t) => t.isCompleted).length,
    'recurring_count': tasks.where((t) => t.isRecurring).length,
    'has_due_dates': tasks.where((t) => t.dueDate != null).length,
    'snapshot_time': DateTime.now().toIso8601String(),
    'schema_version': await getCurrentVersion(),
  };
}
```

### Post-Migration Validation

```dart
static Future<bool> validateMigration(Map<String, dynamic> snapshot) async {
  final tasks = await _getAllTasks();
  
  // Verify counts match
  if (tasks.length != snapshot['task_count']) {
    AppLogger.error('Task count mismatch after migration');
    return false;
  }
  
  // Verify all tasks have new fields
  final invalidTasks = tasks.where((task) {
    // Check for tasks missing required defaults
    if (task.isCompleted && task.completedAt == null) return true;
    if (task.isRecurring && task.currentStreak == null) return true;
    return false;
  }).toList();
  
  if (invalidTasks.isNotEmpty) {
    AppLogger.warning('${invalidTasks.length} tasks missing migrated fields');
    return false;
  }
  
  AppLogger.info('Migration validation successful');
  return true;
}
```

---

## User Communication

### Migration Notice

**During migration** (if visible to user):
```
┌─────────────────────────────────┐
│     Updating...                 │
│                                 │
│  [=====>            ]  35%      │
│                                 │
│  Preparing new features         │
│  This will take a few moments   │
└─────────────────────────────────┘
```

**Only show if migration >2 seconds**

### Post-Migration Notification

**First launch after v1.2.0 upgrade**:
```
┌─────────────────────────────────┐
│     What's New in v1.2.0        │
│                                 │
│ 🔍 Search tasks                 │
│    Find any task instantly      │
│                                 │
│ 🗄️ Archive completed tasks      │
│    Keep your list clean         │
│                                 │
│ 📊 Recurring task history       │
│    Track your progress          │
│                                 │
│ 🔄 Advanced recurrence          │
│    Complex repeat patterns      │
│                                 │
│ [Got it]          [Learn More]  │
└─────────────────────────────────┘
```

**Shown once**, dismissible, with link to full changelog

---

## Logging Strategy

### Migration Logs

**Log Levels**:
- `INFO`: Migration start, progress, completion
- `WARNING`: Skipped tasks, minor issues  
- `ERROR`: Failed migrations, data corruption

**Sample Log Output**:
```
[INFO] 16:40:23.234 - Starting migration to version 3 (v1.2.0)...
[INFO] 16:40:23.240 - Found 247 tasks to migrate
[INFO] 16:40:23.450 - Set completedAt for task: task-123
[INFO] 16:40:23.455 - Initialized streaks for recurring task: task-456
[INFO] 16:40:23.890 - Calculating streaks for 12 recurring tasks...
[INFO] 16:40:24.120 - Updated streaks for task-456: current=3, longest=5
[INFO] 16:40:24.500 - Validating task integrity...
[INFO] 16:40:24.750 - Task integrity validation completed.
[INFO] 16:40:24.800 - Migration to version 3 completed in 566ms
[INFO] 16:40:24.805 - Total: 247 tasks
[INFO] 16:40:24.810 - Migrated: 85 tasks
[INFO] 16:40:24.815 - Skipped: 162 tasks (no changes needed)
```

### Log Persistence

**Store logs**:
- Last 100 log entries in memory
- Migration logs saved to SharedPreferences
- Can export logs for debugging

**Access**:
- Settings → Advanced → Migration Logs
- Shows last migration details
- Export button for support tickets

---

## Backward Compatibility Testing

### Test Matrix

| From Version | To Version | Data Preserved | Features Work | Tested |
|-------------|------------|----------------|---------------|--------|
| v1.0.0 | v1.2.0 | ✅ All | ✅ All | [ ] |
| v1.1.0 | v1.2.0 | ✅ All | ✅ All | [ ] |
| v1.2.0 | v1.1.0 | ⚠️ Partial | ✅ v1.1.0 only | [ ] |
| v1.2.0 | v1.0.0 | ⚠️ Partial | ✅ v1.0.0 only | [ ] |

### Compatibility Guarantees

**Forward Compatibility** (v1.1.0 → v1.2.0):
- ✅ 100% data preservation
- ✅ All v1.1.0 features work identically
- ✅ New features additive only
- ✅ No breaking changes

**Backward Compatibility** (v1.2.0 → v1.1.0):
- ⚠️ Partial data preservation
- ✅ App doesn't crash
- ✅ Core features work
- ❌ v1.2.0-specific data lost

---

## Migration FAQs

### Q: Will my tasks be deleted during migration?
**A**: No. All tasks are preserved. Migration only adds new fields with default values.

### Q: Can I undo the migration?
**A**: You can install v1.1.0 again, but you'll lose v1.2.0-specific data (archives, streaks).

### Q: How long does migration take?
**A**: Usually <1 second for typical use (100-500 tasks). Large datasets (1000+) may take 2-5 seconds.

### Q: What if migration fails?
**A**: App continues to work with your existing data. v1.2.0 features may be unavailable until migration succeeds. You can retry migration from settings.

### Q: Will my recurring tasks break?
**A**: No. All existing basic recurrence patterns continue to work without changes.

### Q: Do I need to backup before upgrading?
**A**: Not required (migration is safe), but recommended for peace of mind.

---

## Release Checklist

### Pre-Release
- [ ] All migration tests passing
- [ ] Manual migration testing completed
- [ ] Performance testing completed
- [ ] Rollback tested successfully
- [ ] Migration logs reviewed
- [ ] Documentation complete

### Release
- [ ] Version number updated in pubspec.yaml
- [ ] Changelog updated
- [ ] Migration guide in app help
- [ ] Release notes published
- [ ] Backup recommendations in docs

### Post-Release
- [ ] Monitor migration success rates
- [ ] Track migration duration metrics
- [ ] Collect user feedback
- [ ] Address any migration issues
- [ ] Plan fixes for edge cases

---

## Summary

**Migration Safety**: ✅ **SAFE**
- Zero data loss on upgrade
- Graceful degradation on downgrade
- Comprehensive error handling
- Thorough testing required

**Migration Complexity**: ⚙️ **MEDIUM**
- Mostly auto-defaulting fields
- Some calculated fields (streaks)
- Well-tested migration patterns
- Clear rollback path

**User Impact**: 📱 **MINIMAL**
- Transparent to users
- Brief delay on first launch (<5s typical)
- No user action required
- Can continue using app during migration

**Risk Level**: 🟢 **LOW**
- Proven migration patterns from v1.1.0
- Extensive testing planned
- Rollback available
- No breaking changes

---

**Status**: MIGRATION STRATEGY COMPLETE
**Ready for**: Implementation