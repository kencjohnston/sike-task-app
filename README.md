# Flutter Task Management App

A complete task management mobile application built with Flutter, featuring local data persistence, intuitive UI, and cross-platform support (iOS & Android).

## Features

### Core Functionality
- ✅ **Create Tasks** - Add new tasks with title, description, and priority levels
- ✅ **Edit Tasks** - Modify existing task details
- ✅ **Delete Tasks** - Remove tasks with swipe-to-delete gesture and confirmation dialog
- ✅ **Toggle Completion** - Mark tasks as complete/incomplete with a checkbox
- ✅ **Task Filtering** - View All, Active, or Completed tasks
- ✅ **Data Persistence** - Tasks are automatically saved locally using Hive
- ✅ **Priority Levels** - Assign Low, Medium, or High priority to tasks
- ✅ **Empty States** - Helpful messages when no tasks are available
- ✅ **Material Design 3** - Modern, beautiful UI following latest design guidelines

### Advanced Features (v1.2.0)
- 🔍 **Task Search** - Full-text search across tasks with advanced filtering
  - Search by title and description
  - Filter by task type, priority, context, completion status
  - Recent search history with persistence
  - Search within archived tasks
- 📦 **Task Archiving** - Preserve completed tasks without cluttering your active list
  - Manual and automatic archiving
  - Time-based grouping (today, yesterday, this week, this month)
  - Restore archived tasks
  - Batch archive operations
- 📊 **Recurring Task History** - Track and analyze recurring task performance
  - View all instances of a recurring task
  - Completion rate statistics
  - Current and longest streaks
  - Skip or reschedule instances
  - Recent completion history
- 🔄 **Advanced Recurrence** - Flexible recurring task patterns
  - Weekday selection (e.g., Mon-Wed-Fri only)
  - Monthly patterns: by date or by weekday (e.g., 2nd Tuesday)
  - Support for first/last occurrences of the month
  - End dates and max occurrence limits

### Technical Features
- 🎨 **Material Design 3** with dynamic theming
- 🌗 **Dark Mode Support** - Automatically adapts to system theme
- 💾 **Hive Database** - Fast, lightweight local storage
- 🔄 **Provider Pattern** - Clean state management
- 📱 **Responsive UI** - Works on various screen sizes
- ⚡ **Performance Optimized** - Efficient list rendering with ListView.builder
- 🎯 **Type-Safe** - Strong typing with generated Hive adapters

## Architecture

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
│  - Data Persistence                         │
└─────────────────────────────────────────────┘
```

## Project Structure

```
lib/
├── main.dart                 # App entry point, provider setup
├── models/
│   ├── task.dart            # Task data model with Hive annotations
│   └── task.g.dart          # Generated Hive TypeAdapter
├── providers/
│   └── task_provider.dart   # Task state management with ChangeNotifier
├── services/
│   └── task_service.dart    # Hive database operations (CRUD)
├── screens/
│   ├── task_list_screen.dart    # Main screen with task list
│   └── task_form_screen.dart    # Create/edit task screen
├── widgets/
│   ├── task_item.dart          # Individual task list item
│   ├── empty_state.dart        # Empty list placeholder
│   └── task_filter_tabs.dart   # Filter tabs widget
└── utils/
    └── constants.dart          # App constants (colors, strings, etc.)
```

## Technologies Used

- **Framework:** Flutter (Dart 2.17.6)
- **State Management:** Provider (^6.1.0)
- **Local Database:** Hive (^2.2.3) + Hive Flutter (^1.1.0)
- **Code Generation:** build_runner (^2.1.11) + hive_generator (^1.1.3)
- **Utilities:** 
  - uuid (^3.0.6) - Unique ID generation
  - intl (^0.17.0) - Date formatting
- **UI Design:** Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK (2.17.6 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / Xcode (for mobile deployment)
- VS Code or Android Studio (recommended IDEs)

### Installation

1. **Clone or navigate to the project directory:**
   ```bash
   cd task_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Hive TypeAdapters (already done, but if needed):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Running the App

#### Debug Mode (Development)
Open an emulator
```bash
flutter emulators --launch Pixel_9_Pro
```
Run the app
```bash
flutter run
```

#### Release Mode (Production)
```bash
# Android
flutter run --release

# iOS
flutter run --release
```

### Building for Production

#### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

#### iOS
```bash
flutter build ios --release
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## Usage Guide

### Creating a Task
1. Tap the **+** floating action button
2. Enter a **title** (required)
3. Optionally add a **description**
4. Select a **priority** level (Low/Medium/High)
5. Tap **Create**

### Editing a Task
1. Tap on any task in the list
2. Modify the details
3. Tap **Save**

### Completing a Task
- Tap the **checkbox** next to the task title

### Deleting a Task
1. **Swipe left** on the task
2. Confirm deletion in the dialog

### Filtering Tasks
- Use the tabs at the top to switch between:
  - **All** - Shows all tasks
  - **Active** - Shows incomplete tasks
  - **Completed** - Shows completed tasks

### Deleting All Tasks
1. Tap the **⋮** menu in the app bar
2. Select **Delete All Tasks**
3. Confirm the action

## Data Model

### Task Properties
```dart
class Task {
  String id;              // Unique identifier (UUID)
  String title;           // Task title (required, max 100 chars)
  String? description;    // Task description (optional, max 500 chars)
  bool isCompleted;       // Completion status
  DateTime createdAt;     // Creation timestamp
  DateTime updatedAt;     // Last update timestamp
  int priority;           // Priority (0=Low, 1=Medium, 2=High)
}
```

## State Management

The app uses the **Provider** pattern for state management:

- **TaskProvider** - Main state manager
  - Manages task list state
  - Handles CRUD operations
  - Implements filtering logic
  - Notifies UI of changes

### Key Methods
- `loadTasks()` - Load all tasks from database
- `addTask()` - Create a new task
- `updateTask()` - Update existing task
- `deleteTask()` - Delete a task
- `toggleTaskCompletion()` - Toggle task completion
- `setFilter()` - Change filter (All/Active/Completed)

## Performance Considerations

- **Lazy Loading:** Uses `ListView.builder` for efficient scrolling
- **Selective Rebuilds:** Provider pattern ensures only affected widgets rebuild
- **Fast Storage:** Hive provides sub-millisecond read/write operations
- **Type Safety:** Generated TypeAdapters ensure compile-time safety

## Key Design Decisions

### Why Provider over BLoC?
- Simpler learning curve
- Official Flutter recommendation
- Sufficient for app complexity
- Better for small-to-medium apps

### Why Hive over SQLite?
- No native dependencies
- Pure Dart implementation
- Faster for CRUD operations
- Type-safe with code generation
- Smaller binary size

### Why Material Design 3?
- Modern, consistent design language
- Built-in accessibility features
- Easy theming and customization
- Familiar to Android users

## Known Limitations

- Android SDK version warning (requires compileSdkVersion 33 for latest features)
- No cloud sync (local-only storage)
- No task categories or tags (future enhancement)

## Future Enhancements

Potential features for future versions:
- 🏷️ Categories and tags
- ☁️ Cloud synchronization
- 📤 Export/Import (JSON/CSV)
- 🌐 Multi-language support
- 🔔 Push notifications for reminders
- 🎨 Custom themes and color schemes

## Troubleshooting

### Build Issues
If you encounter build issues:
```bash
# Clean the build
flutter clean

# Get dependencies again
flutter pub get

# Regenerate code
flutter pub run build_runner build --delete-conflicting-outputs
```

### Hive Issues
If Hive data becomes corrupted:
```bash
# The app stores data in the app's documents directory
# On Android: /data/data/com.taskmanager.task_app/
# On iOS: Library/Application Support/
```

## Contributing

This is a demonstration project following the architecture specified in `ARCHITECTURE.md`.

## License

This project is created for demonstration purposes.

## Version History

- **v1.2.0** (2025-10-08)
  - ✨ **Task Search** - Full-text search with advanced filtering and history
  - 📦 **Task Archiving** - Archive completed tasks with time-based grouping
  - 📊 **Recurring Task History** - View stats, streaks, and analytics
  - 🔄 **Advanced Recurrence** - Weekday selection and monthly patterns
  - 🎯 Performance optimizations (search <200ms, archive load <300ms)
  - 🗄️ Data migration v3 - Archive support and streak tracking
  - 📚 Comprehensive documentation and user guide

- **v1.1.0** (2025-10-05)
  - 📅 Due date support
  - 🔄 Basic recurring tasks
  - 📊 Subtask hierarchy (up to 2 levels)
  - 🎯 Batch filtering by task type, context, energy, time
  - ⚡ Smart task suggestions

- **v1.0.0** (2025-10-03)
  - Initial release
  - Complete CRUD functionality
  - Task filtering
  - Priority levels
  - Material Design 3 UI
  - Dark mode support
  - Local persistence with Hive

## Contact & Support

For questions or issues, refer to the architecture documentation in `ARCHITECTURE.md`.

---

**Built with ❤️ using Flutter**
