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

  Meal({
    required this.id,
    required this.name,
    this.imagePath,
    this.description,
    this.category = 'Other',
  });

  // Convert Meal object to Map (to save)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imagePath': imagePath,
      'description': description,
    };
  }

  // Create Meal object from Map (to load)
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      category: map['category'] ?? 'Other',
      imagePath: map['imagePath'],
      description: map['description'] ?? 'No description',
    );
  }
}
