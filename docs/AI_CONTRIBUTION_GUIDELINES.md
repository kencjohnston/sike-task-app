# AI Contribution Guidelines

## Purpose

This document provides standardized guidelines for AI-assisted contributions to project documentation. Following these guidelines ensures consistency, clarity, and maintainability across all documentation updates.

---

## Documentation Structure

### Directory Organization

All documentation must be placed in the `docs/` directory with the following organization:

```
docs/
├── AI_CONTRIBUTION_GUIDELINES.md (this file)
├── ARCHITECTURE.md
├── ENHANCEMENTS.md
├── versions/
│   ├── v1.0.0/
│   │   ├── CHANGES.md
│   │   ├── FEATURES.md
│   │   └── BUGFIXES.md
│   ├── v1.1.0/
│   │   ├── CHANGES.md
│   │   ├── FEATURES.md
│   │   └── BUGFIXES.md
│   └── v1.2.0/
│       ├── PLANNED.md
│       ├── CHANGES.md
│       └── FEATURES.md
└── [other project documentation]
```

---

## Version Documentation Standards

### Version Naming Convention

- Use semantic versioning: `vMAJOR.MINOR.PATCH`
- Examples: `v1.0.0`, `v1.2.3`, `v2.0.0`
- Create a new directory under `docs/versions/` for each version

### File Structure per Version

Each version directory should contain:

1. **0 - REQUIREMENTS.md** - Features and improvements planned for this version (created before plan)
1. **1 - PLAN.md** - Features and improvements planned for this version (created before implementation)
1. **2 - CHANGES.md** - Summary of all changes made in this version (updated during implementation)
1. **3 - UPDATES.md** - Detailed documentation of new features and bug fixes (completed after implementation)

And nothing more. Include data models, summary, UI/UX design, migration and final decisions in PLANNED.md
---

## Markdown Formatting Standards

### Headers

```markdown
# H1 - Document Title (use once per document)
## H2 - Major Sections
### H3 - Subsections
#### H4 - Detailed Points
```

### Code References

Always use inline code formatting for:
- File names: `main.dart`, `pubspec.yaml`
- Variable names: `taskList`, `userId`
- Function names: `createTask()`, `deleteTask()`
- Class names: `TaskService`, `UserProvider`

### Code Blocks

Use fenced code blocks with language specification:

```dart
// Example Dart code
void main() {
  runApp(MyApp());
}
```

```json
// Example JSON
{
  "version": "1.2.0",
  "name": "task_app"
}
```

### Links

Reference other documentation files:
```markdown
See [Architecture Documentation](ARCHITECTURE.md) for details.
See [Version 1.1.0 Changes](versions/v1.1.0/CHANGES.md) for previous updates.
```

### Lists

**Unordered lists:**
```markdown
- First item
- Second item
  - Nested item
  - Another nested item
```

**Ordered lists:**
```markdown
1. First step
2. Second step
3. Third step
```

**Task lists (for planned work):**
```markdown
- [x] Completed task
- [ ] Pending task
- [ ] Future task
```

### Tables

Use tables for structured data:

```markdown
| Feature | Status | Priority | Assigned To |
|---------|--------|----------|-------------|
| Dark Mode | Completed | High | AI Assistant |
| Export Tasks | In Progress | Medium | AI Assistant |
| Cloud Sync | Planned | Low | TBD |
```

### Emphasis

- **Bold** for important terms: `**important**`
- *Italic* for emphasis: `*emphasis*`
- `Code` for technical terms: `` `code` ``

---

## Documenting Changes

### 1. Before Making Changes

**Create a 1 - PLANNED.md file for the target version:**

```markdown
# Planned Changes for v1.2.0

## Overview
Brief description of what this version aims to accomplish.

## Planned Features

### Feature Name
- **Description**: What this feature does
- **Priority**: High/Medium/Low
- **Dependencies**: Any dependencies or prerequisites
- **Implementation Files**: Expected files to be modified
- **Estimated Complexity**: Simple/Medium/Complex

## Planned Bug Fixes

### Bug Description
- **Issue**: Description of the bug
- **Impact**: How it affects users
- **Proposed Solution**: How it will be fixed
- **Files Affected**: Which files need modification

## Technical Considerations
- Performance implications
- Breaking changes
- Migration requirements
```

### 2. During Implementation

**Update 2 - CHANGES.md as you make modifications:**

```markdown
# Changes Log - v1.2.0

## [Date: 2025-01-15]

### Added
- Implemented dark mode toggle in settings
  - Modified: `lib/main.dart`
  - Added: `lib/theme/dark_theme.dart`
  - Updated: `lib/widgets/settings_screen.dart`

### Changed
- Refactored task filtering logic for better performance
  - Modified: `lib/services/task_service.dart`
  - Modified: `lib/widgets/batch_filter_sheet.dart`

### Fixed
- Resolved issue with task completion not persisting
  - Fixed in: `lib/services/storage_service.dart`
  - Root cause: Async operation not awaited properly

### Technical Notes
- Added new dependency: `shared_preferences: ^2.2.0`
- Updated Flutter SDK requirement to: `>=3.0.0`
```

### 3. After Completion

**Create comprehensive 3 - FEATURES.md documentation:**

```markdown
# Features Documentation - v1.2.0

## New Features

### Dark Mode Support

**Overview**
Full dark mode support with automatic theme switching based on system preferences.

**Usage**
Users can toggle dark mode in Settings → Appearance → Theme.

**Implementation Details**
- Theme data defined in `lib/theme/dark_theme.dart`
- Theme switching managed by `ThemeProvider` in `lib/providers/theme_provider.dart`
- Persists user preference using shared_preferences

**Code Example**
\`\`\`dart
// In main.dart
ThemeMode themeMode = userPreferences.isDarkMode 
  ? ThemeMode.dark 
  : ThemeMode.light;
\`\`\`

**Related Files**
- `lib/theme/dark_theme.dart`
- `lib/theme/light_theme.dart`
- `lib/providers/theme_provider.dart`
- `lib/widgets/settings_screen.dart`

## Breaking Changes
None in this version.

## Migration Guide
No migration required for existing users.
```

---

## Best Practices

### 1. Clarity and Precision

✅ **DO:**
- Be specific about file paths and code locations
- Use exact function/class names with proper capitalization
- Provide context for why changes were made

❌ **DON'T:**
- Use vague descriptions like "updated some files"
- Assume readers know what you're referring to
- Skip explaining the reasoning behind decisions

### 2. Completeness

✅ **DO:**
- Document all modified files
- Include code examples for complex changes
- List all dependencies added or updated
- Document both successful implementations and challenges faced

❌ **DON'T:**
- Leave out "minor" changes
- Forget to document configuration updates
- Skip documenting temporary or experimental code

### 3. Organization

✅ **DO:**
- Group related changes together
- Use consistent date formats (ISO 8601: YYYY-MM-DD)
- Maintain chronological order within version documents
- Link between related documentation files

❌ **DON'T:**
- Mix different types of changes without clear sections
- Use inconsistent formatting across documents
- Create orphaned documentation without links

### 4. Version Control

✅ **DO:**
- Create version documentation BEFORE starting work
- Update CHANGES.md incrementally as work progresses
- Mark items with status indicators: [Completed], [In Progress], [Planned]
- Archive old version documentation (don't delete)

❌ **DON'T:**
- Document everything after the fact
- Overwrite existing version documentation
- Delete historical documentation

---

## Practical Example: Documenting v1.2.0

### Step 1: Create Planning Document

**File:** `docs/versions/v1.2.0/PLANNED.md`

```markdown
# Planned Changes for v1.2.0

## Release Date
Target: 2025-02-01

## Overview
This release focuses on improving user experience with enhanced filtering, 
dark mode support, and performance optimizations.

## Planned Features

### Advanced Task Filtering
- **Description**: Multi-criteria filtering with AND/OR logic
- **Priority**: High
- **Dependencies**: None
- **Implementation Files**:
  - `lib/widgets/batch_filter_sheet.dart` (major changes)
  - `lib/services/task_service.dart` (add filter logic)
  - `lib/models/filter_criteria.dart` (new file)
- **Estimated Complexity**: Medium

### Dark Mode Theme
- **Description**: Complete dark theme with user preference persistence
- **Priority**: High
- **Dependencies**: `shared_preferences` package
- **Implementation Files**:
  - `lib/theme/dark_theme.dart` (new file)
  - `lib/providers/theme_provider.dart` (new file)
  - `lib/main.dart` (modifications for theme switching)
- **Estimated Complexity**: Simple

### Export Tasks to CSV
- **Description**: Allow users to export their task list as CSV
- **Priority**: Medium
- **Dependencies**: `csv` package
- **Implementation Files**:
  - `lib/services/export_service.dart` (new file)
  - `lib/widgets/settings_screen.dart` (add export button)
- **Estimated Complexity**: Simple

## Planned Bug Fixes

### Task Completion Not Persisting
- **Issue**: Completed tasks revert to incomplete after app restart
- **Impact**: High - Core functionality broken
- **Proposed Solution**: Ensure storage service properly awaits save operations
- **Files Affected**: `lib/services/storage_service.dart`

### Filter Sheet UI Overflow
- **Issue**: Filter options overflow on small screens
- **Impact**: Medium - UX issue on certain devices
- **Proposed Solution**: Implement scrollable view
- **Files Affected**: `lib/widgets/batch_filter_sheet.dart`

## Technical Considerations

### Performance
- Implement filter caching to avoid redundant computations
- Use indexed database queries where applicable

### Breaking Changes
None anticipated for this release.

### Testing Requirements
- Unit tests for filter logic
- Integration tests for theme switching
- Manual testing on various screen sizes
```

### Step 2: Document During Implementation

**File:** `docs/versions/v1.2.0/CHANGES.md`

```markdown
# Changes Log - v1.2.0

## [2025-01-15] - Initial Implementation

### Added
- [Completed] Created dark theme configuration
  - Added: `lib/theme/dark_theme.dart`
  - Added: `lib/theme/light_theme.dart`
  - Colors: Primary (#1E1E1E), Surface (#2C2C2C), Background (#121212)
  
- [Completed] Implemented theme provider
  - Added: `lib/providers/theme_provider.dart`
  - Uses ChangeNotifier pattern
  - Persists theme preference with shared_preferences

### Modified
- [Completed] Updated main.dart for theme support
  - File: `lib/main.dart`
  - Changes: Added ThemeProvider, MaterialApp.themeMode configuration
  - Lines modified: 15-30

## [2025-01-16] - Advanced Filtering

### Added
- [Completed] Created filter criteria model
  - Added: `lib/models/filter_criteria.dart`
  - Supports: priority, status, date range, tags
  - Implements: AND/OR logic operators

- [In Progress] Enhanced batch filter sheet
  - Modified: `lib/widgets/batch_filter_sheet.dart`
  - Added: Multi-select filter options
  - Added: Filter logic toggle (AND/OR)
  - Status: UI complete, logic integration pending

### Technical Notes
- Filter performance tested with 1000+ tasks
- Average filter execution: <50ms
- Memory usage: No significant increase observed

## [2025-01-17] - Bug Fixes

### Fixed
- [Completed] Task completion persistence issue
  - File: `lib/services/storage_service.dart`
  - Root cause: Missing await on async save operation
  - Solution: Added await to all storage operations
  - Verified: Manual testing + unit tests

- [Completed] Filter sheet UI overflow
  - File: `lib/widgets/batch_filter_sheet.dart`
  - Solution: Wrapped filter options in SingleChildScrollView
  - Tested on: iPhone SE, Pixel 3a, iPad mini

## Dependencies Updated

```yaml
dependencies:
  shared_preferences: ^2.2.0  # Added for theme persistence
  csv: ^5.0.2                 # Added for export functionality
```

## Known Issues
- [ ] Export feature pending - scheduled for next iteration
- [ ] Dark mode colors need accessibility review
```

### Step 3: Final Documentation

**File:** `docs/versions/v1.2.0/FEATURES.md`

```markdown
# Features Documentation - v1.2.0

## Release Information
- **Version**: 1.2.0
- **Release Date**: 2025-01-18
- **Type**: Minor Release

---

## New Features

### 1. Dark Mode Support

**Overview**
Comprehensive dark theme implementation with automatic theme switching and 
user preference persistence.

**User Benefits**
- Reduced eye strain in low-light environments
- Battery savings on OLED devices
- Modern, polished appearance

**Implementation Details**

**Architecture:**
- Theme configurations: `lib/theme/dark_theme.dart`, `lib/theme/light_theme.dart`
- State management: `lib/providers/theme_provider.dart` (ChangeNotifier)
- Persistence: SharedPreferences for user preference

**Color Palette:**
| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Primary | #007AFF | #0A84FF |
| Background | #FFFFFF | #121212 |
| Surface | #F5F5F5 | #2C2C2C |
| Text Primary | #000000 | #FFFFFF |
| Text Secondary | #666666 | #AAAAAA |

**Usage:**
```dart
// Access current theme
final themeProvider = Provider.of<ThemeProvider>(context);
bool isDarkMode = themeProvider.isDarkMode;

// Toggle theme
themeProvider.toggleTheme();
```

**Files Modified:**
- `lib/main.dart` - Added theme provider integration
- `lib/widgets/settings_screen.dart` - Added theme toggle switch
- Created: `lib/theme/dark_theme.dart`
- Created: `lib/theme/light_theme.dart`
- Created: `lib/providers/theme_provider.dart`

---

### 2. Advanced Task Filtering

**Overview**
Enhanced filtering system supporting multiple criteria with AND/OR logic operators.

**User Benefits**
- Find tasks quickly using multiple filters simultaneously
- Complex queries like "High priority AND incomplete" or "Due today OR overdue"
- Improved productivity for users with large task lists

**Filter Criteria:**
- **Priority**: High, Medium, Low, None
- **Status**: Complete, Incomplete
- **Date Range**: Today, This Week, This Month, Custom
- **Tags**: Multi-select tag filtering
- **Logic**: AND (all criteria must match) / OR (any criteria matches)

**Implementation Details:**

**Filter Model:**
```dart
class FilterCriteria {
  final Set<Priority> priorities;
  final Set<TaskStatus> statuses;
  final DateRange? dateRange;
  final Set<String> tags;
  final FilterLogic logic; // AND or OR
  
  bool matches(Task task) {
    // Implementation in lib/models/filter_criteria.dart
  }
}
```

**Performance:**
- Tested with 1,000+ tasks
- Average filter execution: <50ms
- Uses efficient Set operations for O(1) lookups
- No observable memory overhead

**Files Modified:**
- `lib/widgets/batch_filter_sheet.dart` - Enhanced UI with logic toggle
- `lib/services/task_service.dart` - Added filter application logic
- Created: `lib/models/filter_criteria.dart`

**Usage Example:**
```dart
// Create filter criteria
final criteria = FilterCriteria(
  priorities: {Priority.high, Priority.medium},
  statuses: {TaskStatus.incomplete},
  logic: FilterLogic.and,
);

// Apply filter
final filteredTasks = taskService.filterTasks(criteria);
```

---

## Bug Fixes

### Task Completion Not Persisting

**Issue:**
Tasks marked as complete would revert to incomplete status after app restart.

**Root Cause:**
Storage service was not properly awaiting async save operations, causing 
race conditions where app state was saved before task updates completed.

**Solution:**
- Added proper async/await handling in `lib/services/storage_service.dart`
- Implemented save queue to prevent concurrent save operations
- Added error handling and retry logic

**Impact:** HIGH - Core functionality restored

**Files Modified:**
- `lib/services/storage_service.dart` (lines 45-67)

---

### Filter Sheet UI Overflow

**Issue:**
Filter options panel would overflow on devices with small screens, 
making options inaccessible.

**Solution:**
- Wrapped filter options in `SingleChildScrollView`
- Added responsive height calculations based on screen size
- Improved spacing for better touch targets

**Impact:** MEDIUM - Improved UX on small devices

**Testing:**
- iPhone SE (4" display): ✓ Verified
- Google Pixel 3a (5.6" display): ✓ Verified
- iPad mini (7.9" display): ✓ Verified

**Files Modified:**
- `lib/widgets/batch_filter_sheet.dart` (lines 112-145)

---

## Breaking Changes

None in this release. All changes are backward compatible.

---

## Migration Guide

### Upgrading from v1.1.0

**No manual migration required.** 

**What happens automatically:**
1. Theme preference defaults to system theme on first launch
2. Existing filters continue to work (no breaking changes to filter API)
3. Saved tasks are fully compatible

**New dependencies:**
```yaml
dependencies:
  shared_preferences: ^2.2.0
```

Run `flutter pub get` to install new dependencies.

---

## Testing

### Unit Tests Added
- `test/models/filter_criteria_test.dart` - Filter logic validation
- `test/providers/theme_provider_test.dart` - Theme switching logic
- `test/services/storage_service_test.dart` - Persistence fixes

### Manual Testing Performed
- [x] Dark mode toggle on all screens
- [x] Theme persistence across app restarts
- [x] Filter combinations (16 different scenarios)
- [x] Task completion persistence
- [x] UI overflow on small screens
- [x] Performance with 1000+ tasks

---

## Known Limitations

1. **Export Feature**: Planned for v1.2.0 but postponed to v1.3.0 due to time constraints
2. **Accessibility**: Dark mode colors need WCAG compliance review
3. **Localization**: Filter UI text not yet internationalized

---

## Future Improvements (Targeted for v1.3.0)

- [ ] Export tasks to CSV/JSON
- [ ] Accessibility audit and improvements
- [ ] Custom color theme support
- [ ] Saved filter presets
- [ ] Filter search history
```

**File:** `docs/versions/v1.2.0/BUGFIXES.md`

```markdown
# Bug Fixes - v1.2.0

## Critical Fixes

### 1. Task Completion Not Persisting
- **Severity**: Critical
- **Reporter**: Multiple users
- **Date Fixed**: 2025-01-17
- **Status**: ✓ Fixed and Verified

**Problem:**
Tasks marked as complete would revert to incomplete status after closing 
and reopening the app. This affected approximately 100% of task completions.

**Root Cause Analysis:**
The `StorageService.saveTask()` method was calling an async operation but 
not awaiting the result. When the app closed, pending save operations were 
terminated before completing, causing data loss.

**Solution Implemented:**
```dart
// BEFORE (incorrect)
void saveTask(Task task) {
  _storage.write('task_${task.id}', task.toJson());
}

// AFTER (correct)
Future<void> saveTask(Task task) async {
  await _storage.write('task_${task.id}', task.toJson());
}
```

**Files Modified:**
- `lib/services/storage_service.dart` (lines 45-67)
- `lib/services/task_service.dart` (updated all save calls to await)

**Testing:**
- Unit tests: 15/15 passing
- Manual verification: 50+ task completions tested
- No regressions detected

**Prevention:**
- Added linting rule: `unawaited_futures` to catch similar issues
- Updated developer documentation in `docs/ARCHITECTURE.md`

---

### 2. Filter Sheet UI Overflow
- **Severity**: Medium
- **Reporter**: Internal testing
- **Date Fixed**: 2025-01-17
- **Status**: ✓ Fixed and Verified

**Problem:**
On devices with screens smaller than 5", the filter options panel would 
overflow, making some filter options completely inaccessible.

**Affected Devices:**
- iPhone SE (1st & 2nd gen)
- Google Pixel 3a
- Samsung Galaxy A series (some models)

**Solution Implemented:**
1. Wrapped filter options in `SingleChildScrollView`
2. Added responsive height calculation: `min(screenHeight * 0.7, 600)`
3. Improved minimum touch target size to 48x48dp

**Code Changes:**
```dart
// Added scrollable container
Container(
  constraints: BoxConstraints(
    maxHeight: min(MediaQuery.of(context).size.height * 0.7, 600),
  ),
  child: SingleChildScrollView(
    child: FilterOptionsPanel(),
  ),
)
```

**Files Modified:**
- `lib/widgets/batch_filter_sheet.dart` (lines 112-145)

**Testing Results:**

| Device | Screen Size | Status |
|--------|-------------|--------|
| iPhone SE | 4.0" | ✓ Pass |
| Pixel 3a | 5.6" | ✓ Pass |
| iPad mini | 7.9" | ✓ Pass |
| Galaxy S21 | 6.2" | ✓ Pass |

---

## Minor Fixes

### 3. Theme Toggle Animation Stutter
- **Severity**: Low (cosmetic)
- **Date Fixed**: 2025-01-18
- **Status**: ✓ Fixed

**Problem:**
Brief UI stutter when toggling between light and dark themes.

**Solution:**
Added `AnimatedTheme` widget with 300ms duration for smooth transitions.

**Files Modified:**
- `lib/main.dart` (line 28)

---

### 4. Filter Count Badge Not Updating
- **Severity**: Low
- **Date Fixed**: 2025-01-18  
- **Status**: ✓ Fixed

**Problem:**
The filter count badge on the filter button wasn't updating when filters 
were cleared.

**Solution:**
Added listener to filter provider to rebuild badge widget.

**Files Modified:**
- `lib/widgets/batch_filter_sheet.dart` (lines 24-30)

---

## Regression Testing

All existing functionality verified:
- [x] Task creation
- [x] Task editing
- [x] Task deletion
- [x] Task completion toggle
- [x] Task list sorting
- [x] Search functionality
- [x] Settings persistence
- [x] App navigation
- [x] Deep linking (if applicable)

**No regressions detected.**

---

## Performance Impact

**Before fixes:**
- App crash rate: 2.3% (completion persistence bug)
- UI jank on small screens: ~15 frames dropped during filter sheet open

**After fixes:**
- App crash rate: 0.1%
- UI jank: 0 frames dropped (smooth 60fps)

---

## Related Issues

**GitHub Issues Closed:**
- #142: Tasks not saving
- #156: Can't access all filter options on small screen
- #163: Theme switch causes brief flash

**Forum Threads:**
- "Tasks keep reverting" - Resolved
- "Filter menu cut off" - Resolved
```

---

## Documentation Maintenance

### Regular Updates

Update documentation when:
1. **Adding Features**: Create planning doc → update changes log → finalize feature doc
2. **Fixing Bugs**: Document in BUGFIXES.md immediately
3. **Refactoring**: Note in CHANGES.md with rationale
4. **Dependency Changes**: Update in CHANGES.md and root-level dependency docs
5. **Breaking Changes**: Create BREAKING_CHANGES.md and migration guide

### Version Archival

When releasing a new version:
1. Finalize all documentation for the previous version
2. Mark previous version docs as [Released]
3. Create new version directory for next release
4. Update version references in root README.md

### Cross-Referencing

Always link related documentation:
```markdown
See also:
- [Architecture Overview](../ARCHITECTURE.md)
- [Previous Version Changes](../versions/v1.1.0/CHANGES.md)
- [Bug Report Template](../ISSUE_TEMPLATE.md)
```

---

## Special Considerations

### Security-Related Changes

When documenting security fixes:
- **DO NOT** disclose vulnerability details publicly until patch is widely deployed
- Create a separate SECURITY.md file with responsible disclosure timeline
- Mark sensitive changes as [Security Fix] without implementation details
- Provide detailed internal documentation separately

### Performance Optimizations

Document performance changes with metrics:
```markdown
### Performance Improvement: Task List Rendering
- **Before**: 450ms average render time (1000 tasks)
- **After**: 85ms average render time (1000 tasks)
- **Improvement**: 81% faster
- **Method**: Implemented virtualized scrolling with `ListView.builder`
```

### Experimental Features

Mark experimental features clearly:
```markdown
### 🧪 Experimental: AI Task Suggestions
**Status**: Beta - Subject to change
**Stability**: Use with caution in production
**Feedback**: Please report issues to [feedback link]
```

---

## Checklist for AI Contributors

Before submitting documentation:

- [ ] Created/updated PLANNED.md before starting work
- [ ] Updated CHANGES.md incrementally during development
- [ ] Finalized FEATURES.md after completion
- [ ] Documented all bug fixes in BUGFIXES.md
- [ ] Included code examples for complex changes
- [ ] Listed all modified files with specific line numbers where relevant
- [ ] Added cross-references to related documentation
- [ ] Used consistent markdown formatting
- [ ] Checked all links are valid
- [ ] Updated dependency information if applicable
- [ ] Ran spell checker
- [ ] Verified all code snippets are syntactically correct
- [ ] Added appropriate headers and table of contents for long documents

---

## Contact and Questions

For questions about these guidelines or documentation standards:
1. Review existing documentation in `docs/versions/` for examples
2. Consult [ARCHITECTURE.md](ARCHITECTURE.md) for technical context
3. Check [ENHANCEMENTS.md](ENHANCEMENTS.md) for planned work

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-01-18 | Initial creation of contribution guidelines |

---

**Remember**: Good documentation is as important as good code. Take the time to document thoroughly, and future contributors (including yourself) will thank you.