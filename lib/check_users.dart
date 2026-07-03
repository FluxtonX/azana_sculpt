import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  print('Total Users: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    final data = doc.data();
    print('User: ${data['email']} | Role: ${data['role']} | CoachId: ${data['coachId']}');
  }
}
