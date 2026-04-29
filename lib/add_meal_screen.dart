import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'meal.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;

class AddMealScreen extends StatefulWidget {
  final Meal? existingMeal;

  const AddMealScreen({super.key, this.existingMeal});

  @override
  State<AddMealScreen> createState() => _AddMealscreenState();
}

class _AddMealscreenState extends State<AddMealScreen> {
  late TextEditingController nameController;

  late TextEditingController descController = TextEditingController();

  final imageController = TextEditingController();
  String _selectedCategory = mealCategories[1]; // Default to 'Meat'

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    nameController = TextEditingController(
      text: widget.existingMeal?.name ?? '',
    );
    descController = TextEditingController(
      text: widget.existingMeal?.description ?? '',
    );
    if (widget.existingMeal?.imagePath != null) {
      _selectedImage = File(widget.existingMeal!.imagePath!);
    }
    _selectedCategory =
        widget.existingMeal?.category ?? 'Meat'; // Default to 'Meat'
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600, // Optimize image size for performance
    );

    if (pickedFile != null) {
      final appDir = await syspaths.getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');
      setState(() {
        _selectedImage = savedImage;
        // _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingMeal == null ? 'Add Meal' : 'Edit Meal'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  labelText: 'Meal Name*',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showPickerOptions(context),
                    // onPressed: () => _showPickerOptions(context),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: _selectedImage != null
                            ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showPickerOptions(context),
                    icon: Icon(Icons.add_a_photo),
                    label: Text("Add Meal Photo"),
                  ),
                ],
              ),
              SizedBox(height: 15),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedCategory,

                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: mealCategories.where((c) => c != 'All').map((
                    String category,
                    ) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  String name = nameController.text;
                  final updatedMeal = Meal(
                    id: widget.existingMeal?.id ?? DateTime.now().toString(),
                    name: name[0].toUpperCase() + name.substring(1),
                    category: _selectedCategory,
                    description: descController.text,
                    imagePath: _selectedImage != null
                        ? _selectedImage!.path
                        : null,
                    ingredients: widget.existingMeal?.ingredients,
                    instructions: widget.existingMeal?.instructions,
                    scheduledDate: widget.existingMeal?.scheduledDate,
                    slot: widget.existingMeal?.slot,
                    isTemplate: widget.existingMeal?.isTemplate ?? true,
                    nutrition: widget.existingMeal?.nutrition,
                  );
                  Navigator.pop(context, updatedMeal);
                },
                child: Text(
                  widget.existingMeal == null ? 'Add Meal' : 'Save Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () {
                  _pickImage(
                    ImageSource.gallery,
                  ); // Call the picker with Gallery
                  Navigator.of(context).pop(); // Close the menu
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera); // Call the picker with Camera
                  Navigator.of(context).pop(); // Close the menu
                },
              ),
            ],
          ),
        );
      },
    );
  }
}