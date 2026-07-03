import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("Initializing Firebase...");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final String email = "Azana@Coach.com";
  final String password = "Azana1";
  
  print("Attempting to create coach account: $email");
  
  try {
    // 1. Create Auth User
    UserCredential cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("User already exists in Auth, updating role in Firestore...");
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          final signinCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          await _updateFirestore(signinCred.user!.uid, email);
        } else {
          await _updateFirestore(user.uid, email);
        }
        return;
      } else {
        rethrow;
      }
    }

    await _updateFirestore(cred.user!.uid, email);
    
    print("\n========================================");
    print("SUCCESS: Coach account created!");
    print("Email: $email");
    print("Password: $password");
    print("========================================\n");
    
  } catch (e) {
    print("\nERROR: Failed to create coach: $e");
  }
}

Future<void> _updateFirestore(String uid, String email) async {
  final user = UserModel(
    uid: uid,
    email: email,
    fullName: "Official Coach",
    role: "coach",
    isElite: true,
    isOnboardingComplete: true,
    createdAt: DateTime.now(),
  );
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .set(user.toMap(), SetOptions(merge: true));
      
  print("Firestore profile updated with 'coach' role.");
}
