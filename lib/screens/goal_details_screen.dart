import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/goal.dart';

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

  // A helper function to get a clean string for the goal type
  String _getGoalTypeString(Goal goal) {
    if (goal is DailyGoal) return "Daily Goal";
    if (goal is ObjectiveGoal) return "Objective Goal";
    if (goal is AvoidanceGoal) return "Avoidance Goal";
    if (goal is IrregularGoal) return "Irregular Goal";
    if (goal is CumulativeGoal) return "Cumulative Goal";
    return "Unknown Goal Type";
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
            onPressed: () {
              print("Navigate to Edit Screen for ${goal.id}");
              // TODO: Navigator.push to EditGoalScreen
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
            Text(
              goal.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // NEW: The Goal Type Row
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: Colors.blueGrey[600]),
                const SizedBox(width: 6),
                Text(
                  _getGoalTypeString(goal),
                  style: TextStyle(color: Colors.blueGrey[600], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Updated: The Privacy Row
            Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  // Grabbing the first letter to capitalize it, just like we did in the form
                  "Privacy: ${goal.privacy.name[0].toUpperCase()}${goal.privacy.name.substring(1)}",
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 32),

            // --- 2. STREAKS ---
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

            // --- 3. THE CALENDAR ---
            const Text("History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  
                  // NEW: Hides the "2 weeks" button and centers the month text
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),

                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay; 
                  },
                  
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      DateTime checkDay = DateTime(day.year, day.month, day.day);

                      if (goal is DailyGoal && goal.isCompletedOn(checkDay)) {
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: Center(
                            child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                          ),
                        );
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