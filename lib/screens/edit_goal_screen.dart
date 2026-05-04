import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/partner.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;
  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late TextEditingController _titleController;
  late PrivacyLevel _selectedPrivacy;
  List<AccountabilityPartner> _selectedPartners = [];

  bool _requireSequential = false;
  CheatDayStrategy _cheatStrategy = CheatDayStrategy.none;
  DateTime? _dailyEndDate; 
  
  // NEW: Objective Goal States
  DateTime? _objectiveTargetDate;
  final List<TextEditingController> _checkpointControllers = [];
  final List<DateTime?> _checkpointDeadlines = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _selectedPrivacy = widget.goal.privacy;
    _selectedPartners = widget.goal.assignedPartners.map((gp) => gp.partner).toList();

    if (widget.goal is DailyGoal) {
      _dailyEndDate = (widget.goal as DailyGoal).endDate;
    } else if (widget.goal is ObjectiveGoal) {
      final objGoal = widget.goal as ObjectiveGoal;
      _requireSequential = objGoal.requireSequentialCheckpoints;
      _objectiveTargetDate = objGoal.targetCompletionDate;
      
      // Load existing checkpoints and their deadlines
      for (var cp in objGoal.checkpoints) {
        _checkpointControllers.add(TextEditingController(text: cp.title));
        _checkpointDeadlines.add(cp.targetDate);
      }
    } else if (widget.goal is AvoidanceGoal) {
      _cheatStrategy = (widget.goal as AvoidanceGoal).cheatStrategy;
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
            TextField(controller: _titleController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),

            const Text("Privacy Level", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<PrivacyLevel>(
              value: _selectedPrivacy,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: PrivacyLevel.values.map((level) => DropdownMenuItem(value: level, child: Text(level.name[0].toUpperCase() + level.name.substring(1)))).toList(),
              onChanged: (newValue) => setState(() => _selectedPrivacy = newValue!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            /// --- 2. DYNAMIC SETTINGS ---
            if (widget.goal is DailyGoal) ...[
              const Text("Daily Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Set an End Date (Optional)"),
                subtitle: Text(_dailyEndDate == null ? "No end date set" : "${_dailyEndDate!.month}/${_dailyEndDate!.day}/${_dailyEndDate!.year}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _dailyEndDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _dailyEndDate = picked);
                },
              ),
              if (_dailyEndDate != null)
                TextButton(onPressed: () => setState(() => _dailyEndDate = null), child: const Text("Clear Date", style: TextStyle(color: Colors.red))),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            if (widget.goal is ObjectiveGoal) ...[
              const Text("Objective Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              
              // NEW: Edit Overall Deadline
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Overall Deadline (Optional)"),
                subtitle: Text(_objectiveTargetDate == null ? "No deadline set" : "${_objectiveTargetDate!.month}/${_objectiveTargetDate!.day}/${_objectiveTargetDate!.year}", style: const TextStyle(color: Colors.redAccent)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _objectiveTargetDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _objectiveTargetDate = picked);
                },
              ),
              if (_objectiveTargetDate != null)
                TextButton(onPressed: () => setState(() => _objectiveTargetDate = null), child: const Text("Clear Overall Deadline", style: TextStyle(color: Colors.red))),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Require sequential checkpoints?"),
                value: _requireSequential,
                onChanged: (bool value) => setState(() => _requireSequential = value),
              ),
              const SizedBox(height: 16),
              const Text("Checkpoints", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
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
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            if (widget.goal is AvoidanceGoal) ...[
              const Text("Avoidance Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CheatDayStrategy>(
                value: _cheatStrategy,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Cheat Day Strategy"),
                items: CheatDayStrategy.values.map((strategy) => DropdownMenuItem(value: strategy, child: Text(strategy.name))).toList(),
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
              spacing: 8.0, runSpacing: 4.0, 
              children: myNetwork.where((p) => p.isVerified).map((partner) {
                final isSelected = _selectedPartners.contains(partner);
                return FilterChip(
                  label: Text(partner.firstName),
                  selected: isSelected,
                  onSelected: (selected) => setState(() { selected ? _selectedPartners.add(partner) : _selectedPartners.remove(partner); }),
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
                  widget.goal.title = _titleController.text;
                  widget.goal.privacy = _selectedPrivacy;
                  widget.goal.assignedPartners = _selectedPartners.map((p) => GoalPartner(partner: p, hasAcceptedGoal: false)).toList();

                  if (widget.goal is DailyGoal) {
                    (widget.goal as DailyGoal).endDate = _dailyEndDate;
                  } else if (widget.goal is ObjectiveGoal) {
                    final objGoal = widget.goal as ObjectiveGoal;
                    objGoal.requireSequentialCheckpoints = _requireSequential;
                    
                    // NEW: Save the Overall Target Date
                    objGoal.targetCompletionDate = _objectiveTargetDate;
                    
                    List<Checkpoint> oldCheckpoints = objGoal.checkpoints;
                    objGoal.checkpoints = _checkpointControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      String newTitle = entry.value.text;
                      DateTime? newDeadline = _checkpointDeadlines[index]; // Grab the new deadline!
                      
                      if (index < oldCheckpoints.length) {
                        oldCheckpoints[index].title = newTitle;
                        oldCheckpoints[index].targetDate = newDeadline; // Update existing deadline
                        return oldCheckpoints[index];
                      } else {
                        return Checkpoint(title: newTitle, targetDate: newDeadline);
                      }
                    }).toList();
                  } else if (widget.goal is AvoidanceGoal) {
                    (widget.goal as AvoidanceGoal).cheatStrategy = _cheatStrategy;
                  }

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