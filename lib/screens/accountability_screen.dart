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
  // --- DIALOG HELPERS ---
  void _showActionDialog(BuildContext context, Map<String, dynamic> partnerData, bool alreadyRequested) {
    final name = partnerData['displayName'] ?? 'Unknown';
    final targetUid = partnerData['uid'];
    final status = partnerData['status'];

    showDialog(
      context: context,
      builder: (context) {
        
        // 1. INCOMING REQUEST
        if (status == 'pending_received') {
          return AlertDialog(
            title: const Text("Partner Request"),
            content: Text("Are you willing to be an Accountability Partner for $name?"), // Wording updated!
            actions: [
              TextButton(
                onPressed: () async {
                  await DatabaseService(userId: AuthService().currentUser!.uid).deletePartnerConnection(targetUid, isMySupporter: false);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Decline", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () async {
                  await DatabaseService(userId: AuthService().currentUser!.uid).acceptPartnerRequest(targetUid);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Accept"),
              ),
              // We dynamically hide the 3rd option if they are already on our list!
              if (!alreadyRequested) 
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final db = DatabaseService(userId: AuthService().currentUser!.uid);
                    await db.acceptPartnerRequest(targetUid);
                    await db.sendPartnerRequest(targetUid, partnerData);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text("Accept & Request $name"),
                ),
            ],
          );
        } 
        
        // 2. OUTGOING OR ACCEPTED
        else {
          final isAccepted = status == 'accepted';
          return AlertDialog(
            title: Text(isAccepted ? "Remove Partner?" : "Cancel Request?"),
            content: Text(isAccepted 
              ? "Are you sure you want to remove $name from your Accountability Partners?"
              : "Are you sure you want to cancel your Accountability Partner request to $name?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  await DatabaseService(userId: AuthService().currentUser!.uid).deletePartnerConnection(targetUid, isMySupporter: true);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isAccepted ? "Remove" : "Cancel Request"),
              ),
            ],
          );
        }
      },
    );
  }
  
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
  // --- SUB-TAB 1: MY PARTNERS ---
  Widget _buildMyPartnersTab() {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return const Center(child: Text("Please log in."));

    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService(userId: currentUserId).partners,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Error loading partners."));

        // FILTER: We hide the people you are 'supporting' from this tab!
        // This keeps the relationship strictly one-way visually.
        final visiblePartners = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] != 'supporting'; 
        }).toList() ?? [];

        if (visiblePartners.isEmpty) {
          return const Center(child: Text("You haven't added any supporters yet."));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: visiblePartners.length,
          itemBuilder: (context, index) {
            final partnerData = visiblePartners[index].data() as Map<String, dynamic>;
            
            final uid = partnerData['uid'];
            final name = partnerData['displayName'] ?? 'Unknown';
            final email = partnerData['email'] ?? '';
            final status = partnerData['status']; 

            // THE NEW CHECK: See if we already have a 'supporter' document for this person
            final alreadyRequested = visiblePartners.any((p) {
              final pData = p.data() as Map<String, dynamic>;
              return pData['uid'] == uid && (pData['status'] == 'accepted' || pData['status'] == 'pending_sent');
            });

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
                
                // Pass the new boolean here!
                trailing: _buildStatusWidget(context, status, partnerData, alreadyRequested),
                
                onTap: () {
                  if (status == 'pending_received') {
                    // Pass it here too!
                    _showActionDialog(context, partnerData, alreadyRequested);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- STATUS UI GENERATOR ---
  Widget _buildStatusWidget(BuildContext context, String status, Map<String, dynamic> partnerData, bool alreadyRequested) {
    if (status == 'accepted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.green),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showActionDialog(context, partnerData, alreadyRequested),
          ),
        ],
      );
    } else if (status == 'pending_sent') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Text("Pending", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showActionDialog(context, partnerData, alreadyRequested),
          ),
        ],
      );
    } else if (status == 'pending_received') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text("Action Needed", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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