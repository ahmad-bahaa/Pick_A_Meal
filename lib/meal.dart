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

  const Meal({
    required this.id,
    required this.name,
    this.imagePath,
    this.description,
    this.category = 'Other',
    this.ingredients,
    this.instructions,
  });

  Meal copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? description,
    String? category,
    List<String>? ingredients,
    String? instructions,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
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
    );
  }
}
