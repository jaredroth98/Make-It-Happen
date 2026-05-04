import 'package:flutter/material.dart';
import '../models/partner.dart'; // Imports the myNetwork list

class AccountabilityScreen extends StatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  State<AccountabilityScreen> createState() => _AccountabilityScreenState();
}

class _AccountabilityScreenState extends State<AccountabilityScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. The Tab Controller manages the swipe-to-switch logic
    return DefaultTabController(
      length: 2,
      // 2. We use a nested Scaffold so we can keep your FloatingActionButton, 
      // but we REMOVE the AppBar so we don't get a double header!
      child: Scaffold(
        body: Column(
          children: [
            // 3. The Tab Bar (The buttons at the top)
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'My Partners'),
                Tab(icon: Icon(Icons.assignment_turned_in), text: 'Supporting'),
              ],
            ),
            
            // 4. The Tab Views (The actual screens)
            Expanded(
              child: TabBarView(
                children: [
                  _buildMyPartnersTab(),
                  _buildSupportingGoalsTab(),
                ],
              ),
            ),
          ],
        ),
        
        // Your FAB stays exactly as you had it!
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print("Add new partner!");
            // TODO: Open an 'Add Partner' form
          },
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  // --- SUB-TAB 1: MY PARTNERS (Your exact code!) ---
  Widget _buildMyPartnersTab() {
    if (myNetwork.isEmpty) {
      return const Center(child: Text("You haven't added any supporters yet."));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: myNetwork.length,
      itemBuilder: (context, index) {
        final partner = myNetwork[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(partner.firstName[0].toUpperCase()), 
            ),
            title: Text(partner.firstName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(partner.email),
            trailing: partner.isVerified
                ? const Icon(Icons.verified, color: Colors.green)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Pending",
                      style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
            onTap: () {
              print("Clicked on ${partner.firstName}");
            },
          ),
        );
      },
    );
  }

  // --- SUB-TAB 2: GOALS I'M SUPPORTING (Placeholder) ---
  Widget _buildSupportingGoalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: const Icon(Icons.flag, color: Colors.blueGrey, size: 32),
            title: const Text('Run a Half Marathon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Goal Owner: Alex Chen', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('2 out of 5 checkpoints completed', style: TextStyle(color: Colors.grey)),
              ],
            ),
            onTap: () {
              // Later: Open a read-only version of the GoalDetailsScreen
            },
          ),
        ),
      ],
    );
  }
}