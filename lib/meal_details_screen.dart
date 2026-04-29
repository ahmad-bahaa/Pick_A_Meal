import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinedecide/add_meal_screen.dart';
import 'package:dinedecide/meal.dart';
import 'package:dinedecide/gemini_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MealDetailsScreen extends StatefulWidget {
  final Meal meal;

  const MealDetailsScreen({super.key, required this.meal});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  late Meal _currentMeal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentMeal = widget.meal;
  }

  Future<void> _updateLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealString = prefs.getString('user_meals');
    if (mealString != null) {
      final List<dynamic> decodedData = jsonDecode(mealString);
      final List<Meal> meals = decodedData.map((e) => Meal.fromMap(e)).toList();
      
      if (_currentMeal.isTemplate) {
        // Update template and ALL its scheduled instances
        for (int i = 0; i < meals.length; i++) {
          if (meals[i].id == _currentMeal.id) {
             meals[i] = _currentMeal;
          } else if (!meals[i].isTemplate && meals[i].id.startsWith("${_currentMeal.id}_")) {
             // Keep the scheduled info but update the meal details
             meals[i] = _currentMeal.copyWith(
               id: meals[i].id,
               isTemplate: false,
               scheduledDate: meals[i].scheduledDate,
               slot: meals[i].slot,
             );
          }
        }
      } else {
        // Update only this specific instance
        final index = meals.indexWhere((m) => m.id == _currentMeal.id);
        if (index != -1) {
          meals[index] = _currentMeal;
        }
      }
      
      await prefs.setString('user_meals', jsonEncode(meals.map((m) => m.toMap()).toList()));
    }
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<String?> _showApiKeyDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("API Key Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                children: [
                  const TextSpan(text: "To use AI features, please provide your Gemini API key. You can get one for free at "),
                  TextSpan(
                    text: "Google AI Studio",
                    style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()..onTap = _launchUrl,
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "API Key",
                border: OutlineInputBorder(),
                hintText: "Enter your Gemini API key",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('gemini_api_key');

    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await _showApiKeyDialog();
      if (apiKey == null || apiKey.isEmpty) return;
      await prefs.setString('gemini_api_key', apiKey);
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = GeminiService();
      final data = await service.generateRecipe(_currentMeal.name);
      
      if (data != null && mounted) {
        final List<String> newIngredients = List<String>.from(data['ingredients'] ?? []);
        final String newInstructions = data['instructions']?.toString() ?? "";
        
        setState(() {
          _currentMeal = _currentMeal.copyWith(
            ingredients: newIngredients,
            instructions: newInstructions,
          );
        });
        
        await _updateLocalStorage();
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Failed to generate a recipe or search returned no results.')),
         );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error generating recipe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Meal"),
        content: Text(_currentMeal.isTemplate 
          ? "Are you sure you want to remove this meal from your library? (Scheduled plans will also be removed)"
          : "Are you sure you want to remove this meal from your plan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'delete');
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool needsRecipe = _currentMeal.ingredients == null || _currentMeal.ingredients!.isEmpty;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        Navigator.pop(context, _currentMeal);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentMeal.name),
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _currentMeal),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final updatedMeal = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMealScreen(existingMeal: _currentMeal),
                  ),
                );
  
                if (updatedMeal != null && updatedMeal is Meal) {
                  setState(() {
                    _currentMeal = updatedMeal;
                  });
                  await _updateLocalStorage();
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
              Center(
                child: Hero(
                  tag: _currentMeal.id,
                  child: _currentMeal.imagePath != null
                      ? Image.file(
                          File(_currentMeal.imagePath!),
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 200,
                          width: 200,
                          child: Icon(Icons.restaurant, size: 200),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_currentMeal.isTemplate) ...[
                       Container(
                         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.secondaryContainer,
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text(
                           "Scheduled for: ${_currentMeal.slot} on ${_currentMeal.scheduledDate?.toLocal().toString().split(' ')[0]}",
                           style: TextStyle(fontWeight: FontWeight.bold),
                         ),
                       ),
                       SizedBox(height: 16),
                    ],
                    Text(
                      _currentMeal.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      "Category",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _currentMeal.category.isNotEmpty == true
                          ? _currentMeal.category
                          : "No Category",
                      style: TextStyle(fontSize: 16,),
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
                      _currentMeal.description?.isNotEmpty == true
                          ? _currentMeal.description!
                          : "No description provided for this meal.",
                      style: TextStyle(fontSize: 16,),
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    
                    if (!needsRecipe) ...[
                      SizedBox(height: 10),
                      Text(
                        "Ingredients",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                      SizedBox(height: 8),
                      ..._currentMeal.ingredients!.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 12),
                            Expanded(child: Text(item, style: TextStyle(fontSize: 16))),
                          ],
                        ),
                      )).toList(),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Text(
                        "Instructions",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _currentMeal.instructions ?? "No instructions available.",
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                      SizedBox(height: 20),
                    ],

                    if (needsRecipe)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.5, end: 1.0),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.auto_awesome),
                                        label: const Text("Generate Recipe with AI"),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: _generateRecipe,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
