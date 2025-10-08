# v1.2.0 User Guide

Complete guide to using all features in the Task Management App v1.2.0.

## Table of Contents
- [Getting Started](#getting-started)
- [Task Search](#task-search)
- [Task Archiving](#task-archiving)
- [Recurring Task History](#recurring-task-history)
- [Advanced Recurrence Patterns](#advanced-recurrence-patterns)
- [Tips & Best Practices](#tips--best-practices)
- [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Launch
When you first launch v1.2.0, the app will automatically migrate your existing data to support the new features. This process:
- Takes less than 5 seconds for most users
- Preserves all your existing tasks
- Adds new capabilities without changing your data
- Runs only once

You'll see a brief migration message, then you're ready to use all new features!

---

## Task Search

### Basic Search

**To search for tasks:**
1. Tap the **search icon** (🔍) in the top app bar
2. Enter your search term in the search box
3. Results appear instantly as you type

**What gets searched:**
- Task titles
- Task descriptions
- Both active and completed tasks (when viewing active tasks)
- Archived tasks (when viewing archive)

**Search tips:**
- Search is case-insensitive ("meeting" finds "Meeting")
- Partial matches work ("docu" finds "Documentation")
- Exact title matches appear first in results

### Advanced Filters

**To use advanced filters:**
1. Open search screen
2. Tap **"Filters"** button
3. Select your filter criteria:
   - **Task Type:** Creative, Administrative, Development, etc.
   - **Priority:** Low (0), Medium (1), High (2)
   - **Context:** Office, Home, Anywhere, etc.
   - **Completion Status:** Completed or Not Completed
   - **Recurring:** Recurring tasks only
4. Tap **"Apply Filters"**
5. Results update to match all selected criteria

**Filter behavior:**
- Multiple filters use AND logic (task must match all)
- Clear filters to reset to all results
- Filters work with or without text search

### Search History

**Recent searches are automatically saved:**
- Last 10 searches are remembered
- Tap any recent search to repeat it
- Searches are saved even after closing the app
- Clear history from the search menu

**To use recent searches:**
1. Open search screen
2. View recent searches below the search box
3. Tap any search to re-run it

### Search in Archive

**To search archived tasks:**
1. Go to Archive (menu → Archive)
2. Tap the search icon
3. Search works the same as with active tasks
4. All filters are available

**Use cases:**
- Find an old completed project
- Look up how you solved a similar task before
- Review completion dates

---

## Task Archiving

### What is Archiving?

**Archiving moves completed tasks out of your active view while preserving them for future reference.**

Benefits:
- Keep your active task list clean and focused
- Preserve task history and completion dates
- Still searchable when needed
- Can be restored if needed

### Manual Archiving

**To archive a single task:**
1. Complete the task (if not already completed)
2. Tap the **archive icon** (📦) on the task
3. Task moves to archive immediately

**To archive multiple tasks:**
1. Long-press any completed task to enter selection mode
2. Select additional tasks
3. Tap **"Archive Selected"** button
4. All selected tasks move to archive

### Automatic Archiving

**The app can automatically archive old completed tasks:**

**Default behavior:**
- Tasks completed more than 30 days ago
- Automatically archived when you launch the app
- Runs silently in the background

**To configure auto-archive:**
1. Go to Settings → Archive Settings
2. Choose threshold (7, 30, 60, or 90 days)
3. Enable/disable auto-archive

### Viewing Archived Tasks

**To view your archive:**
1. Tap menu (⋮) in app bar
2. Select **"Archive"**
3. View all archived tasks organized by time

**Archive organization:**
- **Today** - Archived today
- **Yesterday** - Archived yesterday
- **This Week** - Last 7 days
- **This Month** - Last 30 days
- **Older** - More than 30 days ago

**In each group:**
- Tasks sorted by archive date (newest first)
- Shows completion date and archive date
- Full task details available

### Restoring Archived Tasks

**To restore a task:**
1. Open Archive
2. Find the task you want to restore
3. Tap the **restore icon** (↶)
4. Task returns to your active list

**Notes:**
- Task retains all its properties
- Completion status is preserved
- Subtasks are restored together
- Recurring tasks maintain their history

### Managing Archive

**To permanently delete an archived task:**
1. Open Archive
2. Swipe left on the task
3. Confirm deletion
4. ⚠️ This cannot be undone!

**To clear entire archive:**
1. Open Archive
2. Tap menu (⋮)
3. Select "Clear All Archive"
4. Confirm action
5. ⚠️ All archived tasks permanently deleted!

---

## Recurring Task History

### Viewing Task History

**To view history for a recurring task:**
1. Tap on the recurring task
2. Select the **"History"** tab
3. View comprehensive statistics and timeline

### Understanding Statistics

**Key metrics displayed:**

**Completion Rate**
- Percentage of instances completed on time
- Green (>80%): Excellent consistency
- Yellow (50-80%): Moderate consistency  
- Red (<50%): Needs attention
- Formula: Completed ÷ (Total - Pending)

**Current Streak**
- Consecutive completed instances
- Resets when an instance is missed (not skipped)
- Shows 🔥 flame icon when active
- Displayed prominently in stats card

**Longest Streak**
- Best streak you've ever achieved
- Historical record maintained
- Motivation to beat your record
- Shows 🏆 trophy icon

**Instance Counts**
- **Total:** All instances created
- **Completed:** Successfully finished
- **Skipped:** Deliberately skipped
- **Missed:** Overdue and incomplete
- **Pending:** Future instances

**Dates**
- **Last Completed:** When you last completed an instance
- **Next Due:** When the next instance is due

### Instance Timeline

**The timeline shows all instances with:**
- Due date
- Completion status (✓ completed, ⏭ skipped, ⚠️ missed)
- Completion date (if completed)
- Quick actions (skip, reschedule)

**Timeline color coding:**
- **Green:** Completed on time
- **Orange:** Completed late
- **Gray:** Skipped
- **Red:** Missed (overdue)
- **Blue:** Pending (future)

### Skipping Instances

**When to skip:**
- You intentionally don't need to complete this instance
- Example: "Weekly Review" task during vacation week
- Skipping maintains your streak (unlike missing)

**To skip an instance:**
1. View recurring task history
2. Find the instance to skip
3. Tap **"Skip"** button
4. Instance marked as skipped
5. Streak continues

**Note:** Skipped instances don't count toward completion rate.

### Rescheduling Instances

**When to reschedule:**
- Need to change due date for a specific instance
- One-time exception to the recurring pattern
- Doesn't affect future instances

**To reschedule an instance:**
1. View recurring task history
2. Find the instance to reschedule
3. Tap **"Reschedule"** button
4. Choose new date
5. Instance updated with new due date

**Note:** Only affects that specific instance, not the recurrence pattern.

### Recent Completions

**View your completion history:**
- Last 10 completions shown
- Helps track consistency
- See patterns in completion timing
- Useful for accountability

---

## Advanced Recurrence Patterns

### Creating Advanced Recurring Tasks

**To create a recurring task with advanced patterns:**
1. Create or edit a task
2. Enable **"Recurring"** toggle
3. Select base pattern (Daily, Weekly, Monthly, etc.)
4. Configure advanced options based on pattern
5. Preview upcoming occurrences
6. Save task

### Weekly with Weekday Selection

**Choose specific days of the week:**

**Use cases:**
- Gym Mon-Wed-Fri
- Team meetings Tue-Thu
- Weekend chores Sat-Sun

**To configure:**
1. Select **Weekly** pattern
2. Tap on weekdays to select/deselect
3. Selected days are highlighted
4. Preview shows next 5 occurrences

**Examples:**
- **Mon-Wed-Fri:** Select Monday, Wednesday, Friday
- **Weekdays only:** Select Mon-Tue-Wed-Thu-Fri
- **Weekends:** Select Sat-Sun
- **Tue-Thu:** Select Tuesday, Thursday

### Monthly by Date

**Repeat on a specific day of each month:**

**Use cases:**
- Bills due on the 15th
- Rent due on the 1st
- Monthly report on the 30th

**To configure:**
1. Select **Monthly** pattern
2. Choose **"By Date"** tab
3. Enter day of month (1-31)
4. Or select **"Last Day"** for month-end

**Special handling:**
- Day 31 in shorter months → last day of that month
- February 30/31 → February 28/29
- Smart month-end handling

**Examples:**
- **15th of month:** dayOfMonth = 15
- **Last day:** dayOfMonth = -1
- **First of month:** dayOfMonth = 1

### Monthly by Weekday

**Repeat on a specific weekday position:**

**Use cases:**
- First Monday of month (team meeting)
- Last Friday of month (payday)
- Second Tuesday of month (book club)
- Third Wednesday (client check-in)

**To configure:**
1. Select **Monthly** pattern
2. Choose **"By Weekday"** tab
3. Select week position (1st, 2nd, 3rd, 4th, Last)
4. Task's current weekday is used

**Week positions:**
- **1st** - First occurrence in month
- **2nd** - Second occurrence
- **3rd** - Third occurrence
- **4th** - Fourth occurrence (if exists)
- **Last** - Last occurrence in month

**Examples:**
- **First Monday:** weekOfMonth = 1, task on Monday
- **Last Friday:** weekOfMonth = -1, task on Friday
- **Second Tuesday:** weekOfMonth = 2, task on Tuesday

### End Conditions

**Control when recurrence stops:**

**End by date:**
1. Toggle **"End Date"**
2. Select calendar date
3. No instances created after this date

**End after N occurrences:**
1. Toggle **"Max Occurrences"**
2. Enter number (e.g., 10)
3. Stops after creating N instances

**Examples:**
- **Project tasks:** End after 12 occurrences (1 year)
- **Temporary habit:** End after 30 days
- **Trial period:** End on specific date

### Pattern Preview

**Before saving, preview the pattern:**
- Next 5 occurrences displayed
- Verify dates are correct
- Check weekday alignment
- Confirm pattern meets expectations

**What to check:**
- Dates fall on correct weekdays
- Monthly patterns align properly
- End conditions apply correctly
- No unexpected gaps

### Editing Recurring Tasks

**When you edit a recurring task:**

**Options presented:**
1. **This instance only** - Affects single instance
2. **This and future** - Updates pattern going forward
3. **All instances** - Retroactive update (use carefully)

**What gets updated:**
- Title and description
- Priority
- Task type and metadata
- Recurrence pattern (future only)

**What doesn't change:**
- Completed instances remain unchanged
- Past due dates stay the same
- Completion history preserved

---

## Tips & Best Practices

### Search Tips

1. **Use filters strategically**
   - Narrow down large result sets
   - Combine text with filters for precision

2. **Recent searches save time**
   - Commonly used searches appear first
   - No need to retype frequently used queries

3. **Search descriptions too**
   - Don't just search titles
   - Detailed notes make tasks easier to find

4. **Archive search is powerful**
   - Find old solutions to similar problems
   - Reference completed project details

### Archive Tips

1. **Archive regularly**
   - Keep active list manageable
   - Focus on current priorities

2. **Use auto-archive**
   - Set it and forget it
   - Clean up happens automatically

3. **Don't be afraid to archive**
   - Tasks are searchable in archive
   - Easy to restore if needed

4. **Permanent delete carefully**
   - Archive can always be cleared later
   - Better to keep too much than too little

### Recurring Task Tips

1. **Check history weekly**
   - Maintain awareness of streaks
   - Identify patterns of missed instances

2. **Skip vs. Miss**
   - Skip when intentional (vacation)
   - Fix misses promptly to maintain habit

3. **Use reschedule sparingly**
   - Better to adjust the pattern
   - One-off changes only

4. **Celebrate streaks**
   - Acknowledge consistency
   - Compete with yourself

### Advanced Recurrence Tips

1. **Preview before saving**
   - Verify pattern is correct
   - Catch errors early

2. **Weekday selection for flexibility**
   - More flexible than daily
   - Accommodates real-life schedules

3. **Monthly by weekday for consistency**
   - Same weekday each month
   - Better for meetings and events

4. **Set end conditions**
   - Prevents runaway recurrence
   - Good for finite projects

5. **Start simple, add complexity**
   - Begin with basic patterns
   - Add advanced features as needed

---

## Troubleshooting

### Search Issues

**Problem: No results found**
- Check spelling
- Try broader search terms
- Remove filters to see if they're too restrictive
- Verify you're searching the right view (active vs. archive)

**Problem: Wrong results**
- Be more specific in search terms
- Apply filters to narrow results
- Use exact phrases in quotes (coming soon)

**Problem: Search is slow**
- Should be <200ms for 1000 tasks
- Try clearing app cache
- Report if consistently slow

### Archive Issues

**Problem: Can't find archived task**
- Check archive groups (expand all)
- Use archive search
- Verify task was actually archived (check active list)

**Problem: Can't restore task**
- Check if task has been permanently deleted
- Ensure you have permission (if multi-user)
- Try restarting app

**Problem: Auto-archive not working**
- Check settings (may be disabled)
- Verify tasks are old enough (30+ days by default)
- Ensure tasks are completed

### Recurring History Issues

**Problem: Stats seem wrong**
- Refresh the history screen
- Check if migration completed successfully
- Verify instance relationships are intact

**Problem: Streak reset unexpectedly**
- Check for missed instances
- Skipped instances maintain streak
- Missed instances break streak

**Problem: Can't skip/reschedule**
- Ensure instance is not already completed
- Check if you're viewing the right instance
- Try closing and reopening history

### Recurrence Pattern Issues

**Problem: Instances not creating**
- Check if max occurrences reached
- Verify end date hasn't passed
- Ensure pattern is valid (e.g., valid weekdays selected)

**Problem: Wrong dates generated**
- Verify pattern preview before saving
- Check timezone settings
- Report if consistently incorrect

**Problem: Can't edit pattern**
- Some edits only affect future instances
- Past instances can't be changed
- Create new recurring task if needed

### Getting Help

If issues persist:
1. Check app version (should be 1.2.0+)
2. Try restarting the app
3. Clear cache and restart
4. Check documentation at `docs/`
5. Report bugs with specific steps to reproduce

---

## Keyboard Shortcuts

**Search Screen:**
- `ESC` - Close search
- `Enter` - Submit search
- `Ctrl/Cmd + F` - Open search

**Archive Screen:**
- `Ctrl/Cmd + R` - Restore selected
- `Delete` - Delete selected

**General:**
- `Ctrl/Cmd + N` - New task
- `Ctrl/Cmd + ,` - Settings

*(Shortcuts available on desktop/web platforms)*

---

## Accessibility

The app supports:
- Screen readers (TalkBack, VoiceOver)
- Voice control
- Large text sizes
- High contrast mode
- Keyboard navigation (desktop/web)
- Semantic labels on all interactive elements

Enable accessibility features in your device settings.

---

## What's Next?

You're now ready to use all v1.2.0 features! Start with:
1. ✅ Try searching for a task
2. ✅ Archive a completed task
3. ✅ Create a recurring task with weekday selection
4. ✅ View history for a recurring task

Happy task managing! 🎯

---

**Version:** 1.2.0  
**Last Updated:** October 8, 2025  
**Questions?** Check [`CHANGES.md`](CHANGES.md) for technical details or [`SPECIFICATION.md`](SPECIFICATION.md) for deep dive.