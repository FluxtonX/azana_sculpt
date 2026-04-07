import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/program_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Chats ---
  Stream<List<MessageModel>> getChatMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<int> getUnreadMessagesCountStream(String userId) {
    StreamController<int>? controller;
    Map<String, int> clientCounts = {};
    List<StreamSubscription> subs = [];
    StreamSubscription? clientsSub;

    void updateSum() {
      if (controller != null && !controller.isClosed) {
        final total = clientCounts.values.fold(0, (sum, count) => sum + count);
        controller.add(total);
      }
    }

    controller = StreamController<int>(
      onListen: () {
        clientsSub = getCoachClientsStream(userId).listen((clients) {
          // Cancel old subs
          for (var sub in subs) {
            sub.cancel();
          }
          subs.clear();
          clientCounts.clear();

          if (clients.isEmpty) {
            updateSum();
            return;
          }

          // Initial state: all clients start at 0
          for (var client in clients) {
            clientCounts[client.uid] = 0;
          }

          // Set up new subs for each client
          for (var client in clients) {
            final chatId = '${client.uid}_$userId';
            final sub = getChatUnreadCountStream(chatId, userId).listen((count) {
              clientCounts[client.uid] = count;
              updateSum();
            });
            subs.add(sub);
          }
        });
      },
      onCancel: () {
        clientsSub?.cancel();
        for (var sub in subs) {
          sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<int> getChatUnreadCountStream(String chatId, String userId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final querySnapshot = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in querySnapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Create or Update User Profile
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  // Stream of User Profile
  Stream<UserModel?> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // --- Programs ---

  // Create Program
  Future<void> createProgram(ProgramModel program) async {
    try {
      await _db.collection('programs').doc(program.id).set(program.toMap());
    } catch (e) {
      debugPrint('Error creating program: $e');
      rethrow;
    }
  }

  // Get Programs Stream for a Coach
  Stream<List<ProgramModel>> getProgramsStream(String coachId) {
    return _db
        .collection('programs')
        .where('coachId', isEqualTo: coachId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProgramModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Delete Program
  Future<void> deleteProgram(String programId) async {
    try {
      await _db.collection('programs').doc(programId).delete();
    } catch (e) {
      debugPrint('Error deleting program: $e');
      rethrow;
    }
  }

  // --- Clients ---

  // Get User by Email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      rethrow;
    }
  }

  // Assign Coach to Client
  Future<void> assignCoachToClient(String clientId, String coachId) async {
    try {
      await _db.collection('users').doc(clientId).update({
        'coachId': coachId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error assigning coach to client: $e');
      rethrow;
    }
  }

  // Get Clients Stream for a Coach
  Stream<List<UserModel>> getCoachClientsStream(String coachId) {
    return _db
        .collection('users')
        .where('coachId', isEqualTo: coachId)
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }
}
