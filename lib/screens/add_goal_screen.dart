import 'package:flutter/material.dart';
import '../models/goal.dart'; 
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedGoalType = '(Select Goal Type)'; 
  PrivacyLevel _selectedPrivacy = PrivacyLevel.public;

  // Accountability Partners
  final List<Map<String, dynamic>> _selectedPartners = [];

  // Dynamic States
  bool _requireSequential = false; 
  CheatDayStrategy _cheatStrategy = CheatDayStrategy.none; 
  DateTime? _dailyEndDate; 
  
  // NEW: Objective Goal States
  DateTime? _objectiveTargetDate;
  final List<TextEditingController> _checkpointControllers = [];
  final List<DateTime?> _checkpointDeadlines = [];

  final List<String> _goalTypes = ['(Select Goal Type)', 'Daily', 'Objective', 'Avoidance', 'Irregular', 'Cumulative'];

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
        title: const Text('Set a New Goal'),
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
              decoration: const InputDecoration(hintText: "e.g., Read 10 Pages", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            const Text("Goal Description (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _descriptionController,
              maxLines: 3, // Gives them some room to write!
              decoration: const InputDecoration(hintText: "Why is this goal important to you?", border: OutlineInputBorder()),
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
            const SizedBox(height: 16),

            const Text("Goal Type", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedGoalType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _goalTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (newValue) => setState(() => _selectedGoalType = newValue!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            /// --- 2. DYNAMIC SETTINGS ---
            
            // DAILY GOAL
            if (_selectedGoalType == 'Daily') ...[
              const Text("Daily Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              ListTile(
                title: const Text("Set an End Date (Optional)"),
                subtitle: Text(_dailyEndDate == null ? "No end date set" : "${_dailyEndDate!.month}/${_dailyEndDate!.day}/${_dailyEndDate!.year}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _dailyEndDate = picked);
                },
              ),
              if (_dailyEndDate != null)
                TextButton(onPressed: () => setState(() => _dailyEndDate = null), child: const Text("Clear Date", style: TextStyle(color: Colors.red))),
            ],

            // OBJECTIVE GOAL
            if (_selectedGoalType == 'Objective') ...[
              const Text("Objective Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              
              // NEW: Overall Deadline
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Overall Deadline (Optional)"),
                subtitle: Text(_objectiveTargetDate == null ? "No deadline set" : "${_objectiveTargetDate!.month}/${_objectiveTargetDate!.day}/${_objectiveTargetDate!.year}", style: const TextStyle(color: Colors.redAccent)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _objectiveTargetDate = picked);
                },
              ),
              if (_objectiveTargetDate != null)
                TextButton(onPressed: () => setState(() => _objectiveTargetDate = null), child: const Text("Clear Overall Deadline", style: TextStyle(color: Colors.red))),
              
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Require sequential checkpoints?"),
                subtitle: const Text("Checkpoints must be completed in order."),
                value: _requireSequential,
                onChanged: (bool value) => setState(() => _requireSequential = value),
              ),
              const SizedBox(height: 16),
              const Text("Checkpoints", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // NEW: Dynamic Checkpoint Builder with Deadlines
              ..._checkpointControllers.asMap().entries.map((entry) {
                int index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _checkpointControllers[index],
                              decoration: InputDecoration(labelText: "Checkpoint ${index + 1}", border: const OutlineInputBorder()),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_checkpointDeadlines[index] == null ? Icons.calendar_month : Icons.edit_calendar, color: _checkpointDeadlines[index] == null ? Colors.grey : Colors.blue),
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: _checkpointDeadlines[index] ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setState(() => _checkpointDeadlines[index] = picked);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() {
                              _checkpointControllers[index].dispose();
                              _checkpointControllers.removeAt(index);
                              _checkpointDeadlines.removeAt(index);
                            }),
                          )
                        ],
                      ),
                      if (_checkpointDeadlines[index] != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                          child: Text("Deadline: ${_checkpointDeadlines[index]!.month}/${_checkpointDeadlines[index]!.day}/${_checkpointDeadlines[index]!.year}", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() {
                  _checkpointControllers.add(TextEditingController());
                  _checkpointDeadlines.add(null);
                }),
                icon: const Icon(Icons.add),
                label: const Text("Add Checkpoint"),
              ),
            ],

            // AVOIDANCE GOAL
            if (_selectedGoalType == 'Avoidance') ...[
              const Text("Avoidance Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CheatDayStrategy>(
                value: _cheatStrategy,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Cheat Day Strategy"),
                items: CheatDayStrategy.values.map((strategy) => DropdownMenuItem(value: strategy, child: Text(strategy.name))).toList(),
                onChanged: (newValue) => setState(() => _cheatStrategy = newValue!),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            /// --- 3. ACCOUNTABILITY PARTNERS ---
            const Text("Notify these partners:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            StreamBuilder<QuerySnapshot>(
              stream: DatabaseService(userId: AuthService().currentUser!.uid).partners,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                // Filter for only 'accepted' (verified) partners
                final verifiedPartners = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .where((data) => data['status'] == 'accepted')
                    .toList();

                if (verifiedPartners.isEmpty) {
                  return const Text("No verified partners yet. Add them in the Accountability tab!", style: TextStyle(color: Colors.grey));
                }

                return Wrap(
                  spacing: 8.0, 
                  runSpacing: 4.0, 
                  children: verifiedPartners.map((partnerMap) {
                    final uid = partnerMap['uid'];
                    final name = partnerMap['displayName'];
                    
                    // Check if this partner is in our selected list
                    final isSelected = _selectedPartners.any((p) => p['uid'] == uid);

                    return FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPartners.add(partnerMap);
                          } else {
                            _selectedPartners.removeWhere((p) => p['uid'] == uid);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),

            /// --- 4. SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Require goal type selection
                  if (_selectedGoalType == '(Select Goal Type)') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select a Goal Type!"), 
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return; // This completely stops the save process!
                  }
                  String newId = DateTime.now().millisecondsSinceEpoch.toString();
                  String title = _titleController.text;
                  if (title.isEmpty) title = "My New Goal";

                  // --- Package the real Firestore relationships! ---
                  List<String> newSupporterIds = _selectedPartners.map((p) => p['uid'] as String).toList();
                  Map<String, String> newSupporterStatuses = {};
                  for (var uid in newSupporterIds) {
                    newSupporterStatuses[uid] = 'pending'; // Set them all to pending initially!
                  }
                  // ------------------------------------------------------

                  Goal? createdGoal;

                  if (_selectedGoalType == 'Daily') {
                    createdGoal = DailyGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, endDate: _dailyEndDate, supporterIds: newSupporterIds, supporterStatuses: newSupporterStatuses, description: _descriptionController.text);
                  } else if (_selectedGoalType == 'Objective') {
                    List<Checkpoint> builtCheckpoints = [];
                    for (int i = 0; i < _checkpointControllers.length; i++) {
                      if (_checkpointControllers[i].text.isNotEmpty) {
                        builtCheckpoints.add(Checkpoint(title: _checkpointControllers[i].text, targetDate: _checkpointDeadlines[i]));
                      }
                    }
                    createdGoal = ObjectiveGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, requireSequentialCheckpoints: _requireSequential, targetCompletionDate: _objectiveTargetDate, checkpoints: builtCheckpoints, supporterIds: newSupporterIds, supporterStatuses: newSupporterStatuses, description: _descriptionController.text);
                  } else if (_selectedGoalType == 'Avoidance') {
                    createdGoal = AvoidanceGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, cheatStrategy: _cheatStrategy, supporterIds: newSupporterIds, supporterStatuses: newSupporterStatuses, description: _descriptionController.text);
                  } else if (_selectedGoalType == 'Irregular') {
                    createdGoal = IrregularGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, scheduleType: IrregularScheduleType.specificDays, supporterIds: newSupporterIds, supporterStatuses: newSupporterStatuses, description: _descriptionController.text);
                  } else if (_selectedGoalType == 'Cumulative') {
                    createdGoal = CumulativeGoal(id: newId, title: title, createdAt: DateTime.now(), privacy: _selectedPrivacy, targetAmount: 100, supporterIds: newSupporterIds, supporterStatuses: newSupporterStatuses, description: _descriptionController.text); 
                  }
                  
                  final user = AuthService().currentUser;
                  
                  if (user != null && createdGoal != null) {
                    await DatabaseService(userId: user.uid).saveGoal(createdGoal);
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context, createdGoal); 
                  }
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