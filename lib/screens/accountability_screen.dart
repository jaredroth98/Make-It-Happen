import 'package:flutter/material.dart';
import '../models/partner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/add_partner_dialog.dart';

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
      // 2. We use a nested Scaffold so we can keep the FloatingActionButton
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
            showDialog(
              context: context, 
              builder: (context) => const AddPartnerDialog(),
            );
          },
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  // --- SUB-TAB 1: MY PARTNERS (Your exact code!) ---
  Widget _buildMyPartnersTab() {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return const Center(child: Text("Please log in."));

    return StreamBuilder<QuerySnapshot>(
      // Listen to the live relationship pipeline!
      stream: DatabaseService(userId: currentUserId).partners,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading partners."));
        }

        final partnerDocs = snapshot.data?.docs ?? [];

        if (partnerDocs.isEmpty) {
          return const Center(child: Text("You haven't added any supporters yet."));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: partnerDocs.length,
          itemBuilder: (context, index) {
            final partnerData = partnerDocs[index].data() as Map<String, dynamic>;
            
            final name = partnerData['displayName'] ?? 'Unknown';
            final email = partnerData['email'] ?? '';
            final status = partnerData['status']; // 'accepted', 'pending_sent', or 'pending_received'

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(name[0].toUpperCase()), 
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                
                // Dynamically build the trailing widget based on the live stream status
                trailing: _buildStatusWidget(status),
                
                onTap: () {
                  // We will wire up accepting requests here later!
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget to keep the UI clean
  Widget _buildStatusWidget(String status) {
    if (status == 'accepted') {
      return const Icon(Icons.verified, color: Colors.green);
    } else if (status == 'pending_sent') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text("Pending", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else if (status == 'pending_received') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text("Action Required", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
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