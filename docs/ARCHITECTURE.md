# Flutter Task Management App - Technical Architecture

## Project Overview

A basic task management mobile application built with Flutter, featuring local data persistence, intuitive UI, and cross-platform support (iOS & Android).

**Technology Stack:**
- **Framework:** Flutter (Latest stable version)
- **State Management:** Provider
- **Data Persistence:** Hive (NoSQL database)
- **UI Design:** Material Design 3
- **Platforms:** iOS & Android

---

## 1. App Architecture Overview

### 1.1 Architecture Pattern

The app follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│         Presentation Layer (UI)             │
│  - Screens/Pages                            │
│  - Widgets                                  │
│  - UI State Management                      │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│      Business Logic Layer (Providers)       │
│  - TaskProvider (State Management)          │
│  - Business Rules                           │
│  - Data Transformation                      │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│       Data Layer (Models & Services)        │
│  - Task Model                               │
│  - TaskService (Hive Operations)            │
│  - SearchService (Search & Filters)         │
│  - RecurringTaskService (Stats & History)   │
│  - MigrationService (Data Migrations)       │
│  - Data Persistence                         │
└─────────────────────────────────────────────┘
```

**v1.2.0 Architecture Enhancements:**
- Added [`SearchService`](../lib/services/search_service.dart) for full-text search and filtering
- Added [`RecurringTaskService`](../lib/services/recurring_task_service.dart) for recurring task analytics
- Enhanced [`MigrationService`](../lib/services/migration_service.dart) with v3 migration support
- New models: [`SearchQuery`](../lib/models/search_query.dart), [`RecurringTaskStats`](../lib/models/recurring_task_stats.dart)

### 1.2 Design Principles

- **Single Responsibility:** Each class/file has one clear purpose
- **Provider Pattern:** For state management and dependency injection
- **Repository Pattern:** TaskService acts as data access layer
- **Separation of Concerns:** UI, business logic, and data layers are distinct
- **Type Safety:** Use Hive TypeAdapters for type-safe data persistence

### 1.3 State Management Strategy (Provider)

**Why Provider?**
- Official Flutter team recommendation
- Simple learning curve
- Excellent for small to medium apps
- Built-in dependency injection
- Good testing support

**Provider Structure:**
- [`TaskProvider`](lib/providers/task_provider.dart): Main state management class
  - Manages task list state
  - Handles CRUD operations
  - Notifies listeners of state changes
- [`MultiProvider`](lib/main.dart): Root-level provider setup
- [`Consumer`](lib/screens/): UI widgets that react to state changes

---

## 2. Core Features Definition

### 2.1 Essential Features

#### Feature 1: Task List View
- Display all tasks in a scrollable list
- Show task completion status visually
- Empty state when no tasks exist
- Pull-to-refresh capability

#### Feature 2: Create Task
- Floating action button for quick task creation
- Modal bottom sheet or full screen form
- Input fields: title (required), description (optional)
- Auto-save on creation

#### Feature 3: Update Task
- Edit task details (title, description)
- Toggle completion status (tap on checkbox)
- Inline editing or full screen form
- Auto-save on update

#### Feature 4: Delete Task
- Swipe-to-delete gesture
- Delete confirmation dialog
- Undo option (optional for v1)

#### Feature 5: Task Filtering
- View all tasks
- View active (incomplete) tasks
- View completed tasks
- Simple tab-based navigation

#### Feature 6: Data Persistence
- Automatic save on every change
- Data survives app restarts
- Fast load times with Hive

### 2.2 Task Properties

```dart
class Task {
  String id;                  // Unique identifier (UUID)
  String title;               // Task title (required, max 100 chars)
  String description;         // Task description (optional, max 500 chars)
  bool isCompleted;          // Completion status (default: false)
  DateTime createdAt;        // Creation timestamp
  DateTime? updatedAt;       // Last update timestamp (nullable)
  int priority;              // Priority level (0=low, 1=medium, 2=high)
}
```

**Property Details:**
- **id:** Generated using [`uuid`](https://pub.dev/packages/uuid) package
- **title:** Required field, user-facing task name
- **description:** Optional, provides additional context
- **isCompleted:** Boolean flag for completion status
- **createdAt:** Automatically set on creation
- **updatedAt:** Updated whenever task is modified
- **priority:** Optional feature for basic prioritization

### 2.3 UI/UX Considerations

#### Mobile-First Design
- **Thumb-friendly zones:** Action buttons within easy reach
- **Gesture support:** Swipe to delete, tap to toggle
- **Large touch targets:** Minimum 48x48 logical pixels
- **Responsive layouts:** Adapts to different screen sizes

#### Material Design 3 Components
- **AppBar:** Top navigation with title and actions
- **FloatingActionButton:** Primary action (add task)
- **Card/ListTile:** Task list items
- **Checkbox:** Task completion toggle
- **BottomSheet/Dialog:** Task creation/editing
- **SnackBar:** Feedback messages
- **TabBar:** Filter navigation (All/Active/Completed)

#### Color Scheme
- **Primary Color:** Material blue (default)
- **Surface Color:** White/dark background
- **Completed Tasks:** Gray text with strikethrough
- **Active Tasks:** Full color text

#### User Flow
```
App Launch
    ↓
Task List Screen (Home)
    ↓
┌───────────────┬───────────────┬───────────────┐
│ Tap FAB       │ Tap Task      │ Swipe Task    │
│ Create New    │ Edit/Toggle   │ Delete        │
└───────────────┴───────────────┴───────────────┘
```

---

## 3. Technical Specifications

### 3.1 Flutter Project Structure

```
task_app/
├── lib/
│   ├── main.dart                 # App entry point, provider setup
│   ├── models/
│   │   └── task.dart            # Task data model with Hive annotations
│   ├── providers/
│   │   └── task_provider.dart   # Task state management
│   ├── services/
│   │   └── task_service.dart    # Hive database operations
│   ├── screens/
│   │   ├── task_list_screen.dart    # Main screen with task list
│   │   └── task_form_screen.dart    # Create/edit task screen
│   ├── widgets/
│   │   ├── task_item.dart          # Individual task list item
│   │   ├── empty_state.dart        # Empty list placeholder
│   │   └── task_filter_tabs.dart   # Filter tabs widget
│   └── utils/
│       ├── constants.dart          # App constants (colors, strings)
│       └── date_formatter.dart     # Date formatting utilities
├── test/
│   ├── unit/
│   │   ├── models/
│   │   │   └── task_test.dart
│   │   └── providers/
│   │       └── task_provider_test.dart
│   └── widget/
│       └── task_item_test.dart
├── pubspec.yaml                  # Dependencies
├── analysis_options.yaml         # Linter rules
└── README.md                     # Project documentation
```

### 3.2 Required Dependencies

**pubspec.yaml:**

```yaml
name: task_app
description: A basic task management Flutter application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.0
  
  # Data Persistence
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Utilities
  uuid: ^4.0.0
  intl: ^0.18.0              # Date formatting
  
  # UI
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation (Hive)
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
  
  # Linting
  flutter_lints: ^3.0.0
  
  # Testing
  mockito: ^5.4.0
```

**Dependency Justifications:**

1. **provider (^6.1.0)**
   - Purpose: State management and dependency injection
   - Benefits: Simple API, official recommendation, excellent performance

2. **hive (^2.2.3) & hive_flutter (^1.1.0)**
   - Purpose: Local NoSQL database
   - Benefits: Fast, lightweight, no native dependencies, type-safe
   - Features: Box-based storage, lazy loading, encryption support

3. **uuid (^4.0.0)**
   - Purpose: Generate unique task IDs
   - Benefits: Standard UUID generation, collision-resistant

4. **intl (^0.18.0)**
   - Purpose: Date/time formatting and localization
   - Benefits: Proper date formatting, internationalization ready

5. **hive_generator (^2.0.1) & build_runner (^2.4.6)**
   - Purpose: Code generation for Hive TypeAdapters
   - Benefits: Type-safe serialization, reduces boilerplate

### 3.3 Data Persistence Strategy (Hive)

#### Why Hive?
- **Fast:** Pure Dart implementation, no native bridge
- **Lightweight:** Minimal dependencies, small binary size
- **Easy:** Simple API, no SQL knowledge required
- **Type-Safe:** Code generation with TypeAdapters
- **Cross-Platform:** Works identically on iOS and Android

#### Hive Implementation Plan

**Step 1: Initialize Hive**
```dart
// In main.dart
await Hive.initFlutter();
Hive.registerAdapter(TaskAdapter());
await Hive.openBox<Task>('tasks');
```

**Step 2: Define Task Model with Hive Annotations**
```dart
// In models/task.dart
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  bool isCompleted;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  DateTime? updatedAt;
  
  @HiveField(6)
  int priority;
}
```

**Step 3: Generate TypeAdapter**
```bash
flutter packages pub run build_runner build
```

**Step 4: Create TaskService for CRUD Operations**
```dart
// In services/task_service.dart
class TaskService {
  final Box<Task> _taskBox;
  
  // CRUD methods:
  // - Future<void> addTask(Task task)
  // - Future<void> updateTask(Task task)
  // - Future<void> deleteTask(String id)
  // - List<Task> getAllTasks()
  // - Task? getTaskById(String id)
}
```

#### Data Flow

```
User Action (UI)
    ↓
TaskProvider (Business Logic)
    ↓
TaskService (Data Layer)
    ↓
Hive Box (Persistence)
    ↓
File System (Storage)
```

### 3.4 State Management Implementation

#### Provider Architecture

**1. TaskProvider (ChangeNotifier)**

```dart
class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  
  // Getters
  List<Task> get tasks => _getFilteredTasks();
  TaskFilter get filter => _filter;
  
  // Methods
  Future<void> loadTasks() { }
  Future<void> addTask(Task task) { }
  Future<void> updateTask(Task task) { }
  Future<void> deleteTask(String id) { }
  void setFilter(TaskFilter filter) { }
  
  // Private helpers
  List<Task> _getFilteredTasks() { }
}
```

**2. Provider Setup in main.dart**

```dart
void main() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(TaskService())..loadTasks(),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

**3. Consuming Provider in Widgets**

```dart
// Method 1: Consumer widget
Consumer<TaskProvider>(
  builder: (context, taskProvider, child) {
    return ListView.builder(
      itemCount: taskProvider.tasks.length,
      itemBuilder: (context, index) => TaskItem(taskProvider.tasks[index]),
    );
  },
)

// Method 2: Provider.of
final taskProvider = Provider.of<TaskProvider>(context);
taskProvider.addTask(newTask);

// Method 3: context.read (for actions without rebuilds)
context.read<TaskProvider>().deleteTask(taskId);

// Method 4: context.watch (for reactive state)
final tasks = context.watch<TaskProvider>().tasks;
```

---

## 4. Implementation Roadmap

### Phase 1: Project Setup & Foundation (Day 1)

#### Step 1: Create Flutter Project
```bash
flutter create task_app
cd task_app
```

#### Step 2: Configure Dependencies
- Update [`pubspec.yaml`](pubspec.yaml) with required dependencies
- Run `flutter pub get`

#### Step 3: Setup Project Structure
- Create directory structure (models, providers, services, screens, widgets, utils)
- Create placeholder files for main components

#### Step 4: Configure Linting
- Update [`analysis_options.yaml`](analysis_options.yaml) with Flutter lints
- Enable strict type checking

**Deliverables:**
- ✅ Clean project structure
- ✅ All dependencies installed
- ✅ Linting configured

---

### Phase 2: Data Layer Implementation (Day 2)

#### Step 5: Create Task Model
**File:** [`lib/models/task.dart`](lib/models/task.dart)

**Implementation:**
- Define `Task` class with Hive annotations
- Add constructor, copyWith, toMap, fromMap methods
- Add equality operators (==, hashCode)

**Key Methods:**
```dart
- Task({required this.id, required this.title, ...})
- Task copyWith({String? title, bool? isCompleted, ...})
- Map<String, dynamic> toMap()
- factory Task.fromMap(Map<String, dynamic> map)
- @override bool operator ==(Object other)
- @override int get hashCode
```

#### Step 6: Generate Hive TypeAdapter
**Command:** `flutter packages pub run build_runner build`

**Expected Output:** `lib/models/task.g.dart` (auto-generated)

#### Step 7: Create TaskService
**File:** [`lib/services/task_service.dart`](lib/services/task_service.dart)

**Implementation:**
- Initialize Hive box in constructor
- Implement CRUD operations
- Add error handling
- Add transaction support for batch operations

**Key Methods:**
```dart
- TaskService() // Initialize and open box
- Future<void> addTask(Task task)
- Future<void> updateTask(Task task)
- Future<void> deleteTask(String id)
- List<Task> getAllTasks()
- Task? getTaskById(String id)
- Future<void> deleteAllTasks() // For testing/reset
```

**Deliverables:**
- ✅ Task model with Hive support
- ✅ Generated TypeAdapter
- ✅ TaskService with full CRUD operations
- ✅ Unit tests for TaskService

---

### Phase 3: Business Logic Layer (Day 3)

#### Step 8: Create TaskProvider
**File:** [`lib/providers/task_provider.dart`](lib/providers/task_provider.dart)

**Implementation:**
- Extend `ChangeNotifier`
- Inject `TaskService` via constructor
- Implement task management methods
- Add filtering logic
- Add error handling and loading states

**Key Methods:**
```dart
- TaskProvider(this._taskService)
- Future<void> loadTasks()
- Future<void> addTask(String title, String description, int priority)
- Future<void> updateTask(Task task)
- Future<void> toggleTaskCompletion(String id)
- Future<void> deleteTask(String id)
- void setFilter(TaskFilter filter)
- List<Task> _getFilteredTasks()
```

**State Properties:**
```dart
- List<Task> _tasks
- TaskFilter _filter
- bool _isLoading
- String? _errorMessage
```

#### Step 9: Create Utility Classes
**Files:**
- [`lib/utils/constants.dart`](lib/utils/constants.dart) - App constants
- [`lib/utils/date_formatter.dart`](lib/utils/date_formatter.dart) - Date utilities

**Constants to define:**
- Color schemes
- Text styles
- String constants (titles, messages)
- Spacing/padding values
- Animation durations

**Date formatter methods:**
- Format for display (e.g., "Jan 15, 2024")
- Relative time (e.g., "2 hours ago")
- Time only (e.g., "3:45 PM")

**Deliverables:**
- ✅ TaskProvider with state management
- ✅ Utility classes for constants and formatting
- ✅ Unit tests for TaskProvider

---

### Phase 4: UI Layer - Widgets (Day 4)

#### Step 10: Create TaskItem Widget
**File:** [`lib/widgets/task_item.dart`](lib/widgets/task_item.dart)

**Features:**
- Display task title, description, date
- Checkbox for completion toggle
- Strike-through for completed tasks
- Swipe-to-delete gesture (Dismissible widget)
- Tap to edit navigation

**Key Components:**
```dart
- Dismissible (for swipe-to-delete)
- ListTile or Card (container)
- Checkbox (completion toggle)
- Text widgets (title, description)
- IconButton (optional actions)
```

#### Step 11: Create EmptyState Widget
**File:** [`lib/widgets/empty_state.dart`](lib/widgets/empty_state.dart)

**Features:**
- Friendly empty state illustration
- Encouraging message
- CTA button to add first task

#### Step 12: Create TaskFilterTabs Widget
**File:** [`lib/widgets/task_filter_tabs.dart`](lib/widgets/task_filter_tabs.dart)

**Features:**
- Three tabs: All, Active, Completed
- Visual indication of active filter
- Smooth tab transitions

**Deliverables:**
- ✅ Reusable TaskItem widget
- ✅ EmptyState widget
- ✅ TaskFilterTabs widget
- ✅ Widget tests for each component

---

### Phase 5: UI Layer - Screens (Day 5)

#### Step 13: Create TaskListScreen
**File:** [`lib/screens/task_list_screen.dart`](lib/screens/task_list_screen.dart)

**Structure:**
- Scaffold with AppBar
- TaskFilterTabs at top
- ListView.builder for tasks
- FloatingActionButton for adding tasks
- EmptyState when no tasks
- Pull-to-refresh

**Key Components:**
```dart
- AppBar (title, actions)
- TaskFilterTabs
- Consumer<TaskProvider> or context.watch
- ListView.builder or ListView.separated
- RefreshIndicator
- FloatingActionButton
- EmptyState (conditional)
```

#### Step 14: Create TaskFormScreen
**File:** [`lib/screens/task_form_screen.dart`](lib/screens/task_form_screen.dart)

**Features:**
- Form for creating/editing tasks
- Text fields: title (required), description (optional)
- Priority selector (optional)
- Save and cancel buttons
- Form validation
- Auto-focus on title field

**Key Components:**
```dart
- Form widget
- TextFormField (title, description)
- DropdownButton or SegmentedButton (priority)
- ElevatedButton (save)
- TextButton (cancel)
- Form validation
```

**Two modes:**
1. Create mode: Empty form
2. Edit mode: Pre-filled with existing task data

**Deliverables:**
- ✅ TaskListScreen with filtering
- ✅ TaskFormScreen for CRUD
- ✅ Navigation between screens
- ✅ Widget tests for screens

---

### Phase 6: App Integration (Day 6)

#### Step 15: Configure main.dart
**File:** [`lib/main.dart`](lib/main.dart)

**Implementation:**
- Initialize Hive
- Register TypeAdapters
- Setup MultiProvider
- Configure MaterialApp with theme
- Set TaskListScreen as home

**Key Code:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(TaskService())..loadTasks(),
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.system,
        home: TaskListScreen(),
      ),
    );
  }
}
```

#### Step 16: Wire Up Navigation
- Implement navigation from TaskListScreen to TaskFormScreen
- Pass task data for edit mode
- Return result from TaskFormScreen
- Handle navigation pop

**Navigation Code:**
```dart
// Navigate to create
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TaskFormScreen(),
  ),
);

// Navigate to edit
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TaskFormScreen(task: existingTask),
  ),
);
```

#### Step 17: Add Error Handling
- Try-catch blocks in async methods
- User-friendly error messages
- SnackBar for feedback
- Loading indicators during operations

**Deliverables:**
- ✅ Fully integrated app
- ✅ Working navigation
- ✅ Error handling
- ✅ Loading states

---

### Phase 7: Testing & Polish (Day 7)

#### Step 18: Unit Tests
**Files:**
- [`test/unit/models/task_test.dart`](test/unit/models/task_test.dart)
- [`test/unit/providers/task_provider_test.dart`](test/unit/providers/task_provider_test.dart)

**Test Coverage:**
- Task model methods (copyWith, equality)
- TaskProvider CRUD operations
- TaskProvider filtering
- Edge cases and error handling

#### Step 19: Widget Tests
**Files:**
- [`test/widget/task_item_test.dart`](test/widget/task_item_test.dart)
- [`test/widget/task_list_screen_test.dart`](test/widget/task_list_screen_test.dart)

**Test Coverage:**
- TaskItem rendering and interactions
- TaskListScreen with different states
- TaskFormScreen validation
- Navigation flows

#### Step 20: Polish & Optimization
- Add animations (hero transitions, fade-ins)
- Optimize ListView performance
- Add haptic feedback for interactions
- Improve accessibility (semantic labels)
- Test on multiple screen sizes
- Test on iOS and Android devices

**Deliverables:**
- ✅ Comprehensive test suite
- ✅ Code coverage report
- ✅ Performance optimizations
- ✅ Accessibility improvements

---

### Phase 8: Documentation & Deployment (Day 8)

#### Step 21: Update README.md
**Sections:**
- App description
- Features list
- Screenshots
- Setup instructions
- Build instructions
- Tech stack

#### Step 22: Add Code Documentation
- Dartdoc comments for public APIs
- Inline comments for complex logic
- Usage examples in key files

#### Step 23: Build Release APK/IPA
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

#### Step 24: Final Testing
- Test on physical devices
- Test different screen sizes
- Test orientation changes
- Test offline functionality
- Test app lifecycle (pause/resume)

**Deliverables:**
- ✅ Complete documentation
- ✅ Release builds
- ✅ Final QA passed
- ✅ App ready for distribution

---

## 5. File Implementation Order

**Recommended sequence for implementation:**

```
1.  pubspec.yaml                      # Dependencies
2.  lib/utils/constants.dart          # Constants
3.  lib/models/task.dart              # Data model
4.  [Run build_runner]                # Generate TypeAdapter
5.  lib/services/task_service.dart    # Data persistence
6.  lib/providers/task_provider.dart  # State management
7.  lib/utils/date_formatter.dart     # Utilities
8.  lib/widgets/empty_state.dart      # Simple widget first
9.  lib/widgets/task_item.dart        # Core widget
10. lib/widgets/task_filter_tabs.dart # Filter widget
11. lib/screens/task_form_screen.dart # Form screen
12. lib/screens/task_list_screen.dart # Main screen
13. lib/main.dart                     # App entry point
14. test/unit/models/task_test.dart   # Tests
15. test/unit/providers/task_provider_test.dart
16. test/widget/task_item_test.dart
17. README.md                         # Documentation
```

---

## 6. Key Design Decisions

### 6.1 Why Provider over BLoC?
- **Simplicity:** Less boilerplate, easier to understand
- **Official support:** Recommended by Flutter team
- **Sufficient for scope:** Task management doesn't require complex state logic
- **Learning curve:** Faster onboarding for new developers
- **Performance:** Adequate for the app's scale

### 6.2 Why Hive over SQLite?
- **No SQL required:** Simpler mental model
- **Pure Dart:** No native dependencies, easier to debug
- **Performance:** Faster for simple CRUD operations
- **Type safety:** Code generation ensures compile-time safety
- **Size:** Smaller binary size compared to SQLite plugins

### 6.3 Why Material 3?
- **Modern design:** Latest design system from Google
- **Consistency:** Familiar patterns for Android users
- **Accessibility:** Built-in accessibility features
- **Theming:** Easy to customize and extend
- **Documentation:** Extensive guidelines and examples

### 6.4 Data Persistence Strategy
- **Local-first:** No network dependency
- **Immediate consistency:** Changes persist immediately
- **Box-based storage:** Simple key-value paradigm
- **Type-safe:** Compile-time guarantees via code generation

---

## 7. Services Architecture (v1.2.0)

### 7.1 TaskService
**File:** [`lib/services/task_service.dart`](../lib/services/task_service.dart)

**Responsibilities:**
- Core CRUD operations for tasks
- Hive database management
- Task archiving operations
- Recurring task instance creation
- Due date sorting and filtering

**Key Methods:**
```dart
// Basic CRUD
Future<void> addTask(Task task)
Future<void> updateTask(Task task)
Future<void> deleteTask(String id)
List<Task> getAllTasks()
Task? getTaskById(String id)

// Archive operations (v1.2.0)
Future<void> archiveTask(String taskId)
Future<void> unarchiveTask(String taskId)
Future<void> archiveMultipleTasks(List<String> taskIds)
List<Task> getArchivedTasks()
Future<void> deleteArchivedTask(String taskId)
Future<void> clearArchive()
Future<void> autoArchiveOldCompletedTasks({int daysThreshold = 30})

// Recurring tasks
Future<Task?> createNextRecurringInstance(Task completedTask)
Future<void> updateRecurringTaskStreak(Task task)
List<Task> getRecurringTaskInstances(String parentId)
```

### 7.2 SearchService (v1.2.0)
**File:** [`lib/services/search_service.dart`](../lib/services/search_service.dart)

**Responsibilities:**
- Full-text search across task titles and descriptions
- Advanced filtering by multiple criteria
- Search history management
- Relevance scoring for results

**Key Methods:**
```dart
// Core search
List<Task> searchTasks(String query, List<Task> tasks)
List<Task> searchWithFilters({
  String? text,
  List<TaskType>? taskTypes,
  List<int>? priorities,
  List<TaskContext>? contexts,
  bool? isCompleted,
  bool? isRecurring,
  required List<Task> tasks,
})

// Search history
Future<void> saveRecentSearch(String query)
Future<List<SearchQuery>> getRecentSearches({int limit = 10})
Future<void> clearSearchHistory()
```

**Search Algorithm:**
- Exact title matches score 1000 points
- Partial title matches score 500 points
- Description matches score 100 points
- Results sorted by relevance score descending

**Performance:**
- Target: <200ms for 1000 tasks
- Uses efficient string matching
- Results capped at reasonable limit

### 7.3 RecurringTaskService (v1.2.0)
**File:** [`lib/services/recurring_task_service.dart`](../lib/services/recurring_task_service.dart)

**Responsibilities:**
- Calculate comprehensive statistics for recurring tasks
- Track completion rates and streaks
- Manage recurring task instances (skip, reschedule)
- Filter instances by status (completed, pending, missed)

**Key Methods:**
```dart
// Statistics
Future<RecurringTaskStats> getRecurringTaskStats(String parentId, List<Task> allTasks)
double calculateCompletionRate(List<Task> instances)
int calculateCurrentStreak(List<Task> instances)
int calculateLongestStreak(List<Task> instances)
List<DateTime> getRecentCompletions(List<Task> instances, {int limit = 10})

// Instance management
Task skipInstance(Task instance)
Task rescheduleInstance(Task instance, DateTime newDueDate)
List<Task> updateFutureInstances(String parentId, List<Task> allTasks, Task template)

// Instance filtering
List<Task> getCompletedInstances(String parentId, List<Task> allTasks)
List<Task> getPendingInstances(String parentId, List<Task> allTasks)
List<Task> getMissedInstances(String parentId, List<Task> allTasks)
List<Task> getAllInstances(String parentId, List<Task> allTasks, {DateTime? startDate, DateTime? endDate})
```

**Statistics Calculated:**
- Total instances created
- Completed/skipped/missed/pending counts
- Completion rate (excludes pending)
- Current consecutive streak
- Longest streak in history
- Recent completion dates

**Performance:**
- Target: <500ms for 1000 instances
- Efficient sorting and filtering
- Cached calculations where possible

### 7.4 MigrationService
**File:** [`lib/services/migration_service.dart`](../lib/services/migration_service.dart)

**Responsibilities:**
- Data schema migrations between versions
- Backward compatibility preservation
- Data integrity validation
- Migration status tracking

**Migration History:**
- **v2 Migration:** Added hierarchy (subtasks), batch metadata
- **v3 Migration (v1.2.0):** Added archive support, streak tracking, skip status

**v3 Migration Details:**
```dart
// New fields added in v3:
- isArchived: bool (default false)
- archivedAt: DateTime? (default null)
- completedAt: DateTime? (set for existing completed tasks)
- currentStreak: int (calculated from instances)
- longestStreak: int (calculated from history)
- isSkipped: bool (default false)
```

**Key Methods:**
```dart
static Future<bool> needsMigrationToV3()
static Future<void> migrateToVersion3()
static Future<void> validateTaskIntegrity(List<Task> tasks)
static Future<int> getSchemaVersion()
```

**Migration Process:**
1. Check schema version from SharedPreferences
2. Load all existing tasks from Hive
3. Add new fields with appropriate defaults
4. Calculate initial streak values for recurring tasks
5. Validate data integrity
6. Save updated tasks back to Hive
7. Update schema version marker

**Performance:**
- Target: <5s for 1000 tasks
- Runs once per version upgrade
- Non-blocking with progress indication

## 8. Models Architecture (v1.2.0)

### 8.1 Core Models

**Task Model** - [`lib/models/task.dart`](../lib/models/task.dart)
```dart
@HiveType(typeId: 0)
class Task extends HiveObject {
  // Core fields
  @HiveField(0) final String id;
  @HiveField(1) String title;
  @HiveField(2) String? description;
  @HiveField(3) bool isCompleted;
  @HiveField(4) DateTime createdAt;
  @HiveField(5) DateTime updatedAt;
  @HiveField(6) int priority;
  
  // Hierarchy (v1.1.0)
  @HiveField(7) String? parentTaskId;
  @HiveField(8) List<String> subtaskIds;
  @HiveField(9) int nestingLevel;
  @HiveField(10) int sortOrder;
  
  // Batch metadata (v1.1.0)
  @HiveField(11) TaskType taskType;
  @HiveField(12) List<RequiredResource> requiredResources;
  @HiveField(13) TaskContext taskContext;
  @HiveField(14) EnergyLevel energyRequired;
  @HiveField(15) TimeEstimate timeEstimate;
  
  // Due dates & recurrence (v1.1.0)
  @HiveField(16) DateTime? dueDate;
  @HiveField(17) RecurrenceRule? recurrenceRule;
  @HiveField(18) String? parentRecurringTaskId;
  
  // Archive support (v1.2.0)
  @HiveField(19) bool isArchived;
  @HiveField(20) DateTime? archivedAt;
  @HiveField(21) DateTime? completedAt;
  
  // Streak tracking (v1.2.0)
  @HiveField(22) int currentStreak;
  @HiveField(23) int longestStreak;
  @HiveField(24) bool isSkipped;
}
```

### 8.2 Supporting Models (v1.2.0)

**SearchQuery** - [`lib/models/search_query.dart`](../lib/models/search_query.dart)
```dart
class SearchQuery {
  final String text;
  final List<TaskType>? taskTypes;
  final List<int>? priorities;
  final List<TaskContext>? contexts;
  final bool? isCompleted;
  final bool? isRecurring;
  final DateTime timestamp;
  
  // Serialization for SharedPreferences
  Map<String, dynamic> toJson()
  factory SearchQuery.fromJson(Map<String, dynamic> json)
}
```

**RecurringTaskStats** - [`lib/models/recurring_task_stats.dart`](../lib/models/recurring_task_stats.dart)
```dart
class RecurringTaskStats {
  final String parentTaskId;
  final int totalInstances;
  final int completedInstances;
  final int skippedInstances;
  final int missedInstances;
  final int pendingInstances;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedAt;
  final DateTime? nextDueDate;
  final List<DateTime> recentCompletions;
  
  // Computed properties
  double get completionPercentage => completionRate * 100;
  bool get hasGoodCompletionRate => completionRate > 0.8;
  bool get hasActiveStreak => currentStreak > 0;
  int get eligibleInstances => totalInstances - pendingInstances;
}
```

## 9. Future Enhancements

**Potential features for future versions:**

1. **Categories/Tags:** Organize tasks into categories
2. **Dark Mode Toggle:** Manual theme switching
3. **Export/Import:** Backup tasks to JSON/CSV
4. **Widgets:** Home screen widget (Android/iOS)
5. **Sharing:** Share tasks via text/email
6. **Cloud Sync:** Optional backend synchronization
7. **Multi-language:** i18n support
8. **Notifications:** Push notifications for reminders
9. **Collaboration:** Multi-user task sharing
10. **Voice Input:** Create tasks via voice commands

---

## 8. Performance Considerations

### 8.1 Optimization Strategies
- **Lazy loading:** Use ListView.builder for efficient scrolling
- **Selective rebuilds:** Consumer with child parameter
- **Debouncing:** Delay rapid state changes (search input)
- **Box lazy loading:** Load Hive boxes on-demand
- **Image caching:** If adding images in future

### 8.2 Memory Management
- **Dispose controllers:** TextEditingController cleanup
- **Close boxes:** Proper Hive box closure on app exit
- **Remove listeners:** Unsubscribe from providers when widgets dispose

### 8.3 Expected Performance Metrics
- **App startup:** < 1 second cold start
- **Task list load:** < 100ms for 1000 tasks
- **CRUD operations:** < 50ms per operation
- **UI interactions:** 60 FPS smooth scrolling

---

## 9. Testing Strategy

### 9.1 Unit Tests
**Coverage targets: 80%+**

**Test cases:**
- Task model serialization/deserialization
- TaskService CRUD operations
- TaskProvider state management
- Filtering logic
- Date formatting utilities

### 9.2 Widget Tests
**Coverage targets: 70%+**

**Test cases:**
- TaskItem rendering with different states
- TaskFormScreen validation
- TaskListScreen with empty/populated states
- Filter tab switching
- Navigation flows

### 9.3 Integration Tests
**Manual testing checklist:**
- End-to-end task creation flow
- Task editing and deletion
- Filter switching
- App lifecycle (background/foreground)
- Platform-specific behaviors (iOS/Android)

---

## 10. Code Quality Standards

### 10.1 Linting Rules
- Enable `flutter_lints` package
- Enforce strong type checking
- Require documentation comments
- Limit line length to 80 characters
- Use trailing commas for formatting

### 10.2 Naming Conventions
- **Classes:** PascalCase (TaskProvider)
- **Files:** snake_case (task_provider.dart)
- **Variables:** camelCase (taskList)
- **Constants:** lowerCamelCase with const (defaultPadding)
- **Private members:** Leading underscore (_tasks)

### 10.3 Code Organization
- One class per file
- Group imports (Dart, Flutter, Package, Relative)
- Consistent file structure (fields, constructor, methods)
- Prefer composition over inheritance

---

## 11. Security Considerations

### 11.1 Data Security
- **Local storage only:** No sensitive data transmission
- **Encryption option:** Hive supports encrypted boxes (future enhancement)
- **No PII:** Task data is user-generated, no personal info required

### 11.2 App Permissions
- **Minimal permissions:** No special permissions required
- **Storage access:** Implicit through app sandbox
- **No network access:** Fully offline app

---

## 12. Accessibility

### 12.1 Requirements
- **Semantic labels:** Provide meaningful labels for screen readers
- **Contrast ratios:** Meet WCAG 2.1 AA standards (4.5:1)
- **Touch targets:** Minimum 48x48 logical pixels
- **Focus indicators:** Visible keyboard navigation
- **Text scaling:** Support dynamic font sizes

### 12.2 Implementation
```dart
// Example semantic label
Semantics(
  label: 'Mark task as complete',
  child: Checkbox(
    value: task.isCompleted,
    onChanged: (value) => onToggle(),
  ),
)
```

---

## 13. Conclusion

This architecture provides a solid foundation for a Flutter task management app that is:

- **Simple:** Easy to understand and maintain
- **Scalable:** Can grow with additional features
- **Performant:** Fast and responsive user experience
- **Testable:** Clear separation enables comprehensive testing
- **Cross-platform:** Works seamlessly on iOS and Android

The layered architecture with Provider for state management and Hive for persistence offers the right balance of simplicity and capability for a basic task management application.

---

## 14. Quick Reference

### Project Commands
```bash
# Create project
flutter create task_app

# Get dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build

# Run app
flutter run

# Run tests
flutter test

# Build release
flutter build apk --release  # Android
flutter build ios --release  # iOS

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Key File Paths
- Entry point: [`lib/main.dart`](lib/main.dart)
- Models: [`lib/models/task.dart`](lib/models/task.dart)
- Provider: [`lib/providers/task_provider.dart`](lib/providers/task_provider.dart)
- Service: [`lib/services/task_service.dart`](lib/services/task_service.dart)
- Screens: [`lib/screens/`](lib/screens/)
- Widgets: [`lib/widgets/`](lib/widgets/)

### Important Notes
- Run build_runner after modifying Hive models
- Always call `notifyListeners()` in TaskProvider after state changes
- Use `context.read()` for actions, `context.watch()` for reactive UI
- Close Hive boxes in app disposal
- Test on both iOS and Android regularly

---

---

## 15. v1.2.0 Feature Integration

### 15.1 Search Integration Flow
```
User enters search query
    ↓
SearchBarWidget captures input
    ↓
SearchService.searchTasks(query, tasks)
    ↓
Apply filters if selected
    ↓
Sort by relevance score
    ↓
Display results in SearchResultItem widgets
    ↓
Save to search history
```

### 15.2 Archive Integration Flow
```
Task completion
    ↓
User taps archive OR auto-archive triggers
    ↓
TaskService.archiveTask(taskId)
    ↓
Update Task: isArchived = true, archivedAt = now
    ↓
TaskProvider notifies listeners
    ↓
UI updates to hide from active list
    ↓
Task visible in Archive screen
```

### 15.3 Recurring History Integration Flow
```
User taps recurring task
    ↓
Navigate to RecurringTaskDetailScreen
    ↓
Load instances: TaskProvider.getInstancesForParent()
    ↓
Calculate stats: RecurringTaskService.getRecurringTaskStats()
    ↓
Display in RecurringStatsCard
    ↓
Show timeline in InstanceTimelineItem list
    ↓
User can skip/reschedule instances
```

### 15.4 Data Migration Flow (v3)
```
App startup
    ↓
Check MigrationService.needsMigrationToV3()
    ↓
If needed: Run MigrationService.migrateToVersion3()
    ↓
Phase 1: Add new fields with defaults
    ↓
Phase 2: Calculate streaks for recurring tasks
    ↓
Phase 3: Validate data integrity
    ↓
Phase 4: Mark migration complete
    ↓
Continue app initialization
```

---

**Document Version:** 2.0
**Last Updated:** 2025-10-08
**Target Flutter Version:** 3.x (latest stable)
**Current App Version:** 1.2.0