const List<String> mealCategories = [
  'All',
  'Meat',
  'Fish',
  'Chicken',
  'Other',
  'Fruit',
  'Snack',
  'Dessert',
];

class Nutrition {
  final int calories;
  final String protein;
  final String carbs;
  final String fats;

  const Nutrition({
    this.calories = 0,
    this.protein = '0g',
    this.carbs = '0g',
    this.fats = '0g',
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  factory Nutrition.fromMap(Map<String, dynamic> map) {
    return Nutrition(
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: map['protein']?.toString() ?? '0g',
      carbs: map['carbs']?.toString() ?? '0g',
      fats: map['fats']?.toString() ?? '0g',
    );
  }

  Nutrition copyWith({
    int? calories,
    String? protein,
    String? carbs,
    String? fats,
  }) {
    return Nutrition(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }
}

class Meal {
  final String id;
  final String name;
  final String? imagePath;
  final String? description;
  final String category;
  final List<String>? ingredients;
  final String? instructions;
  final DateTime? scheduledDate;
  final String? slot; // e.g., 'Breakfast', 'Lunch', 'Dinner'
  final bool isTemplate; // true if it's in the main library, false if it's a scheduled instance
  final Nutrition? nutrition;

  const Meal({
    required this.id,
    required this.name,
    this.imagePath,
    this.description,
    this.category = 'Other',
    this.ingredients,
    this.instructions,
    this.scheduledDate,
    this.slot,
    this.isTemplate = true,
    this.nutrition,
  });

  Meal copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? description,
    String? category,
    List<String>? ingredients,
    String? instructions,
    DateTime? scheduledDate,
    String? slot,
    bool? isTemplate,
    Nutrition? nutrition,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      slot: slot ?? this.slot,
      isTemplate: isTemplate ?? this.isTemplate,
      nutrition: nutrition ?? this.nutrition,
    );
  }

  // Convert Meal object to Map (to save)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imagePath': imagePath,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'slot': slot,
      'isTemplate': isTemplate,
      'nutrition': nutrition?.toMap(),
    };
  }

  // Create Meal object from Map (to load)
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Other',
      imagePath: map['imagePath'] as String?,
      description: map['description'] as String? ?? 'No description',
      ingredients: map['ingredients'] != null
          ? List<String>.from(map['ingredients'] as List)
          : null,
      instructions: map['instructions'] as String?,
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'] as String)
          : null,
      slot: map['slot'] as String?,
      isTemplate: map['isTemplate'] as bool? ?? true,
      nutrition: map['nutrition'] != null
          ? Nutrition.fromMap(map['nutrition'] as Map<String, dynamic>)
          : null,
    );
  }
}
