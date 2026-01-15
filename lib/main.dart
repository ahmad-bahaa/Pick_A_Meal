import 'dart:convert';
import 'dart:io';

import 'package:eating/Meal.dart';
import 'package:eating/AddMealScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meal_details_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MealListScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

class MealListScreen extends StatefulWidget {
  const MealListScreen({super.key, required this.title});

  final String title;

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  final List<Meal> _meals = [];

  void _addMeal(Meal meal) {
    setState(() {
      _meals.add(meal);
      _saveToStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Meals'), centerTitle: true),
      body: _meals.isEmpty
          ? Center(
              child: Text(
                'No meals added yet!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (ctx, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MealDetailsScreen(meal: _meals[index]),
                        ),
                      );
                    },
                    leading: Hero(
                      tag: _meals[index].id,
                      child: _meals[index].imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_meals[index].imagePath!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.fastfood, size: 40),
                    ),
                    title: Text(
                      _meals[index].name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _meals[index].description ?? 'No description',
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealScreen(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddMealScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMealscreen()),
    );

    if (result != null && result is Meal) {
      _addMeal(result);
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert List<Meal> to List of Maps, then to a JSON String
    final String encodedData = jsonEncode(
      _meals.map((meal) => meal.toMap()).toList(),
    );
    await prefs.setString('user_meals', encodedData);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealString = prefs.getString('user_meals');

    if (mealString != null) {
      final List<dynamic> decodedData = jsonDecode(mealString);
      setState(() {
        _meals.clear();
        _meals.addAll(decodedData.map((item) => Meal.fromMap(item)).toList());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
  }
}
