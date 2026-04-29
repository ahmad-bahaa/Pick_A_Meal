import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dinedecide/meal.dart';
import 'package:dinedecide/add_meal_screen.dart';
import 'package:dinedecide/settings_screen.dart';
import 'package:dinedecide/meal_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dinedecide/meal_details_screen.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 1));
    FlutterNativeSplash.remove();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  void _updateTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DineDecide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: MealListScreen(onThemeChanged: _updateTheme),
    );
  }
}

class MealListScreen extends StatefulWidget {
  const MealListScreen({super.key, required this.onThemeChanged});

  final Function(ThemeMode) onThemeChanged;

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  final List<Meal> _meals = [];
  String _filterCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    _checkSearchResults();
  }

  void _checkSearchResults() {
    try {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) return;

      final results = _meals.where((meal) {
        // Only search in library (template) meals
        if (!meal.isTemplate) return false;
        
        final matchesCategory =
            _filterCategory == 'All' || meal.category == _filterCategory;
        final matchesSearch =
            meal.name.toLowerCase().contains(query) ||
            meal.category.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();

      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found for your search.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _addMeal(Meal meal) {
    setState(() {
      // Ensure added meals are marked as templates
      _meals.add(meal.copyWith(isTemplate: true));
      _saveToStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Meal> filteredMeals = [];
    try {
      final query = _searchController.text.toLowerCase();
      filteredMeals = _meals.where((meal) {
        // Main screen only shows templates (the library)
        if (!meal.isTemplate) return false;

        final matchesCategory =
            _filterCategory == 'All' || meal.category == _filterCategory;
        final matchesSearch =
            query.isEmpty ||
            meal.name.toLowerCase().contains(query) ||
            meal.category.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    } catch (e) {
      filteredMeals = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? TextField(
                  key: const ValueKey('searchField'),
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search library...',
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                )
              : const Text('DineDecide', key: ValueKey('title')),
        ),
        centerTitle: true,
        leading: _isSearching
            ? BackButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen(onThemeChanged: widget.onThemeChanged),
                    ),
                  );
                },
              ),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MealPlannerScreen()),
                );
                _loadFromStorage();
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.casino),
              onPressed: _meals.where((m) => m.isTemplate).isEmpty 
                  ? null 
                  : () => _pickRandomMeal(context),
            ),
          ]
        ],
      ),
      body: _meals.where((m) => m.isTemplate).isEmpty
          ? const Center(
              child: Text(
                'No meals in library yet!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: filteredMeals.isEmpty
                        ? const Center(child: Text("No meals found in this category"))
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredMeals.length,
                            itemBuilder: (ctx, index) {
                              final meal = filteredMeals[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MealDetailsScreen(meal: meal),
                                      ),
                                    );

                                    if (!mounted) return;

                                    if (result == 'delete') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("${meal.name} deleted"),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      _deleteMeal(meal.id);
                                    } else if (result is Meal) {
                                      _updateMeal(result);
                                    }
                                  },
                                  leading: Hero(
                                    tag: meal.id,
                                    child: meal.imagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(meal.imagePath!),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.restaurant, size: 40),
                                  ),
                                  title: Text(
                                    meal.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    meal.description ?? 'No description',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteMeal(String id) {
    setState(() {
      // Deleting a template should probably delete all its scheduled instances too?
      // Or we can just delete the template. Let's delete the template only for now.
      _meals.removeWhere((m) => m.id == id);
    });
    _saveToStorage();
  }

  void _showAddMealScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMealScreen()),
    );

    if (!mounted) return;

    if (result != null && result is Meal) {
      _addMeal(result);
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _meals.map((meal) => meal.toMap()).toList(),
    );
    await prefs.setString('user_meals', encodedData);
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? mealString = prefs.getString('user_meals');

      if (mealString != null) {
        final List<dynamic> decodedData = jsonDecode(mealString);
        setState(() {
          _meals.clear();
          _meals.addAll(decodedData.map((item) => Meal.fromMap(item)).toList());
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load meals: $e')),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    final libraryMeals = _meals.where((m) => m.isTemplate).toList();
    if (libraryMeals.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add some meals first!")),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final randomMeal = libraryMeals[Random().nextInt(libraryMeals.length)];
    _showResultDialog(context, randomMeal);
  }

  void _pickRandomMeal(BuildContext context) async {
    final libraryMeals = _meals.where((m) => m.isTemplate).toList();
    if (libraryMeals.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text(
                  "Choosing your next meal...",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    Navigator.pop(context);

    final randomMeal = libraryMeals[Random().nextInt(libraryMeals.length)];
    _showResultDialog(context, randomMeal);
  }

  void _showResultDialog(BuildContext context, Meal meal) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedValue),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: meal.imagePath != null
                        ? Image.file(
                            File(meal.imagePath!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 100,
                            color: Colors.green[100],
                            child: const Icon(Icons.restaurant, size: 50),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "How about this?",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Maybe later"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealDetailsScreen(meal: meal),
                      ),
                    );
                  },
                  child: const Text("View Details"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateMeal(Meal updatedMeal) {
    final index = _meals.indexWhere((m) => m.id == updatedMeal.id);
    if (index != -1) {
      setState(() {
        _meals[index] = updatedMeal;
      });
      _saveToStorage();
    }
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: mealCategories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              label: Text(category),
              selected: _filterCategory == category,
              onSelected: (selected) {
                setState(() {
                  _filterCategory = selected ? category : "All";
                });
                _checkSearchResults();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
