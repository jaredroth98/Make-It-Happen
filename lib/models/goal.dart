import 'package:make_it_happen/models/partner.dart';

enum PrivacyLevel { public, private, hidden }

class GoalPartner {
  AccountabilityPartner partner;
  bool hasAcceptedGoal;

  GoalPartner({
    required this.partner,
    this.hasAcceptedGoal = false,
  });
}

/// Every goal will share these properties
abstract class Goal {
  String id;
  String title;
  DateTime createdAt;
  PrivacyLevel privacy;
  List<GoalPartner> assignedPartners;
  List<String> supporterIds;
  Map<String, String> supporterStatuses;

  Goal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.privacy = PrivacyLevel.public,
    this.assignedPartners = const [],
    List<String>? supporterIds,
    Map<String, String>? supporterStatuses,
  })  : this.supporterIds = supporterIds ?? [],
        this.supporterStatuses = supporterStatuses ?? {};

  double calculateProgress();
}

/// ----------------------------------------
/// 1. Objective Goal (e.g. Run a Marathon)
/// ----------------------------------------

class Checkpoint {
  String title;
  bool isCompleted;
  DateTime? targetDate;  // The planned deadline for this step
  DateTime? completionDate; // The day they actually did it!

  Checkpoint({
    required this.title,
    this.isCompleted = false,
    this.targetDate,
    this.completionDate,
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
    super.assignedPartners,
    this.targetCompletionDate,
    this.checkpoints = const [],
    this.requireSequentialCheckpoints = false,
    this.isGoalCompleted = false,
    super.supporterIds,
    super.supporterStatuses,
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
  Set<DateTime> completedDates;
  DateTime? endDate; // NEW: The optional last day

  DailyGoal({
    required super.id,
    required super.title,
    required super.createdAt,
    super.privacy,
    super.assignedPartners,
    Set<DateTime>? completedDates,
    this.endDate,
    super.supporterIds,
    super.supporterStatuses,
  }) : completedDates = completedDates ?? {};

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void markCompleted(DateTime date) {
    completedDates.add(_normalizeDate(date));
  }

  // NEW: Helper to un-check a day
  void removeCompletion(DateTime date) {
    completedDates.remove(_normalizeDate(date));
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(_normalizeDate(date));
  }

  int get activeStreak {
    int streak = 0;
    DateTime today = _normalizeDate(DateTime.now());
    DateTime checkDate = today;

    // 1. Is today complete?
    if (isCompletedOn(today)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1)); // Move to yesterday
    } else {
      // 2. Today is NOT complete. Let's see if the streak is still alive from yesterday.
      checkDate = checkDate.subtract(const Duration(days: 1)); // Move to yesterday
      if (!isCompletedOn(checkDate)) {
        // They missed yesterday AND haven't done today. Streak is officially broken.
        return 0;
      }
    }

    // 3. Keep counting backwards for all consecutive previous days
    while (isCompletedOn(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  @override
  double calculateProgress() {
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
    super.assignedPartners,
    Set<DateTime>? failedDates,
    Set<DateTime>? generatedCheatDays,
    this.cheatStrategy = CheatDayStrategy.none,
    this.hideUpcomingCheatDays = false,
    super.supporterIds,
    super.supporterStatuses,
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
    super.assignedPartners,
    Set<DateTime>? completedDates,
    required this.scheduleType,
    this.allowedWeekdays,
    this.targetFrequency,
    this.windowInDays,
    super.supporterIds,
    super.supporterStatuses,
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
    super.assignedPartners,
    required this.targetAmount,
    this.deadline,
    Map<DateTime, double>? progressLog,
    super.supporterIds,
    super.supporterStatuses,
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