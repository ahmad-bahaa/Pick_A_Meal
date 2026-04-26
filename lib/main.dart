import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dinedecide/meal.dart';
import 'package:dinedecide/add_meal_screen.dart';
import 'package:dinedecide/settings_screen.dart';
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
  void initState() {super.initState();
  _loadTheme();
  _initApp(); // Add this
  }

  Future<void> _initApp() async {
    // Wait for loading or just yield
    await Future.delayed(const Duration(seconds: 1));
    FlutterNativeSplash.remove(); // Remove the splash screen
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  void _addMeal(Meal meal) {
    setState(() {
      _meals.add(meal);
      _saveToStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Meal> filteredMeals = [];
    try {
      final query = _searchController.text.toLowerCase();
      filteredMeals = _meals.where((meal) {
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
                    hintText: 'Search meals...',
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
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.casino), // Dice icon for randomness
            onPressed: _meals.isEmpty ? null : () => _pickRandomMeal(context),
          ),
        ],
      ),
      body: _meals.isEmpty
          ? Center(
              child: Text(
                'No meals added yet!',
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
                        ? Center(child: Text("No meals found in this category"))
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            // Ensures the pull works even for short lists
                            itemCount: filteredMeals.length,
                            itemBuilder: (ctx, index) {
                              final meal = filteredMeals[index];
                              return Card(
                                margin: EdgeInsets.symmetric(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("${meal.name} deleted"),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      _deleteMeal(meal.id);
                                    } else if (result is Meal) {
                                      _updateMeal(
                                        result,
                                      ); // Call the update function
                                    }
                                  },
                                  leading: Hero(
                                    tag: meal.id,
                                    child: meal.imagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              File(meal.imagePath!),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Icon(Icons.restaurant, size: 40),
                                  ),
                                  title: Text(
                                    meal.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
        child: Icon(Icons.add),
      ),
    );
  }

  void _deleteMeal(String id) {
    setState(() {
      _meals.removeWhere((m) => m.id == id);
    });
    _saveToStorage(); // Update local storage so it stays deleted
  }

  void _showAddMealScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMealScreen()),
    );

    if (!mounted) return;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load meals: $e')));
      }
    }
  }

  Future<void> _handleRefresh() async {
    // 1. Check if we actually have meals
    if (_meals.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Add some meals first!")));
      return;
    }

    // 2. Simulate "picking" time (the spinner will stay visible during this)
    await Future.delayed(Duration(milliseconds: 1200));

    if (!mounted) return;

    // 3. Pick the random meal
    final randomMeal = _meals[Random().nextInt(_meals.length)];

    // 4. Show the result dialog
    // We don't need to 'await' this so the refresh spinner can disappear immediately
    _showResultDialog(context, randomMeal);
  }

  void _pickRandomMeal(BuildContext context) async {
    // 1. Show a "Picking..." visual
    showDialog(
      context: context,
      barrierDismissible: false, // User can't click away while "picking"
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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

    // 2. Wait for a moment to simulate "thinking"
    await Future.delayed(Duration(milliseconds: 1500));

    if (!mounted) return;

    // 3. Close the "Picking" dialog
    Navigator.pop(context);

    // 4. Select a random meal
    final randomMeal = _meals[Random().nextInt(_meals.length)];

    // 5. Show the Result Dialog
    _showResultDialog(context, randomMeal);
  }

  void _showResultDialog(BuildContext context, Meal meal) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      // Tap background to close
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      // Standard dimmed background
      transitionDuration: const Duration(milliseconds: 400),
      // A snappy 0.4s animation
      // pageBuilder is required but not used here because we use transitionBuilder
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        // Create a "bouncy" curve for the pop effect
        final curvedValue = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );

        // Combine Fade and Scale for a smooth entrance
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedValue),
          // Grow from 50% to 100% size
          child: FadeTransition(
            opacity: anim1, // Fade in from transparent to opaque
            // This is the actual dialog content from before
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Header
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
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
                            child: Icon(Icons.restaurant, size: 50),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "How about this?",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 5),
                        Text(
                          meal.name,
                          style: TextStyle(
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
                  child: Text("Maybe later"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    // Navigate to Details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealDetailsScreen(meal: meal),
                      ),
                    );
                  },
                  child: Text("View Details"),
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

  // Create a helper function to build the filter bar
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
