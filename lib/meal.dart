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
    );
  }
}
