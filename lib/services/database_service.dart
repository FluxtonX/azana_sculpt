import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/program_model.dart';
import '../models/message_model.dart';
import '../models/workout_models.dart';
import 'streak_service.dart';

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
      // Note: In a real app, you might want to delete sub-collections too, 
      // but Firestore doesn't do this automatically. For now, we delete the doc.
      await _db.collection('programs').doc(programId).delete();
    } catch (e) {
      debugPrint('Error deleting program: $e');
      rethrow;
    }
  }

  // --- Workouts & Exercises ---

  // Add Workout to Program
  Future<void> addWorkoutToProgram(String programId, WorkoutSession session) async {
    try {
      await _db
          .collection('programs')
          .doc(programId)
          .collection('workouts')
          .doc(session.id)
          .set(session.toMap());
    } catch (e) {
      debugPrint('Error adding workout: $e');
      rethrow;
    }
  }

  // Get Workouts Stream for a Program
  Stream<List<WorkoutSession>> getWorkoutsStream(String programId) {
    return _db
        .collection('programs')
        .doc(programId)
        .collection('workouts')
        .orderBy('orderIndex', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkoutSession.fromMap(doc.data()))
          .toList();
    });
  }

  // Get the first workout session for a program
  Stream<WorkoutSession?> getFirstWorkoutStream(String programId) {
    return _db
        .collection('programs')
        .doc(programId)
        .collection('workouts')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return WorkoutSession.fromMap(snapshot.docs.first.data());
      }
      return null;
    });
  }

  // Update Exercises in a Workout
  Future<void> updateWorkoutExercises(
      String programId, String workoutId, List<ExerciseModel> exercises) async {
    try {
      await _db
          .collection('programs')
          .doc(programId)
          .collection('workouts')
          .doc(workoutId)
          .update({
        'exercises': exercises.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error updating exercises: $e');
      rethrow;
    }
  }

  // Delete Workout from Program
  Future<void> deleteWorkout(String programId, String workoutId) async {
    try {
      await _db
          .collection('programs')
          .doc(programId)
          .collection('workouts')
          .doc(workoutId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting workout: $e');
      rethrow;
    }
  }

  // Get Stream for all programs (for clients)
  Stream<List<ProgramModel>> getAllProgramsStream({String? coachId}) {
    // Simplified query to avoid index errors during development
    Query query = _db.collection('programs');
    
    if (coachId != null && coachId.isNotEmpty) {
      query = query.where('coachId', isEqualTo: coachId);
    }
    
    return query
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProgramModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
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

  // --- Workout Progress & Completion ---

  // Mark a workout as complete
  Future<void> completeWorkout({
    required String userId,
    required String programId,
    required String workoutId,
    required String workoutTitle,
    required String duration,
    required int exercisesCount,
    required int calories,
  }) async {
    try {
      debugPrint('DEBUG: Attempting to complete workout: $workoutId in program: $programId');
      final completionId = '${userId}_${workoutId}_${DateTime.now().millisecondsSinceEpoch}';
      await _db.collection('completed_workouts').doc(completionId).set({
        'userId': userId,
        'programId': programId,
        'workoutId': workoutId,
        'workoutTitle': workoutTitle,
        'duration': duration,
        'exercisesCount': exercisesCount,
        'calories': calories,
        'completedAt': DateTime.now().toIso8601String(),
      });
      
      debugPrint('DEBUG: Workout completion saved successfully: $completionId');
      
      // Update user streak and last active date
      await StreakService().updateStreak(userId);
    } catch (e) {
      debugPrint('DEBUG: Error completing workout: $e');
      rethrow;
    }
  }

  // Get progress for a specific program
  Stream<double> getProgramProgressStream(String userId, String programId) {
    return _db
        .collection('completed_workouts')
        .where('userId', isEqualTo: userId)
        // Note: Filter by programId in Dart to avoid complex composite index requirement
        .snapshots()
        .asyncMap((completedSnapshot) async {
      // Filter by programId in memory
      final relevantCompletions = completedSnapshot.docs
          .where((doc) => doc.data()['programId'] == programId);

      // Get total workouts in this program
      final workoutsSnapshot = await _db
          .collection('programs')
          .doc(programId)
          .collection('workouts')
          .get();
      
      final totalWorkouts = workoutsSnapshot.docs.length;
      if (totalWorkouts == 0) return 0.0;

      // Count unique workouts completed for this specific program
      final completedWorkoutIds = relevantCompletions
          .map((doc) => doc.data()['workoutId'] as String)
          .toSet();
          
      return (completedWorkoutIds.length / totalWorkouts).clamp(0.0, 1.0);
    });
  }

  // Get recently completed workouts
  Stream<List<Map<String, dynamic>>> getLatestCompletedWorkoutsStream(String userId) {
    return _db
        .collection('completed_workouts')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Get stream of completed workout IDs for a program
  Stream<Set<String>> getCompletedWorkoutIdsStream(String userId, String programId) {
    return _db
        .collection('completed_workouts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Filter by programId in memory to avoid index issues
      return snapshot.docs
          .where((doc) => doc.data()['programId'] == programId)
          .map((doc) => doc.data()['workoutId'] as String)
          .toSet();
    });
  }

  // Get the NEXT available workout session in a program (the first one not completed)
  Stream<WorkoutSession?> getNextWorkoutStream(String userId, String programId) {
    // 1. Get all workouts in program order
    return getWorkoutsStream(programId).asyncMap((workouts) async {
      if (workouts.isEmpty) return null;

      // 2. Get completed workouts for this user
      final completedSnapshot = await _db
          .collection('completed_workouts')
          .where('userId', isEqualTo: userId)
          .get();

      // 3. Filter for this program in Dart
      final completedIds = completedSnapshot.docs
          .where((doc) => doc.data()['programId'] == programId)
          .map((doc) => doc.data()['workoutId'] as String)
          .toSet();

      // 4. Return the first workout whose ID is not in completedIds
      try {
        return workouts.firstWhere((w) => !completedIds.contains(w.id));
      } catch (_) {
        // All workouts completed!
        return workouts.last; // Or return null to signify program completion
      }
    });
  }

  // Get the ACTIVE program (first one with progress < 1.0)
  Stream<ProgramModel?> getActiveProgramStream(String userId, String? coachId) {
    if (coachId == null) return Stream.value(null);

    return getAllProgramsStream(coachId: coachId).asyncMap((programs) async {
      for (var program in programs) {
        // Check progress of each program
        final progress = await getProgramProgressStream(userId, program.id).first;
        if (progress < 1.0) {
          return program; // Found the active one!
        }
      }
      // If all are done, return the first one as a fallback or null
      return programs.isNotEmpty ? programs.first : null;
    });
  }
}
