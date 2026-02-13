# v1.3.0 Changes - Complete Changelog

**Release Date:** February 13, 2026

## Overview

Version 1.3.0 is a UI overhaul release that introduces a new brand color scheme matching the Sike logo, centralized color management via a single source of truth, and improved metadata UX with presets and progressive disclosure.

## 🎨 Color Scheme Update

### New Brand Colors

| Role | Previous | New | Hex |
|------|----------|-----|-----|
| **Primary** | Light blue `#87CEEB` | Navy blue | `#275790` |
| **Secondary** | Pink `#E91E63` | Green | `#57AF62` |
| **Dark Primary** | `#5FA8D3` | Muted navy | `#1E4570` |
| **Dark Secondary** | `#C2185B` | Muted green | `#3D8B4A` |

### Centralized Color Management

Created [`lib/utils/app_colors.dart`](../../../lib/utils/app_colors.dart) as a single source of truth for ALL app colors. This file defines:

- **Brand colors** — primary navy blue, secondary green, and dark mode variants
- **Semantic colors** — success, warning, error, info
- **Priority colors** — low (green), medium (orange), high (red)
- **Due date status colors** — none, overdue, due today, upcoming, future
- **Recurring task colors** — streak active, streak record
- **Energy level colors** — high, medium, low
- **Theme color schemes** — `lightColorScheme()` and `darkColorScheme()` using `ColorScheme.fromSeed`

All other files now reference `AppColors.*` constants instead of hardcoding `Color(0xFF...)` or `Colors.*` values. Future rebranding requires updating only this single file.

### Theme Updates

- [`lib/main.dart`](../../../lib/main.dart) — light and dark themes updated to use `AppColors.lightColorScheme()` and `AppColors.darkColorScheme()`
- [`lib/utils/constants.dart`](../../../lib/utils/constants.dart) — priority colors now reference `AppColors.priorityLow/Medium/High`
- [`lib/models/task_enums.dart`](../../../lib/models/task_enums.dart) — `DueDateStatus.getColor()` updated to use `AppColors.statusNone/Overdue/DueToday/Upcoming/Future`

### Logo & Platform Colors

- [`assets/images/logo.svg`](../../../assets/images/logo.svg) — gradient updated from `#87CEEB/#E91E63/#9C27B0` to `#275790/#57AF62`
- [`android/app/src/main/res/values/colors.xml`](../../../android/app/src/main/res/values/colors.xml) — primary color values updated
- [`android/app/src/main/res/values-night-v31/styles.xml`](../../../android/app/src/main/res/values-night-v31/styles.xml) — Material You dark theme colors updated

### Hardcoded Color Replacement

Replaced 36+ hardcoded `Colors.*` references across 11 widget/screen files with `AppColors.*` constants:

| File | Changes |
|------|---------|
| [`recurring_stats_card.dart`](../../../lib/widgets/recurring_stats_card.dart) | `Colors.blue/green/red/orange/grey` → `AppColors.*` |
| [`recurrence_preview_list.dart`](../../../lib/widgets/recurrence_preview_list.dart) | `Colors.blue/grey` → `AppColors.*` / theme refs |
| [`archived_task_item.dart`](../../../lib/widgets/archived_task_item.dart) | `Colors.blue/white` → theme refs |
| [`search_result_item.dart`](../../../lib/widgets/search_result_item.dart) | `Colors.red/orange/blue` → `AppColors.priority*` |
| [`instance_timeline_item.dart`](../../../lib/widgets/instance_timeline_item.dart) | `Colors.green/orange/red/blue/grey` → `AppColors.*` |
| [`streak_indicator.dart`](../../../lib/widgets/streak_indicator.dart) | `Colors.orange/deepOrange/amber/grey` → `AppColors.*` |
| [`batch_view_screen.dart`](../../../lib/screens/batch_view_screen.dart) | `Colors.red/orange/green` → `AppColors.energy*` |
| [`task_list_screen.dart`](../../../lib/screens/task_list_screen.dart) | `Colors.red` → `AppColors.error` |
| [`recurring_task_detail_screen.dart`](../../../lib/screens/recurring_task_detail_screen.dart) | `Colors.red/grey` → `AppColors.*` |
| [`restore_button.dart`](../../../lib/widgets/restore_button.dart) | `Colors.white/green` → theme refs |
| [`task_form_screen.dart`](../../../lib/screens/task_form_screen.dart) | `Colors.red/orange/blue` → `AppColors.*` |

> **Note**: `Colors.transparent`, `Colors.white`, and `Colors.black` were kept as-is since they are universal and carry no semantic meaning.

---

## 📋 Metadata UX Improvement

### Three-Layer Progressive Disclosure

Replaced the large inline "Batch Metadata" card in the task form with a three-layer progressive disclosure pattern:

1. **Layer 1 — Preset Quick-Select**: Horizontal scrollable row of preset cards that auto-fill all 5 metadata fields at once
2. **Layer 2 — Collapsed Summary**: Compact chip row showing current metadata selections (type, energy, time, context, resources)
3. **Layer 3 — Bottom Sheet Editor**: Draggable bottom sheet containing all 5 metadata field editors

### Predefined Presets

Six presets defined in [`lib/models/metadata_preset.dart`](../../../lib/models/metadata_preset.dart):

| Preset | Icon | Type | Resources | Context | Energy | Time |
|--------|------|------|-----------|---------|--------|------|
| Deep Work | 🧠 | Creative | Computer, Internet | Home | High | Long |
| Quick Errand | 🏃 | Physical | Transportation | Outdoor | Low | Short |
| Admin | 📋 | Administrative | Computer, Documents | Anywhere | Low | Medium |
| Phone Call | 📞 | Communication | Phone | Anywhere | Medium | Short |
| Hands-On | 🔧 | Technical | Tools, Materials | Home | High | Medium |
| Meeting | 👥 | Communication | Computer, People | Office | Medium | Medium |

### New Widgets

- [`lib/widgets/metadata_preset_selector.dart`](../../../lib/widgets/metadata_preset_selector.dart) — Horizontal scrollable preset cards with icon and label
- [`lib/widgets/metadata_summary_chips.dart`](../../../lib/widgets/metadata_summary_chips.dart) — Compact chip row for collapsed metadata display with "Edit" action
- [`lib/widgets/metadata_bottom_sheet.dart`](../../../lib/widgets/metadata_bottom_sheet.dart) — Draggable bottom sheet with drag handle, preset row, all 5 field editors, and "Apply" button

### Task Form Refactoring

[`lib/screens/task_form_screen.dart`](../../../lib/screens/task_form_screen.dart) — Removed the inline metadata card and integrated the three-layer system:
- Preset selector shown at top of metadata section
- Summary chips displayed when metadata is set
- "Add task details" placeholder shown when no metadata is set
- Tapping Edit or placeholder opens the bottom sheet
- State management updated to handle preset selection and manual edits

---

## 📦 Files Created (5)

| File | Purpose |
|------|---------|
| [`lib/utils/app_colors.dart`](../../../lib/utils/app_colors.dart) | Centralized color definitions — single source of truth for all app colors |
| [`lib/models/metadata_preset.dart`](../../../lib/models/metadata_preset.dart) | `MetadataPreset` class and 6 predefined preset definitions |
| [`lib/widgets/metadata_preset_selector.dart`](../../../lib/widgets/metadata_preset_selector.dart) | Horizontal scrollable preset card selector widget |
| [`lib/widgets/metadata_summary_chips.dart`](../../../lib/widgets/metadata_summary_chips.dart) | Compact chip row for collapsed metadata display |
| [`lib/widgets/metadata_bottom_sheet.dart`](../../../lib/widgets/metadata_bottom_sheet.dart) | Draggable bottom sheet with all metadata field editors |

## 📝 Files Modified (17+)

| File | Change Summary |
|------|---------------|
| [`lib/main.dart`](../../../lib/main.dart) | Light/dark themes use `AppColors` color schemes |
| [`lib/utils/constants.dart`](../../../lib/utils/constants.dart) | Priority colors reference `AppColors`; `appVersion` bumped to `1.3.0` |
| [`lib/models/task_enums.dart`](../../../lib/models/task_enums.dart) | Due date status colors reference `AppColors` |
| [`lib/screens/task_form_screen.dart`](../../../lib/screens/task_form_screen.dart) | Inline metadata card replaced with progressive disclosure |
| [`lib/screens/task_list_screen.dart`](../../../lib/screens/task_list_screen.dart) | Hardcoded colors replaced with `AppColors` |
| [`lib/screens/batch_view_screen.dart`](../../../lib/screens/batch_view_screen.dart) | Energy colors replaced with `AppColors.energy*` |
| [`lib/screens/recurring_task_detail_screen.dart`](../../../lib/screens/recurring_task_detail_screen.dart) | Hardcoded colors replaced with `AppColors` |
| [`lib/widgets/recurring_stats_card.dart`](../../../lib/widgets/recurring_stats_card.dart) | All `Colors.*` replaced with `AppColors.*` |
| [`lib/widgets/recurrence_preview_list.dart`](../../../lib/widgets/recurrence_preview_list.dart) | Colors replaced with `AppColors` / theme refs |
| [`lib/widgets/archived_task_item.dart`](../../../lib/widgets/archived_task_item.dart) | Colors replaced with theme refs |
| [`lib/widgets/search_result_item.dart`](../../../lib/widgets/search_result_item.dart) | Priority colors replaced with `AppColors.priority*` |
| [`lib/widgets/instance_timeline_item.dart`](../../../lib/widgets/instance_timeline_item.dart) | Status colors replaced with `AppColors.*` |
| [`lib/widgets/streak_indicator.dart`](../../../lib/widgets/streak_indicator.dart) | Streak colors replaced with `AppColors.*` |
| [`lib/widgets/restore_button.dart`](../../../lib/widgets/restore_button.dart) | Colors replaced with theme refs |
| [`assets/images/logo.svg`](../../../assets/images/logo.svg) | Gradient updated to brand colors |
| [`android/app/src/main/res/values/colors.xml`](../../../android/app/src/main/res/values/colors.xml) | Platform primary color updated |
| [`android/app/src/main/res/values-night-v31/styles.xml`](../../../android/app/src/main/res/values-night-v31/styles.xml) | Material You dark colors updated |

## 📦 Dependencies

No new dependencies added. All features use existing packages.

## ⚠️ Breaking Changes

**None.** Version 1.3.0 is fully backward compatible with v1.2.0. No data model changes, no migration required.

## 🚀 Upgrade Instructions

### From v1.2.0 to v1.3.0

1. **Pull latest code:**
   ```bash
   git pull origin main
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

No migration needed — this release contains only UI/UX changes.

---

**v1.3.0 - UI Overhaul Complete** ✨
