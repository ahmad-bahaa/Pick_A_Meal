class Meal {
  final String id;
  final String name;
  final String? imagePath;
  final String? description;

  Meal({
    required this.id,
    required this.name,
    this.imagePath,
    this.description,
  });

  // Convert Meal object to Map (to save)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'description': description,
    };
  }
  // Create Meal object from Map (to load)
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      description: map['description'],
    );
  }
}