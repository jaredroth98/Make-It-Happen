import 'package:flutter/material.dart';
import '../models/goal.dart';
import 'add_goal_screen.dart';
import 'goal_details_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // MOCK DATA
  // This is just temporary, fake data
  final List<Goal> _myGoals = [
    DailyGoal(
      id: 'g1',
      title: 'Read 10 Pages',
      createdAt: DateTime.now(),
    ),
    ObjectiveGoal(
      id: 'g2',
      title: 'Run a Marathon',
      createdAt: DateTime.now(),
      requireSequentialCheckpoints: true,
      checkpoints: [
        Checkpoint(title: 'Run a 5k'),
        Checkpoint(title: 'Run a 10k'),
        Checkpoint(title: 'Run a half marathon'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    // The UI
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _myGoals.length,
        itemBuilder: (context,index) {
          final goal = _myGoals[index];

          // Determine the correct subtitle text BEFORE drawing the card
          String subtitleText = 'Progress: ${(goal.calculateProgress() * 100).toInt()}%';
          if (goal is DailyGoal) {
            subtitleText = 'Active Streak: ${goal.activeStreak} Days';
          } else if (goal is ObjectiveGoal) {
            int completedCount = goal.checkpoints.where((c) => c.isCompleted).length;
            subtitleText = '$completedCount out of ${goal.checkpoints.length} checkpoints completed';
          }
          
          // Wrap each item in a Card
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom:12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),

              // Leading icon changes based on what type of goal it is
              leading: Icon(
                goal is DailyGoal ? Icons.calendar_today : Icons.flag,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),

              title: Text(
                goal.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              // Subtitle
              subtitle: Text(
                subtitleText,
                style: TextStyle(color: Colors.grey[700]),
              ),

              // Quick-Action Buttons for Daily & Avoidance
              trailing: Builder(
                builder: (context) {
                  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                  // Quick Check for Daily Goals
                  if (goal is DailyGoal) {
                    bool isDone = goal.completedDates.contains(today);
                    return IconButton(
                      icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                      color: isDone ? Colors.green : Colors.grey,
                      onPressed: () {
                        setState(() {
                          isDone ? goal.completedDates.remove(today) : goal.markCompleted(DateTime.now());
                        });
                      },
                    );
                  }
                  
                  // Quick Fail for Avoidance Goals
                  if (goal is AvoidanceGoal) {
                    bool hasFailed = goal.failedDates.contains(today);
                    return IconButton(
                      icon: Icon(hasFailed ? Icons.cancel : Icons.shield_outlined),
                      color: hasFailed ? Colors.red : Colors.green,
                      onPressed: () {
                        setState(() {
                          hasFailed ? goal.failedDates.remove(today) : goal.markFailed(DateTime.now());
                        });
                      },
                    );
                  }

                  // Default arrow for Objective, Cumulative, and Irregular goals
                  return const Icon(Icons.arrow_forward_ios, size: 16);
                }
              ),

              // What happens when they click the goal
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Pass the specific goal that was tapped to the new screen
                    builder: (context) => GoalDetailsScreen(goal: goal),
                  ),
                );
                setState(() {});
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        // Notice the 'async' keyword. This tells Flutter "This button triggers an action that takes time."
        onPressed: () async { 
          // 'await' pauses this specific function until the AddGoalScreen closes
          final newGoal = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );

          // If the user actually created a goal (and didn't just hit the back arrow to cancel)
          if (newGoal != null && newGoal is Goal) {
            // setState tells the screen to redraw itself with the new data!
            setState(() {
              _myGoals.add(newGoal);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}