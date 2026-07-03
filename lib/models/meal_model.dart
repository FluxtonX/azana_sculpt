class MealModel {
  final String id;
  final String title;
  final String type; // Breakfast, Lunch, etc.
  final String time;
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final List<String> ingredients;
  final List<String> instructions;
  final String prepTime;
  final String? imageUrl;

  MealModel({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'time': time,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'imageUrl': imageUrl,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      time: map['time'] ?? '',
      calories: map['calories'] ?? '0',
      protein: map['protein'] ?? '0',
      carbs: map['carbs'] ?? '0',
      fat: map['fat'] ?? '0',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      prepTime: map['prepTime'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}

class DailyMealPlan {
  final String day;
  final String targetCalories;
  final String targetProtein;
  final String targetCarbs;
  final String targetFat;
  final List<MealModel> meals;

  DailyMealPlan({
    required this.day,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.meals,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'meals': meals.map((m) => m.toMap()).toList(),
    };
  }

  factory DailyMealPlan.fromMap(Map<String, dynamic> map) {
    return DailyMealPlan(
      day: map['day'] ?? '',
      targetCalories: map['targetCalories'] ?? '0',
      targetProtein: map['targetProtein'] ?? '0',
      targetCarbs: map['targetCarbs'] ?? '0',
      targetFat: map['targetFat'] ?? '0',
      meals: (map['meals'] as List? ?? [])
          .map((m) => MealModel.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MealPlanPdf {
  final String fileName;
  final String downloadUrl;
  final String storagePath;
  final String uploadedAt;

  const MealPlanPdf({
    required this.fileName,
    required this.downloadUrl,
    required this.storagePath,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'uploadedAt': uploadedAt,
    };
  }

  factory MealPlanPdf.fromMap(Map<String, dynamic> map) {
    return MealPlanPdf(
      fileName: map['fileName'] ?? 'Meal Plan.pdf',
      downloadUrl: map['downloadUrl'] ?? '',
      storagePath: map['storagePath'] ?? '',
      uploadedAt: map['uploadedAt'] ?? '',
    );
  }
}
