import 'package:flutter/material.dart';
import 'dart:io';
import 'AddMealScreen.dart';
import 'Meal.dart';

class MealDetailsScreen extends StatelessWidget {
  final Meal meal;

  MealDetailsScreen({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              // 1. Open the Edit Screen
              final updatedMeal = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMealscreen(existingMeal: meal),
                ),
              );

              // 2. If the user actually saved changes (result is not null)
              if (updatedMeal != null && updatedMeal is Meal) {
                // 3. Close the detail screen and send the updated meal to the main list
                Navigator.pop(context, updatedMeal);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: meal.id,
              child: meal.imagePath != null
                  ? Image.file(
                      File(meal.imagePath!),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.fastfood),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),

                  Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    meal.description?.isNotEmpty == true
                        ? meal.description!
                        : "No description provided for this meal.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Confirmation Dialog
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Meal"),
        content: Text("Are you sure you want to remove this meal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(
                context,
                'delete',
              ); // Return 'delete' signal to main screen
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
