import 'package:flutter/material.dart';
import 'dart:io';
import 'Meal.dart';

class MealDetailsScreen extends StatelessWidget {
  final Meal meal;

  MealDetailsScreen({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(meal.name)),
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
}
