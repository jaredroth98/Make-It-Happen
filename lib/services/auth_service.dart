import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Sign Up (Create a brand new account)
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }

  // 2. Log In (For existing users)
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      print("Error logging in: $e");
      return null;
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. Helper to check if someone is currently logged in
  User? get currentUser => _auth.currentUser;
}