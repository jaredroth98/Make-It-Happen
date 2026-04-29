enum PrivacyLevel { public, private, hidden }

/// Every goal will share these properties
abstract class Goal {
  String id;
  String title;
  DateTime createdAt;
  PrivacyLevel privacy;

  Goal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.privacy = PrivacyLevel.public,
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
    super.privacy,
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
    super.privacy,
    Set<DateTime>? completedDates,
  }) : completedDates = completedDates ?? {};

  // Strips off the time of a date so we only compare Year/Month/Day
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

/// ---------------------------------------------------------
/// 3. AVOIDANCE GOAL (e.g., No Social Media)
/// ---------------------------------------------------------

// How are cheat days generated?
enum CheatDayStrategy { none, specificFrequency, randomFrequency, manual }

class AvoidanceGoal extends Goal {
  // Unlike Daily goals, we track when they FAIL, not when they succeed.
  Set<DateTime> failedDates;
  Set<DateTime> generatedCheatDays;
  
  CheatDayStrategy cheatStrategy;
  bool hideUpcomingCheatDays;

  AvoidanceGoal({
    required super.id,
    required super.title,
    required super.createdAt,
    super.privacy,
    Set<DateTime>? failedDates,
    Set<DateTime>? generatedCheatDays,
    this.cheatStrategy = CheatDayStrategy.none,
    this.hideUpcomingCheatDays = false,
  }) : failedDates = failedDates ?? {},
       generatedCheatDays = generatedCheatDays ?? {};

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void markFailed(DateTime date) {
    failedDates.add(_normalizeDate(date));
  }

  bool isCheatDay(DateTime date) {
    return generatedCheatDays.contains(_normalizeDate(date));
  }

  @override
  double calculateProgress() {
    DateTime today = _normalizeDate(DateTime.now());
    
    // If it's a cheat day, they get a 100% free pass for today
    if (isCheatDay(today)) return 1.0; 
    
    // Otherwise, they are at 100% UNLESS they explicitly failed today
    return failedDates.contains(today) ? 0.0 : 1.0; 
  }

  // Active Streak with "Frozen" Cheat Days
  int get activeStreak {
    int streak = 0;
    DateTime checkDate = _normalizeDate(DateTime.now());

    // Walk backwards. 
    while (true) {
      if (isCheatDay(checkDate)) {
        // Streak is frozen. Do not increment, but do not break. Skip to yesterday.
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }
      
      if (failedDates.contains(checkDate)) {
        break; // They failed, streak is over.
      }
      
      // They survived the day!
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

/// ---------------------------------------------------------
/// 4. IRREGULAR FREQUENCY GOAL (e.g., 3x a week, or every Tuesday)
/// ---------------------------------------------------------

enum IrregularScheduleType { specificDays, calendarPeriod, rollingWindow }

class IrregularGoal extends Goal {
  Set<DateTime> completedDates;
  IrregularScheduleType scheduleType;
  
  // Variables for 'Specific Days' (1 = Monday, 7 = Sunday)
  List<int>? allowedWeekdays;
  
  // Variables for 'Frequencies'
  int? targetFrequency; // e.g., 5 times
  int? windowInDays;    // e.g., per 7 days

  IrregularGoal({
    required super.id,
    required super.title,
    required super.createdAt,
    super.privacy,
    Set<DateTime>? completedDates,
    required this.scheduleType,
    this.allowedWeekdays,
    this.targetFrequency,
    this.windowInDays,
  }) : completedDates = completedDates ?? {};

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void markCompleted(DateTime date) {
    completedDates.add(_normalizeDate(date));
  }

  @override
  double calculateProgress() {
    // The calculation here will be dynamic based on the scheduleType.
    // For the MVP, we will return 0.0 until we build the specific window logic.
    if (completedDates.isEmpty) return 0.0;
    
    if (scheduleType == IrregularScheduleType.specificDays) {
      return completedDates.contains(_normalizeDate(DateTime.now())) ? 1.0 : 0.0;
    }
    
    // Future logic for rolling/calendar windows goes here
    return 0.5; 
  }
}

/// ---------------------------------------------------------
/// 5. CUMULATIVE GOAL (e.g., Read 500 pages)
/// ---------------------------------------------------------

class CumulativeGoal extends Goal {
  double targetAmount;
  DateTime? deadline;
  
  // Instead of a single number, we store a Map of {Date : Amount}.
  // This allows the user to look back and see EXACTLY what days they made progress.
  Map<DateTime, double> progressLog;

  CumulativeGoal({
    required super.id,
    required super.title,
    required super.createdAt,
    super.privacy,
    required this.targetAmount,
    this.deadline,
    Map<DateTime, double>? progressLog,
  }) : progressLog = progressLog ?? {};

  // Adds up all the entries in the log
  double get currentTotal {
    return progressLog.values.fold(0.0, (sum, amount) => sum + amount);
  }

  void addProgress(DateTime date, double amount) {
    DateTime normalized = DateTime(date.year, date.month, date.day);
    // If there is already progress for today, add to it. Otherwise, set it.
    progressLog[normalized] = (progressLog[normalized] ?? 0.0) + amount;
  }

  @override
  double calculateProgress() {
    if (targetAmount <= 0) return 0.0;
    // .clamp ensures it never goes above 100% (1.0) visually
    return (currentTotal / targetAmount).clamp(0.0, 1.0); 
  }
}