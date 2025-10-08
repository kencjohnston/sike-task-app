# v1.2.0 Stakeholder Decisions

**Date**: October 7, 2025
**Status**: ✅ APPROVED
**Approved By**: Stakeholder
**Ready For**: Implementation

---

## How to Use This Document

You can communicate your decisions in **two ways**:

### Option 1: Edit This File Directly
- Update the "DECISION" field for each question
- Add any notes or rationale
- Save the file and let me know it's updated

### Option 2: Tell Me Your Decisions
Simply say something like:
> "For question 1, go with the recommendation. For question 2, I want option C with 180 days. For questions 3-5, use the recommendations."

I'll update this document and the specifications accordingly.

---

## Open Questions

### Question 1: Search Indexing Strategy

**Context**: Search performance optimization approach

**Options**:
- **A. In-memory filtering only** (simpler, adequate for <5,000 tasks)
- **B. Build search index** (faster, more complex, uses more memory)
- **C. Hybrid** (in-memory first, build index when task count >1,000)

**Recommendation**: Option A (start in-memory)

**Impact**:
- Option A: Simpler code, slightly slower search (still <200ms target)
- Option B: Faster search (<50ms) but more complexity upfront
- Option C: Best of both but requires two implementations

**DECISION**: Option A

**RATIONALE/NOTES**: Users are only using small number of tasks to start, save for later improvement

---

### Question 2: Archive Retention Policy

**Context**: Should archived tasks be automatically cleaned up?

**Options**:
- **A. No auto-cleanup** (keep all archived tasks forever)
- **B. Auto-delete after 1 year** (fixed retention period)
- **C. Configurable retention** (user chooses: 90/180/365 days)
- **D. Size-based limit** (e.g., max 1000 archived tasks)

**Recommendation**: Option A (no auto-cleanup)

**Impact**:
- Option A: Simplest, preserves all history, archive grows unbounded
- Option B: Keeps database lean, users lose old data
- Option C: Most flexible, more UI complexity
- Option D: Predictable size, but arbitrary limit

**DECISION**: Option A

**RATIONALE/NOTES**: No need for cleanup yet, users are all new

---

### Question 3: Streak Calculation on Migration

**Context**: How to initialize streak data for existing recurring tasks?

**Options**:
- **A. Start fresh** (all streaks = 0, simpler)
- **B. Calculate from history** (accurate but complex)

**Recommendation**: Option B (calculate from history)

**Impact**:
- Option A: Fast migration, users lose historical streak data
- Option B: Slower migration (+1-2s), preserves user achievement history

**DECISION**: Option B

**RATIONALE/NOTES**: I don't care about speed of migration

---

### Question 4: Date Exclusions in Advanced Recurrence

**Context**: Should v1.2.0 include the ability to exclude specific dates from recurrence?

**Options**:
- **A. Include in v1.2.0** (feature-complete advanced recurrence)
- **B. Defer to v1.3.0** (faster v1.2.0 delivery)

**Recommendation**: Option B (defer to v1.3.0)

**Impact**:
- Option A: More complete feature, adds 2-3 days to timeline
- Option B: Faster delivery, users can request for v1.3.0

**DECISION**: Option B

**RATIONALE/NOTES**: Not important for now

---

### Question 5: Recurring Instance Auto-Archive

**Context**: Should completed recurring task instances be auto-archived?

**Options**:
- **A. Never auto-archive instances** (preserve full history in main view)
- **B. Auto-archive after N days** (keeps main view focused)
- **C. User configurable** (let user decide per task or globally)

**Recommendation**: Option A for v1.2.0, Option C for v1.3.0

**Impact**:
- Option A: Simplest, all instances visible in recurring history
- Option B: Cleaner main view, may lose track of old instances
- Option C: Most flexible but more complex

**DECISION**: Option A

**RATIONALE/NOTES**: Agreed, other improvements can come later

---

### Question 6: Calendar View Implementation

**Context**: Should recurring task history include monthly calendar view?

**Options**:
- **A. Include in v1.2.0** (full-featured history view)
- **B. Defer to v1.3.0** (focus on timeline view first)
- **C. Use third-party package** (faster but adds dependency)

**Recommendation**: Option B (defer to v1.3.0)

**Impact**:
- Option A: More complete, adds 1-2 days to timeline
- Option B: Faster v1.2.0, can add later based on user feedback
- Option C: Fastest but adds maintenance burden (new dependency)

**DECISION**: Option B

**RATIONALE/NOTES**: Agree, can defer for later

---

## Additional Decisions

### Any modifications to proposed features?

**Changes Requested**: None

Example:
- "Remove advanced monthly patterns, just do weekday selection"
- "Add export to archive feature"
- "Change timeline estimate from 13-17 days to X days"

---

### Any additional features to include?

**Extra Features**: None

Available to add from original list:
- Task Templates (save/reuse task configurations)
- Quick Actions (swipe gestures, keyboard shortcuts)
- Task Tags/Labels (user-defined flexible categorization)
- Projects/Lists (group related tasks)
- Task Dependencies (prerequisite relationships)
- Time-of-Day for Due Dates (extend from date-only)
- Calendar View (month/week views)
- Task Reminders (push notifications)
- Snooze/Postpone (quick reschedule)
- Bulk Operations (multi-select actions)
- Task Statistics Dashboard (productivity analytics)

---

### Budget & Timeline Approval

**Estimated Timeline**: 13-17 days

**Approved Timeline**: Approved

**Development Budget**: Approved

**Target Release Date**: Approved

---

## Decision Summary

Once decisions are made, I'll:
1. ✅ Update all specification documents
2. ✅ Create final implementation-ready plan
3. ✅ Update timeline based on decisions
4. ✅ Mark this document as APPROVED
5. 🚀 Ready to switch to Code mode for implementation

---

## How to Proceed

### Simple Approach
Just tell me your decisions in plain text, like:
> "Use all recommendations except question 2 - I want configurable retention (option C). For question 6, include calendar view in v1.2.0 (option A)."

I'll update all the documentation accordingly.

### Detailed Approach
Edit this file directly with your decisions, then tell me it's ready for review.

---

**Status**: ✅ ALL DECISIONS APPROVED
**Next Step**: Begin Phase 1 implementation in Code mode