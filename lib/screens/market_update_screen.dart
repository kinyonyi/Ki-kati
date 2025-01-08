import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ki_kati/components/custom_button.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/components/textfield_component.dart';

class MarketUpdateScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic>? initialData;

  const MarketUpdateScreen({super.key, required this.itemId, this.initialData});

  @override
  State<MarketUpdateScreen> createState() => _MarketUpdateScreenState();
}

class _MarketUpdateScreenState extends State<MarketUpdateScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  bool _isLoading = false;

  // Text editing controllers
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController categoryController;
  late TextEditingController locationCityController;
  late TextEditingController locationRegionController;
  late TextEditingController quantityController;
  List<File> filesSelected = [];

  // Error messages
  String? _titleError;
  String? _descriptionError;
  String? _priceError;
  String? _categoryError;
  String? _locationCityError;
  String? _locationRegionError;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    titleController =
        TextEditingController(text: widget.initialData?['title'] ?? '');
    descriptionController =
        TextEditingController(text: widget.initialData?['description'] ?? '');
    priceController = TextEditingController(
        text: widget.initialData?['price']?.toString() ?? '');
    categoryController =
        TextEditingController(text: widget.initialData?['category'] ?? '');
    quantityController = TextEditingController(
        text: widget.initialData?['quantity']?.toString() ?? '');
    locationCityController = TextEditingController(
        text: widget.initialData?['location']['city'] ?? '');
    locationRegionController = TextEditingController(
        text: widget.initialData?['location']['region'] ?? '');
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

  // File picker
  Future<void> pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      List<File> selectedFiles =
          result.files.map((file) => File(file.path!)).toList();
      setState(() {
        filesSelected = selectedFiles;
      });

      String fileNames = result.files.map((e) => e.name).join(', ');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Picked files: $fileNames")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No file was picked")));
    }
  }

  // Update item
  void updateItem() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await httpService.put('/market/${widget.itemId}', {
        'title': titleController.text,
        'description': descriptionController.text,
        'price': priceController.text,
        'category': categoryController.text,
        'quantity': quantityController.text,
        'location[city]': locationCityController.text,
        'location[region]': locationRegionController.text,
        //'media': filesSelected,
      });

      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
        Navigator.pop(context); // Return to the previous screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update item')),
      );
    } finally {
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
        title: const Text('Update Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
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
              suffixIcon: const Icon(Icons.category, color: Color(0xFFBDBDBD)),
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
                const SizedBox(width: 10),
                Expanded(
                  child: TextFieldComponent(
                    controller: locationRegionController,
                    hintText: 'Location (region)',
                    obscureText: false,
                    suffixIcon:
                        const Icon(Icons.area_chart, color: Color(0xFFBDBDBD)),
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
                  for (var file in filesSelected)
                    Row(
                      children: [
                        if (file.path.toLowerCase().endsWith('.jpg') ||
                            file.path.toLowerCase().endsWith('.png') ||
                            file.path.toLowerCase().endsWith('.jpeg'))
                          Image.file(file,
                              width: 50, height: 50, fit: BoxFit.cover),
                        const SizedBox(width: 8),
                        Text(file.path.split('/').last),
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
                ],
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.image, color: Colors.blue),
              label: const Text('Select Files To Upload',
                  style: TextStyle(color: Colors.blue)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.blue, width: 1),
                ),
                backgroundColor: Colors.white,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            CustomButton(
              onTap: _isLoading ? null : updateItem,
              buttonText: _isLoading ? "Updating item..." : "Update Item",
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
