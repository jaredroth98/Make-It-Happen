import 'package:flutter/material.dart';
import '../models/goal.dart'; 
import '../models/partner.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // Controllers read the text the user types
  final _titleController = TextEditingController();
  
  // Default Selections
  String _selectedGoalType = 'Daily'; 
  PrivacyLevel _selectedPrivacy = PrivacyLevel.public;

  // Holds the partners the user selects for this specific goal
  final List<AccountabilityPartner> _selectedPartners = [];

  // Dynamic States for specific goals
  bool _requireSequential = false; // For Objective Goals
  CheatDayStrategy _cheatStrategy = CheatDayStrategy.none; // For Avoidance
  DateTime? _dailyEndDate;

  // A list of all goal types for the dropdown
  final List<String> _goalTypes = ['Daily', 'Objective', 'Avoidance', 'Irregular', 'Cumulative'];

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set a New Goal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      
      // A scrollable view so the keyboard doesn't cover the inputs
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            /// --- 1. UNIVERSAL SETTINGS (Applies to all goals) ---
            const Text("Goal Name", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "e.g., Read 10 Pages",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text("Privacy Level", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<PrivacyLevel>(
              value: _selectedPrivacy,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: PrivacyLevel.values.map((PrivacyLevel level) {
                String displayName = level.name[0].toUpperCase() + level.name.substring(1);

                return DropdownMenuItem(
                  value: level,
                  child: Text(displayName), // e.g., PUBLIC
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedPrivacy = newValue!);
              },
            ),
            const SizedBox(height: 16),

            const Text("Goal Type", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedGoalType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _goalTypes.map((String type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedGoalType = newValue!);
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            /// --- 2. DYNAMIC SETTINGS (Changes based on Goal Type) ---
            
            // DAILY GOAL SETTINGS
            if (_selectedGoalType == 'Daily') ...[
              const Text("Daily Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              ListTile(
                title: const Text("Set an End Date (Optional)"),
                subtitle: Text(_dailyEndDate == null ? "No end date set" : "${_dailyEndDate!.month}/${_dailyEndDate!.day}/${_dailyEndDate!.year}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _dailyEndDate = picked);
                  }
                },
              ),
              if (_dailyEndDate != null)
                TextButton(
                  onPressed: () => setState(() => _dailyEndDate = null), 
                  child: const Text("Clear Date", style: TextStyle(color: Colors.red))
                ),
              const SizedBox(height: 16),
            ],
            
            // If they chose Objective, show this section
            if (_selectedGoalType == 'Objective') ...[
              const Text("Objective Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              SwitchListTile(
                title: const Text("Require sequential checkpoints?"),
                subtitle: const Text("Checkpoints must be completed in order."),
                value: _requireSequential,
                onChanged: (bool value) {
                  setState(() => _requireSequential = value);
                },
              ),
              // You can add a button here later to dynamically add checkpoints to a list
            ],

            // If they chose Avoidance, show this section
            if (_selectedGoalType == 'Avoidance') ...[
              const Text("Avoidance Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              const Text("Cheat Day Strategy"),
              DropdownButtonFormField<CheatDayStrategy>(
                value: _cheatStrategy,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: CheatDayStrategy.values.map((strategy) {
                  return DropdownMenuItem(value: strategy, child: Text(strategy.name));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _cheatStrategy = newValue!);
                },
              ),
            ],

            const SizedBox(height: 40),

            /// --- 3. ACCOUNTABILITY PARTNERS ---
            
            const Text("Notify these partners:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, 
              runSpacing: 4.0, 
              // We filter the network to ONLY show verified partners!
              children: myNetwork.where((p) => p.isVerified).map((partner) {
                final isSelected = _selectedPartners.contains(partner);
                
                return FilterChip(
                  label: Text(partner.firstName),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedPartners.add(partner);
                      } else {
                        _selectedPartners.remove(partner);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            
            /// --- 4. SAVE BUTTON ---
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 1. Create a unique ID (Using the current time is a great MVP trick)
                  String newId = DateTime.now().millisecondsSinceEpoch.toString();
                  String title = _titleController.text;

                  // Fallback in case they leave it completely blank
                  if (title.isEmpty) title = "My New Goal";

                  // Wrap the selected partners with the GoalPartner wrapper (defaulting to hasAcceptedGoal: false)
                  List<GoalPartner> wrappedPartners = _selectedPartners.map((p) {
                    return GoalPartner(partner: p, hasAcceptedGoal: false);
                  }).toList();

                  Goal ? createdGoal;

                  // 2. Build the correct object based on their selection
                  if (_selectedGoalType == 'Daily') {
                    createdGoal = DailyGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, assignedPartners: wrappedPartners, endDate: _dailyEndDate);
                  } else if (_selectedGoalType == 'Objective') {
                    createdGoal = ObjectiveGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, requireSequentialCheckpoints: _requireSequential);
                  } else if (_selectedGoalType == 'Avoidance') {
                    createdGoal = AvoidanceGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, cheatStrategy: _cheatStrategy);
                  } else if (_selectedGoalType == 'Irregular') {
                    // Using a dummy default for MVP so it doesn't crash
                    createdGoal = IrregularGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, scheduleType: IrregularScheduleType.specificDays);
                  } else if (_selectedGoalType == 'Cumulative') {
                    // Using a dummy target of 100 for MVP
                    createdGoal = CumulativeGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, targetAmount: 100); 
                  }
                  
                  // 3. Close the screen and hand the object back to the previous screen
                  Navigator.pop(context, createdGoal); 
                },
                child: const Text('Create Goal', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}