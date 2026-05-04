import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<DocumentSnapshot>(
      // 1. We listen directly to this user's specific profile document in the Vault!
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Extract the data safely
        Map<String, dynamic>? userData = snapshot.data?.data() as Map<String, dynamic>?;
        
        // If we found data, grab it. Otherwise, provide fallbacks.
        String username = userData?['displayName'] ?? "Unknown User";
        String partnerCode = userData?['partnerCode'] ?? "No Code";

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 16),
              
              // Display the real Username!
              Text(
                username,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                currentUser.email ?? "No Email",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 24),

              // THE PARTNER CODE DISPLAY
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text("Your Partner Code", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 4),
                    Text(
                      partnerCode, // Show the 6-digit code!
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // RESET PASSWORD BUTTON
              SizedBox(
                width: 250,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Send Password Reset", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (currentUser.email != null) {
                      await authService.sendPasswordResetEmail(currentUser.email!);
                      if (context.mounted) {
                        // Show a nice little popup confirmation at the bottom of the screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Reset email sent to ${currentUser.email}")),
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // SIGN OUT BUTTON
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Sign Out", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false, 
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}