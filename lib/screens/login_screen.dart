import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      // Success! Send them to the main app
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      setState(() {
        _errorMessage = "Login failed. Check your email and password.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or App Name
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 16),
              const Text(
                "Make It Happen",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 40),

              // Error Message Display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),

               // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true, // Hides the password dots
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Loading Spinner or Buttons
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Log In", style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // FORGOT PASSWORD BUTTON
                TextButton(
                  onPressed: () {
                    // Show a quick popup asking for their email
                    showDialog(
                      context: context,
                      builder: (context) {
                        final resetEmailController = TextEditingController();
                        return AlertDialog(
                          title: const Text("Reset Password"),
                          content: TextField(
                            controller: resetEmailController,
                            decoration: const InputDecoration(hintText: "Enter your email"),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final email = resetEmailController.text.trim();
                                if (email.isNotEmpty) {
                                  await _authService.sendPasswordResetEmail(email);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Reset email sent to $email")),
                                    );
                                  }
                                }
                              },
                              child: const Text("Send Email"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.grey)),
                ),
                
                // Sign Up Navigation Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}