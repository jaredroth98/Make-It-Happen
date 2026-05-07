import 'package:flutter/material.dart';
import '../models/goal.dart';
import 'add_goal_screen.dart';
import 'goal_details_screen.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    // The UI
      body: StreamBuilder<List<Goal>>(
        // 1. Tell it which pipeline to listen to
        stream: DatabaseService(userId: AuthService().currentUser!.uid).goals,
        builder: (context, snapshot) {
          
          // 2. Handle the loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Handle errors
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          // 4. Extract the goals from the pipeline
          List<Goal> goals = snapshot.data ?? [];

          // 5. Handle empty state
          if (goals.isEmpty) {
            return const Center(child: Text("No goals yet! Tap + to Make It Happen.", style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          // 6. Build the list (This is almost exactly your old code!)
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              
              String? subtitleText;
              if (goal is DailyGoal) {
                subtitleText = 'Active Streak: ${goal.activeStreak} Days';
              } else if (goal is AvoidanceGoal) {
                subtitleText = 'Active Streak: ${goal.activeStreak} Days'; // Added Avoidance!
              } else if (goal is ObjectiveGoal) {
                if (goal.checkpoints.isEmpty) {
                  subtitleText = null; 
                } else {
                  int completedCount = goal.checkpoints.where((c) => c.isCompleted).length;
                  subtitleText = '$completedCount out of ${goal.checkpoints.length} checkpoints completed';
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom:12.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Icon(
                    goal is DailyGoal ? Icons.calendar_today : 
                    goal is AvoidanceGoal ? Icons.close : // The big X for Avoidance!
                    Icons.flag, // Default for Objective, etc.
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  title: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: subtitleText != null ? Text(subtitleText, style: TextStyle(color: Colors.grey[700])) : null,
                  trailing: Builder(
                    builder: (context) {
                      if (goal is DailyGoal) {
                        bool completedToday = goal.isCompletedOn(DateTime.now());
                        return IconButton(
                          icon: Icon(completedToday ? Icons.check_circle : Icons.circle_outlined),
                          color: completedToday ? Colors.green : Colors.grey,
                          iconSize: 32,
                          onPressed: () async {
                            completedToday ? goal.removeCompletion(DateTime.now()) : goal.markCompleted(DateTime.now());
                            await DatabaseService(userId: AuthService().currentUser!.uid).saveGoal(goal);
                          },
                        );
                      } else if (goal is AvoidanceGoal) {
                        // --- NEW AVOIDANCE UI ---
                        DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                        bool failedToday = goal.failedDates.contains(today);
                        
                        return IconButton(
                          // Shows a Shield if safe, a red Cancel if failed
                          icon: Icon(failedToday ? Icons.cancel : Icons.shield_outlined),
                          color: failedToday ? Colors.red : Colors.grey,
                          iconSize: 32,
                          onPressed: () async {
                            failedToday ? goal.removeFailure(DateTime.now()) : goal.markFailed(DateTime.now());
                            await DatabaseService(userId: AuthService().currentUser!.uid).saveGoal(goal);
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
                  onTap: () {
                    // No need for 'async/await' or 'setState' here anymore! 
                    // The StreamBuilder handles redrawing the screen automatically.
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GoalDetailsScreen(goal: goal)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Add Goal screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}