class ExerciseModel {
  final String id;
  final String name;
  final String instruction;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? videoUrl;
  final String? thumbnailUrl;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.instruction,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.videoUrl,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'instruction': instruction,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      instruction: map['instruction'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? '',
      restSeconds: map['restSeconds'] ?? 0,
      videoUrl: map['videoUrl'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }
}

class WorkoutSession {
  final String id;
  final String programId;
  final String title;
  final List<ExerciseModel> exercises;
  final String totalDuration;
  final int caloriesBurned;
  final int orderIndex;

  WorkoutSession({
    required this.id,
    required this.programId,
    required this.title,
    required this.exercises,
    required this.totalDuration,
    required this.caloriesBurned,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'title': title,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'totalDuration': totalDuration,
      'caloriesBurned': caloriesBurned,
      'orderIndex': orderIndex,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] ?? '',
      programId: map['programId'] ?? '',
      title: map['title'] ?? '',
      exercises: (map['exercises'] as List?)
              ?.map((e) => ExerciseModel.fromMap(e))
              .toList() ??
          [],
      totalDuration: map['totalDuration'] ?? '',
      caloriesBurned: map['caloriesBurned'] ?? 0,
      orderIndex: map['orderIndex'] ?? 0,
    );
  }
}
