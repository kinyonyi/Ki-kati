import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ki_kati/components/custom_button.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/textfield_component.dart';

class MarketCreateScreen extends StatefulWidget {
  const MarketCreateScreen({super.key});

  @override
  State<MarketCreateScreen> createState() => _MarketCreateScreenState();
}

class _MarketCreateScreenState extends State<MarketCreateScreen> {
  // Loading state
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  bool _isLoading = false;
  // Text editing controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final categoryController = TextEditingController();
  final locationCityController = TextEditingController();
  final locationRegionController = TextEditingController();
  final quantityController = TextEditingController();
  List<File> filesSelected = [];

  // Error messages
  String? _titleError;
  String? _descriptionError;
  String? _priceError;
  String? _categoryError;
  String? _locationCityError;
  String? _locationRegionError;
  String? _quantityError;

  void _clearFields() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    categoryController.clear();
    locationCityController.clear();
    locationRegionController.clear();
    quantityController.clear();
  }

  // Validate inputs
  bool _validateInputs() {
    _titleError = titleController.text.isEmpty ? 'Title cannot be empty' : null;
    _descriptionError = descriptionController.text.isEmpty
        ? 'Description cannot be empty'
        : null;
    _priceError = priceController.text.isEmpty ? 'Price cannot be empty' : null;
    _categoryError =
        categoryController.text.isEmpty ? 'Category cannot be empty' : null;
    _locationCityError = locationCityController.text.isEmpty
        ? 'Location City cannot be empty'
        : null;
    _locationRegionError = locationRegionController.text.isEmpty
        ? 'Location Region cannot be empty'
        : null;
    _quantityError =
        quantityController.text.isEmpty ? 'Quantity cannot be empty' : null;

    return _titleError == null &&
        _descriptionError == null &&
        _priceError == null &&
        _categoryError == null &&
        _locationCityError == null &&
        _locationRegionError == null &&
        _quantityError == null;
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      // List to store selected files
      List<File> selectedFiles = [];

      for (var file in result.files) {
        // Create a File object for each picked file
        selectedFiles.add(File(file.path!));
      }

      setState(() {
        filesSelected = selectedFiles;
      });

      // Showing a snack bar with file names
      String fileNames = result.files.map((e) => e.name).join(', ');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Picked files: $fileNames"),
      ));
    } else {
      // User canceled the picker
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No file was picked"),
      ));
    }
  }

  void createItem() async {
    setState(() {
      _isLoading = true;
    });

    if (!_validateInputs()) {
      setState(() {
        _isLoading = false; // Set loading to false
      });
      return;
    }
    try {
      final response = await httpService.postdio('/market/create', {
        'title': titleController.text,
        'price': priceController.text,
        'category': categoryController.text,
        'location[city]': locationCityController.text,
        'location[region]': locationRegionController.text,
        'media': filesSelected,
        'quantity': quantityController.text,
      });
      print(response);

      if (response['statusCode'] == 201) {
        setState(() {
          _isLoading = false;
          // Reset the input fields
        });
      }
    } catch (e) {
      print('Error: $e'); // Handle error
    } finally {
      //_clearFields();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
          title: const Text(
            'Create Item',
            style: TextStyle(fontSize: 20),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              TextFieldComponent(
                controller: titleController,
                hintText: 'Title',
                obscureText: false,
                suffixIcon: const Icon(Icons.title, color: Color(0xFFBDBDBD)),
                errorText: _titleError,
              ),
              const SizedBox(height: 10),
              TextFieldComponent(
                controller: descriptionController,
                hintText: 'Description',
                obscureText: false,
                maxLines: 5,
                suffixIcon: const Icon(Icons.details, color: Color(0xFFBDBDBD)),
                errorText: _descriptionError,
              ),
              const SizedBox(height: 10),
              TextFieldComponent(
                controller: priceController,
                hintText: 'Price',
                obscureText: false,
                suffixIcon: const Icon(Icons.money, color: Color(0xFFBDBDBD)),
                errorText: _priceError,
              ),
              const SizedBox(height: 10),
              TextFieldComponent(
                controller: categoryController,
                hintText: 'Category',
                obscureText: false,
                suffixIcon:
                    const Icon(Icons.category, color: Color(0xFFBDBDBD)),
                errorText: _categoryError,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFieldComponent(
                      controller: locationCityController,
                      hintText: 'Location (city)',
                      obscureText: false,
                      suffixIcon:
                          const Icon(Icons.pin_drop, color: Color(0xFFBDBDBD)),
                      errorText: _locationCityError,
                    ),
                  ),
                  const SizedBox(width: 10), // Space between the fields
                  Expanded(
                    child: TextFieldComponent(
                      controller: locationRegionController,
                      hintText: 'Location (region)',
                      obscureText: false,
                      suffixIcon: const Icon(Icons.area_chart,
                          color: Color(0xFFBDBDBD)),
                      errorText: _locationRegionError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFieldComponent(
                controller: quantityController,
                hintText: 'Quantity',
                obscureText: false,
                suffixIcon: const Icon(Icons.production_quantity_limits,
                    color: Color(0xFFBDBDBD)),
                errorText: _quantityError,
              ),
              const SizedBox(height: 10),
              if (filesSelected.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Files:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Check if selected files are images or other file types
                    for (var file in filesSelected)
                      if (file.path.toLowerCase().endsWith('.jpg') ||
                          file.path.toLowerCase().endsWith('.png') ||
                          file.path.toLowerCase().endsWith('.jpeg'))
                        // Display image files in a row
                        Row(
                          children: [
                            Image.file(
                              file,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  filesSelected.remove(file);
                                });
                              },
                            ),
                          ],
                        )
                      else
                        // Display other file names in a column
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Text(file.path
                                  .split('/')
                                  .last), // Display file name
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    filesSelected.remove(file);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: pickFile, // Open file picker on button press
                icon: const Icon(Icons.image, color: Colors.blue), // Image icon
                label: const Text(
                  'Select Files To Upload',
                  style: TextStyle(color: Colors.blue),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    side: const BorderSide(
                        color: Colors.blue, width: 1), // Border color
                  ),
                  backgroundColor: Colors.white, // Button background color
                  iconColor: Colors.blue, // Text and icon color
                ),
              ),
              const SizedBox(height: 10),
              CustomButton(
                onTap: _isLoading ? null : createItem,
                buttonText:
                    _isLoading ? "Creating account..." : "Create an account",
                isLoading: _isLoading,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ));
  }
}
