import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/goal.dart';
import 'edit_goal_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  DateTime _focusedDay = DateTime.now();

  int _calculateBestStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    List<DateTime> sorted = dates.toList()..sort();
    int best = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      int difference = sorted[i].difference(sorted[i - 1]).inDays;
      if (difference == 1) {
        current++;
        if (current > best) best = current;
      } else if (difference > 1) {
        current = 1; 
      }
    }
    return best;
  }

  String _getGoalTypeString(Goal goal) {
    if (goal is DailyGoal) return "Daily Goal";
    if (goal is ObjectiveGoal) return "Objective Goal";
    if (goal is AvoidanceGoal) return "Avoidance Goal";
    if (goal is IrregularGoal) return "Irregular Goal";
    if (goal is CumulativeGoal) return "Cumulative Goal";
    return "Unknown Goal Type";
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  // NEW: Helper function to calculate and format the 10-day countdown
  String _getCountdownText(DateTime endDate) {
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime end = DateTime(endDate.year, endDate.month, endDate.day);
    
    int daysRemaining = end.difference(today).inDays;

    if (daysRemaining > 0 && daysRemaining <= 10) {
      return " ($daysRemaining days remaining!)";
    } else if (daysRemaining == 0) {
      return " (Last day!)";
    } else if (daysRemaining < 0) {
      return " (Finished)";
    }
    return ""; // Return nothing if it's more than 10 days away
  }

  void _showToggleDateDialog(DateTime date, DailyGoal dailyGoal) {
    bool isCompleted = dailyGoal.isCompletedOn(date);
    String actionText = isCompleted ? "Remove 'Completed' from" : "Mark 'Completed' on";
    String dateStr = "${date.month}/${date.day}/${date.year}";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Log"),
        content: Text("$actionText $dateStr?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isCompleted) {
                  dailyGoal.removeCompletion(date);
                } else {
                  dailyGoal.markCompleted(date);
                }
              });
              Navigator.pop(context); 
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final didUpdate = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditGoalScreen(goal: goal)),
              );
              if (didUpdate == true) setState(() {}); 
            },
          )
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER INFO ---
            Text(goal.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: Colors.blueGrey[600]),
                const SizedBox(width: 6),
                Text(_getGoalTypeString(goal), style: TextStyle(color: Colors.blueGrey[600], fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text("Privacy: ${goal.privacy.name[0].toUpperCase()}${goal.privacy.name.substring(1)}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),

            // Deadlines / End Dates Display
            if (goal is DailyGoal && goal.endDate != null)
              Row(
                children: [
                  const Icon(Icons.event_available, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  // NEW: We append the countdown text right after the formatted date!
                  Text("End Date: ${_formatDate(goal.endDate!)}${_getCountdownText(goal.endDate!)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                ],
              ),
            if (goal is ObjectiveGoal && goal.targetCompletionDate != null)
              Row(
                children: [
                  const Icon(Icons.event_available, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text("Deadline: ${_formatDate(goal.targetCompletionDate!)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                ],
              ),
            if (goal is CumulativeGoal && goal.deadline != null)
              Row(
                children: [
                  const Icon(Icons.event_available, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text("Deadline: ${_formatDate(goal.deadline!)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                ],
              ),
              
            const Divider(height: 24),

            // --- 2. ACCOUNTABILITY PARTNERS ---
            if (goal.assignedPartners.isNotEmpty) ...[
              const Text("Assigned Partners", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: goal.assignedPartners.map((gp) {
                  return Chip(
                    avatar: Icon(gp.hasAcceptedGoal ? Icons.check_circle : Icons.pending, color: gp.hasAcceptedGoal ? Colors.green : Colors.orange, size: 18),
                    label: Text(gp.partner.firstName),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // --- 3. CHECKPOINTS (Objective Goals Only) ---
            if (goal is ObjectiveGoal && goal.checkpoints.isNotEmpty) ...[
              const Text("Checkpoints", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: goal.checkpoints.asMap().entries.map((entry) {
                    int index = entry.key;
                    Checkpoint cp = entry.value;
                    bool isLocked = !goal.canCompleteCheckpoint(index);

                    return CheckboxListTile(
                      title: Text(cp.title, style: TextStyle(decoration: cp.isCompleted ? TextDecoration.lineThrough : null, color: isLocked ? Colors.grey : Colors.black87)),
                      subtitle: isLocked ? const Text("Complete previous steps first", style: TextStyle(fontSize: 12)) : null,
                      value: cp.isCompleted,
                      activeColor: Colors.green,
                      // Notice the 'async' keyword so we can await the popup!
                      onChanged: isLocked ? null : (bool? newValue) async {
                        if (newValue == true) {
                          // 1. They are checking the box. Ask for the date!
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          
                          // 2. If they picked a date (and didn't hit cancel), save it!
                          if (pickedDate != null) {
                            setState(() {
                              cp.isCompleted = true;
                              cp.completionDate = pickedDate;
                              goal.isGoalCompleted = goal.checkpoints.every((c) => c.isCompleted);
                            });
                          }
                        } else {
                          // 3. They are unchecking the box. Clear the data.
                          setState(() {
                            cp.isCompleted = false;
                            cp.completionDate = null;
                            goal.isGoalCompleted = goal.checkpoints.every((c) => c.isCompleted);
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- 4. STREAKS ---
            if (goal is DailyGoal) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard("Active Streak", "${goal.activeStreak} Days", Colors.orange),
                  _buildStatCard("Best Streak", "${_calculateBestStreak(goal.completedDates)} Days", Colors.blue),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // --- 5. THE CALENDAR ---
            const Text("History & Timeline", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  
                  onDaySelected: (selectedDay, focusedDay) {
                    DateTime normalizedSelected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                    
                    if (normalizedSelected.isAfter(today)) {
                      return; 
                    }

                    if (goal is DailyGoal) {
                      _showToggleDateDialog(selectedDay, goal);
                    }
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },

                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      DateTime checkDay = DateTime(day.year, day.month, day.day);

                      if (goal is DailyGoal) {
                        bool isEndDate = goal.endDate != null && isSameDay(goal.endDate!, checkDay);
                        if (isEndDate) return _buildCalendarMarker(day.day.toString(), Colors.redAccent, BoxShape.rectangle);
                        if (goal.isCompletedOn(checkDay)) return _buildCalendarMarker(day.day.toString(), Colors.green, BoxShape.circle);
                      }
                      
                      if (goal is ObjectiveGoal) {
                        bool hasCheckpoint = goal.checkpoints.any((c) => c.completionDate != null && isSameDay(c.completionDate!, checkDay));
                        bool isDeadline = goal.targetCompletionDate != null && isSameDay(goal.targetCompletionDate!, checkDay);

                        if (isDeadline) return _buildCalendarMarker(day.day.toString(), Colors.redAccent, BoxShape.rectangle);
                        if (hasCheckpoint) return _buildCalendarMarker(day.day.toString(), Colors.blue, BoxShape.circle);
                      }

                      if (goal is CumulativeGoal && goal.deadline != null && isSameDay(goal.deadline!, checkDay)) {
                         return _buildCalendarMarker(day.day.toString(), Colors.redAccent, BoxShape.rectangle);
                      }

                      return null; 
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarMarker(String text, Color color, BoxShape shape) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(color: color, shape: shape, borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(6) : null),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}