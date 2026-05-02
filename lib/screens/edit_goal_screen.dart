import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/partner.dart'; // To access myNetwork

class EditGoalScreen extends StatefulWidget {
  final Goal goal; // The goal we are editing

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late TextEditingController _titleController;
  late PrivacyLevel _selectedPrivacy;
  
  // Dynamic states
  bool _requireSequential = false;
  CheatDayStrategy _cheatStrategy = CheatDayStrategy.none;
  DateTime? _dailyEndDate;
  
  // For Accountability Partners
  List<AccountabilityPartner> _selectedPartners = [];

  // For Objective Goal Checkpoints (We need a text controller for EVERY checkpoint)
  List<TextEditingController> _checkpointControllers = [];

  @override
  void initState() {
    super.initState();
    
    // 1. PRE-LOAD UNIVERSAL DATA
    _titleController = TextEditingController(text: widget.goal.title);
    _selectedPrivacy = widget.goal.privacy;
    
    // Pre-load partners (extracting the partner from the GoalPartner wrapper)
    _selectedPartners = widget.goal.assignedPartners.map((gp) => gp.partner).toList();

    // 2. PRE-LOAD DYNAMIC DATA BASED ON TYPE
    if (widget.goal is DailyGoal) {
      final dailyGoal = widget.goal as DailyGoal;
      _dailyEndDate = dailyGoal.endDate; // <--- ADD THIS
    } else if (widget.goal is ObjectiveGoal) {
      final objGoal = widget.goal as ObjectiveGoal;
      _requireSequential = objGoal.requireSequentialCheckpoints;
      
      // Create a text controller for each existing checkpoint
      for (var cp in objGoal.checkpoints) {
        _checkpointControllers.add(TextEditingController(text: cp.title));
      }
    } else if (widget.goal is AvoidanceGoal) {
      final avGoal = widget.goal as AvoidanceGoal;
      _cheatStrategy = avGoal.cheatStrategy;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _checkpointControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            /// --- 1. UNIVERSAL SETTINGS ---
            const Text("Goal Name", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            const Text("Privacy Level", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<PrivacyLevel>(
              value: _selectedPrivacy,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: PrivacyLevel.values.map((PrivacyLevel level) {
                String displayName = level.name[0].toUpperCase() + level.name.substring(1);
                return DropdownMenuItem(value: level, child: Text(displayName));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedPrivacy = newValue!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            /// --- 2. DYNAMIC SETTINGS ---
            
            // DAILY GOAL
            if (widget.goal is DailyGoal) ...[
              const Text("Daily Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              ListTile(
                title: const Text("Set an End Date (Optional)"),
                subtitle: Text(_dailyEndDate == null ? "No end date set" : "${_dailyEndDate!.month}/${_dailyEndDate!.day}/${_dailyEndDate!.year}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dailyEndDate ?? DateTime.now(),
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
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // OBJECTIVE GOAL: Checkpoint Editor
            if (widget.goal is ObjectiveGoal) ...[
              const Text("Checkpoints", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              SwitchListTile(
                title: const Text("Require sequential checkpoints?"),
                value: _requireSequential,
                onChanged: (bool value) => setState(() => _requireSequential = value),
              ),
              const SizedBox(height: 8),
              
              // Draw the list of current checkpoints
              ..._checkpointControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: "Checkpoint ${index + 1}",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _checkpointControllers[index].dispose();
                            _checkpointControllers.removeAt(index);
                          });
                        },
                      )
                    ],
                  ),
                );
              }),
              
              // Button to add a new blank checkpoint
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _checkpointControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Checkpoint"),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // AVOIDANCE GOAL
            if (widget.goal is AvoidanceGoal) ...[
              const Text("Avoidance Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CheatDayStrategy>(
                value: _cheatStrategy,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Cheat Day Strategy"),
                items: CheatDayStrategy.values.map((strategy) {
                  return DropdownMenuItem(value: strategy, child: Text(strategy.name));
                }).toList(),
                onChanged: (newValue) => setState(() => _cheatStrategy = newValue!),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            /// --- 3. ACCOUNTABILITY PARTNERS ---
            const Text("Notify these partners:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, 
              runSpacing: 4.0, 
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
                  // 1. UPDATE UNIVERSAL PROPERTIES
                  widget.goal.title = _titleController.text;
                  widget.goal.privacy = _selectedPrivacy;
                  
                  // Update partners (Note: In a production app, we would write logic here 
                  // to preserve the hasAcceptedGoal status of existing partners, 
                  // but for the MVP we will just rebuild the list).
                  widget.goal.assignedPartners = _selectedPartners.map((p) {
                    return GoalPartner(partner: p, hasAcceptedGoal: false);
                  }).toList();

                  // 2. UPDATE DYNAMIC PROPERTIES
                  if (widget.goal is DailyGoal) {
                    final dailyGoal = widget.goal as DailyGoal;
                    dailyGoal.endDate = _dailyEndDate;
                  } else if (widget.goal is ObjectiveGoal) {
                    final objGoal = widget.goal as ObjectiveGoal;
                    objGoal.requireSequentialCheckpoints = _requireSequential;
                    
                    // We take a snapshot of the old checkpoints before we overwrite them
                    List<Checkpoint> oldCheckpoints = objGoal.checkpoints;
                    
                    objGoal.checkpoints = _checkpointControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      String newTitle = entry.value.text;
                      
                      // If a checkpoint already existed at this spot, just update the title
                      if (index < oldCheckpoints.length) {
                        oldCheckpoints[index].title = newTitle;
                        return oldCheckpoints[index];
                      } else {
                        // If there is no old checkpoint here, they must have clicked "Add Checkpoint"
                        return Checkpoint(title: newTitle);
                      }
                    }).toList();
                  } else if (widget.goal is AvoidanceGoal) {
                    final avGoal = widget.goal as AvoidanceGoal;
                    avGoal.cheatStrategy = _cheatStrategy;
                  }

                  // 3. Return 'true' to tell the previous screen that data changed!
                  Navigator.pop(context, true); 
                },
                child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}