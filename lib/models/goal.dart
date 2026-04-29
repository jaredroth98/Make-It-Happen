/// Every goal will share these properties
abstract class Goal {
  String id;
  String title;
  DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  double calculateProgress();
}

/// ----------------------------------------
/// 1. Objective Goal (e.g. Run a Marathon)
/// ----------------------------------------

class Checkpoint {
  String title;
  bool isCompleted;
  DateTime? targetDate;  // ? means this can be null (optional)

  Checkpoint({
    required this.title,
    this.isCompleted = false,
    this.targetDate,
  });
}

class ObjectiveGoal extends Goal {
  DateTime? targetCompletionDate;
  List<Checkpoint> checkpoints;
  bool requireSequentialCheckpoints;
  bool isGoalCompleted;

  ObjectiveGoal({
    required super.id,
    required super.title,
    required super.createdAt,
    this.targetCompletionDate,
    this.checkpoints = const [],
    this.requireSequentialCheckpoints = false,
    this.isGoalCompleted = false,
  });

  @override
  double calculateProgress() {
    if (isGoalCompleted) return 1.0;
    if (checkpoints.isEmpty) return 0.0;
    
    int completedCount = checkpoints.where((cp) => cp.isCompleted).length;
    return completedCount / checkpoints.length;
  }

  // A helper function to check if a specific checkpoint is allowed to be checked off
  bool canCompleteCheckpoint(int index) {
    if (!requireSequentialCheckpoints || index == 0) return true;

    // If sequential is true, the previous checkpoint must be completed
    return checkpoints[index - 1].isCompleted;
  }
}

/// ----------------------------------------
/// 2. Daily Goal (e.g. Give a compliment)
/// ----------------------------------------

class DailyGoal extends Goal {
  // Instead of a simple boolean, we store every day the user completes the habit
  // This allows us to build the "green calendar" view
  Set<DateTime> completedDates;

  DailyGoal({
    required super.id,
    required super.title,
    required super.createdAt,
    Set<DateTime>? completedDates,
  }) : completedDates = completedDates ?? {};

  // Strips off the time of a date so we only compare Year/Month/Day
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.date);
  }

  // Mark today as done
  void markCompleted(DateTime date) {
    completedDates.add(_normalizeDate(date));
  }

  // Check if a specific day is done
  bool isCompletedOn(DateTime date) {
    return completedDates.contains(_normalizeDate(date));
  }

  // Calculates the current active streak
  int get activeStreak {
    int streak = 0;
    DateTime checkDate = _normalizeDate(DateTime.now());

    // Walk backwards day by day to count the streak
    while (isCompletedOn(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  double calculateProgress() {
    // For a daily goal, progress on the main screen just means "Is it done today?"
    return isCompletedOn(DateTime.now()) ? 1.0 : 0.0;
  }
}

/// ----------------------------------------
/// 3. Placeholders
/// ----------------------------------------

class AvoidanceGoal extends Goal {
  AvoidanceGoal({required super.id, required super.title, required super.createdAt});

  @override
  double calculateProgress() => 0.0; // Logic TBD
}

class CumulativeGoal extends Goal {
  CumulativeGoal({required super.id, required super.title, required super.createdAt});

  @override
  double calculateProgress() => 0.0; // Logic TBD
}

class IrregularGoal extends Goal {
  IrregularGoal({required super.id, required super.title, required super.createdAt});

  @override
  double calculateProgress() => 0.0; // Logic TBD
}