import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dinedecide/meal.dart';
import 'package:dinedecide/meal_details_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Meal> _allMeals = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealString = prefs.getString('user_meals');
    if (mealString != null) {
      final List<dynamic> decodedData = jsonDecode(mealString);
      setState(() {
        _allMeals = decodedData.map((item) => Meal.fromMap(item)).toList();
      });
    }
  }

  Future<void> _saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _allMeals.map((meal) => meal.toMap()).toList(),
    );
    await prefs.setString('user_meals', encodedData);
  }

  List<Meal> _getMealsForDay(DateTime day) {
    final meals = _allMeals.where((meal) {
      return !meal.isTemplate && meal.scheduledDate != null && isSameDay(meal.scheduledDate, day);
    }).toList();

    const slotOrder = {'Breakfast': 0, 'Lunch': 1, 'Dinner': 2};
    meals.sort((a, b) {
      final orderA = slotOrder[a.slot] ?? 99;
      final orderB = slotOrder[b.slot] ?? 99;
      return orderA.compareTo(orderB);
    });

    return meals;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Color _getSlotColor(String? slot) {
    switch (slot) {
      case 'Breakfast':
        return Colors.orange.shade100;
      case 'Lunch':
        return Colors.green.shade100;
      case 'Dinner':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _addMealToPlan() async {
    if (_selectedDay == null) return;

    final libraryMeals = _allMeals.where((m) => m.isTemplate).toList();

    if (libraryMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No meals in library. Add some first!")),
      );
      return;
    }

    final Meal? selectedMeal = await showDialog<Meal>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select from Library"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: libraryMeals.length,
            itemBuilder: (context, index) {
              final meal = libraryMeals[index];
              return ListTile(
                leading: meal.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(meal.imagePath!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.restaurant),
                title: Text(meal.name),
                onTap: () => Navigator.pop(context, meal),
              );
            },
          ),
        ),
      ),
    );

    if (selectedMeal == null) return;

    final String? selectedSlot = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Slot"),
        children: ['Breakfast', 'Lunch', 'Dinner']
            .map((slot) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, slot),
                  child: Text(slot),
                ))
            .toList(),
      ),
    );

    if (selectedSlot == null) return;

    // Create a scheduled instance of the template meal
    final plannedMeal = selectedMeal.copyWith(
      id: "${selectedMeal.id}_${DateTime.now().millisecondsSinceEpoch}", 
      scheduledDate: _selectedDay,
      slot: selectedSlot,
      isTemplate: false, // Mark it as a scheduled instance, not a library template
    );

    setState(() {
      _allMeals.add(plannedMeal);
    });
    await _saveMeals();
  }

  @override
  Widget build(BuildContext context) {
    final mealsForSelectedDay = _getMealsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Planner"),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            eventLoader: _getMealsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: mealsForSelectedDay.isEmpty
                ? const Center(child: Text("No meals planned for this day."))
                : ListView.builder(
                    itemCount: mealsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final meal = mealsForSelectedDay[index];
                      final Color cardColor = _getSlotColor(meal.slot);
                      final bool isDark = Theme.of(context).brightness == Brightness.dark;

                      return Card(
                        color: isDark ? Color.alphaBlend(Colors.black54, cardColor) : cardColor,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              meal.slot?[0] ?? '?', 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            meal.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(meal.slot ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              setState(() {
                                _allMeals.removeWhere((m) => m.id == meal.id);
                              });
                              await _saveMeals();
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MealDetailsScreen(meal: meal),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMealToPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
