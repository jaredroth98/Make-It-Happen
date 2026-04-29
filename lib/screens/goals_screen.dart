import 'package:flutter/material.dart';
import '../models/goal.dart';

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
    // The UI
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _myGoals.length,
      itemBuilder: (context,index) {
        final goal = _myGoals[index];

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

            // Subtitle shows the current progress
            subtitle: Text(
              'Progress: ${(goal.calculateProgress() * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[700]),
            ),

            trailing: const Icon(Icons.arrow_forward_ios, size: 16),

            // What happens when they click the goal
            onTap: () {
              print('Clicked on ${goal.title}!');
              // TODO: Navigate to the details page
            },
          ),
        );
      },
    );
  }
}