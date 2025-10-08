/// Model representing computed statistics for a recurring task
/// This is a computed model (not stored in Hive)
class RecurringTaskStats {
  final String parentTaskId;
  final int totalInstances; // Total instances created
  final int completedInstances; // Instances marked complete
  final int skippedInstances; // Instances marked as skipped
  final int missedInstances; // Overdue instances not completed
  final int pendingInstances; // Future instances not yet due
  final double
      completionRate; // completedInstances / (totalInstances - pendingInstances)
  final int currentStreak; // Current consecutive completions
  final int longestStreak; // Best ever consecutive completions
  final DateTime? lastCompletedAt;
  final DateTime? nextDueDate;
  final List<DateTime> recentCompletions; // Last 10 completion dates

  RecurringTaskStats({
    required this.parentTaskId,
    required this.totalInstances,
    required this.completedInstances,
    required this.skippedInstances,
    required this.missedInstances,
    required this.pendingInstances,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedAt,
    this.nextDueDate,
    List<DateTime>? recentCompletions,
  }) : recentCompletions = recentCompletions ?? [];

  /// Calculate completion percentage (0-100)
  double get completionPercentage => completionRate * 100;

  /// Check if completion rate is good (>80%)
  bool get hasGoodCompletionRate => completionRate > 0.8;

  /// Check if completion rate is moderate (50-80%)
  bool get hasModerateCompletionRate =>
      completionRate >= 0.5 && completionRate <= 0.8;

  /// Check if completion rate is poor (<50%)
  bool get hasPoorCompletionRate => completionRate < 0.5;

  /// Check if there's an active streak
  bool get hasActiveStreak => currentStreak > 0;

  /// Check if current streak is at or near the longest
  bool get isAtBestStreak =>
      currentStreak >= longestStreak && longestStreak > 0;

  /// Get total eligible instances (excludes pending)
  int get eligibleInstances => totalInstances - pendingInstances;

  /// Create a copy with updated fields
  RecurringTaskStats copyWith({
    String? parentTaskId,
    int? totalInstances,
    int? completedInstances,
    int? skippedInstances,
    int? missedInstances,
    int? pendingInstances,
    double? completionRate,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedAt,
    DateTime? nextDueDate,
    List<DateTime>? recentCompletions,
  }) {
    return RecurringTaskStats(
      parentTaskId: parentTaskId ?? this.parentTaskId,
      totalInstances: totalInstances ?? this.totalInstances,
      completedInstances: completedInstances ?? this.completedInstances,
      skippedInstances: skippedInstances ?? this.skippedInstances,
      missedInstances: missedInstances ?? this.missedInstances,
      pendingInstances: pendingInstances ?? this.pendingInstances,
      completionRate: completionRate ?? this.completionRate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      recentCompletions: recentCompletions ?? this.recentCompletions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecurringTaskStats &&
        other.parentTaskId == parentTaskId &&
        other.totalInstances == totalInstances &&
        other.completedInstances == completedInstances &&
        other.skippedInstances == skippedInstances &&
        other.missedInstances == missedInstances &&
        other.pendingInstances == pendingInstances &&
        other.completionRate == completionRate &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.lastCompletedAt == lastCompletedAt &&
        other.nextDueDate == nextDueDate &&
        _listEquals(other.recentCompletions, recentCompletions);
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return parentTaskId.hashCode ^
        totalInstances.hashCode ^
        completedInstances.hashCode ^
        skippedInstances.hashCode ^
        missedInstances.hashCode ^
        pendingInstances.hashCode ^
        completionRate.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        lastCompletedAt.hashCode ^
        nextDueDate.hashCode ^
        recentCompletions.hashCode;
  }

  @override
  String toString() {
    return 'RecurringTaskStats(parentTaskId: $parentTaskId, totalInstances: $totalInstances, completedInstances: $completedInstances, skippedInstances: $skippedInstances, missedInstances: $missedInstances, pendingInstances: $pendingInstances, completionRate: $completionRate, currentStreak: $currentStreak, longestStreak: $longestStreak, lastCompletedAt: $lastCompletedAt, nextDueDate: $nextDueDate, recentCompletions: $recentCompletions)';
  }
}
