import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 16),
          const Text(
            "Account Settings",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Display the email of the currently logged-in user
          Text(
            "Logged in as: ${currentUser?.email ?? 'Unknown User'}",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // The Sign Out Button
          SizedBox(
            width: 200,
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
                // 1. Tell Firebase to terminate the session
                await authService.signOut();
                
                // 2. Kick the user back to the Login Screen
                if (context.mounted) {
                  // We use pushAndRemoveUntil to completely destroy the navigation history.
                  // This prevents the user from hitting the "Back" arrow to bypass the login screen!
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
  }
}