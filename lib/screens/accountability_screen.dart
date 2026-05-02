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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Supporters'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      
      // If the network is empty, show a friendly message. Otherwise, build the list.
      body: myNetwork.isEmpty
          ? const Center(child: Text("You haven't added any supporters yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: myNetwork.length,
              itemBuilder: (context, index) {
                final partner = myNetwork[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    // Circle avatar using the first letter of their first name
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(partner.firstName[0].toUpperCase()), 
                    ),
                    
                    title: Text(partner.firstName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(partner.email),
                    
                    // NEW: Dynamic trailing widget based on Verification Status!
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
                      // TODO: Open an edit dialog or screen
                    },
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Add new partner!");
          // TODO: Open an 'Add Partner' form
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}