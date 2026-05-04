import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- NEW: Generate a random 6-character alphanumeric code ---
  String _generatePartnerCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  // --- NEW: Check if a username is already taken ---
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    return query.docs.isEmpty;
  }

  // --- UPGRADED: Sign Up (Now includes Username and Profile Generation) ---
  Future<UserCredential?> signUpWithEmail(String email, String password, String username) async {
    try {
      // 1. Double check username availability right before creating the account
      bool available = await isUsernameAvailable(username);
      if (!available) {
        throw Exception('Username is already taken.');
      }

      // 2. Create the Auth account (The Bouncer)
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );

      // 3. Generate a completely unique Partner Code
      String newCode = _generatePartnerCode();
      bool isCodeUnique = false;
      while (!isCodeUnique) {
        final codeQuery = await _db.collection('users').where('partnerCode', isEqualTo: newCode).get();
        if (codeQuery.docs.isEmpty) {
          isCodeUnique = true;
        } else {
          newCode = _generatePartnerCode(); // Try again if by some miracle it exists
        }
      }

      // 4. Create the User Profile in Firestore (The Vault)
      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email.toLowerCase(),
          'username': username.toLowerCase(), // Save as lowercase for easier searching later
          'displayName': username, // Save the original casing for the UI
          'partnerCode': newCode,
          'createdAt': Timestamp.now(),
        });
      }

      return credential;
    } catch (e) {
      print("Error signing up: $e");
      // We re-throw the error so the UI can catch it and show a popup to the user!
      throw e; 
    }
  }

  // 2. Log In (Unchanged)
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

  // 3. Sign Out (Unchanged)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. Helper to check if someone is currently logged in (Unchanged)
  User? get currentUser => _auth.currentUser;

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error sending password reset: $e");
      throw e;
    }
  }
}