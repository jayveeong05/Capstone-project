import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/pages/MealScanHistoryScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/meal_scanner_service.dart'; // Adjust the import path as necessary

class MealScannerScreen extends StatefulWidget {
  final String userId;
  const MealScannerScreen({super.key, required this.userId});

  @override
  State<MealScannerScreen> createState() => _MealScannerScreenState();
}

class _MealScannerScreenState extends State<MealScannerScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _scanResult;
  bool _isLogging = false;
  final MealScannerService _mealScannerService = MealScannerService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _scanResult = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);

    final uri = Uri.parse('http://10.0.2.2:5000/api/scan-meal'); // Use your backend URL
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = widget.userId
      ..files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    setState(() => _isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _scanResult = json.decode(respStr);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${json.decode(respStr)['error'] ?? respStr}')),
      );
    }
  }

  Future<void> _showLogMealDialog() async {
    if (_scanResult == null) return;

    final selectedMealType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Log Meal As'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Breakfast'),
              child: const Text('Breakfast'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Lunch'),
              child: const Text('Lunch'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Dinner'),
              child: const Text('Dinner'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Snack'),
              child: const Text('Snack'),
            ),
          ],
        );
      },
    );

    if (selectedMealType != null) {
      // If a meal type was selected, proceed to log it
      _logMeal(selectedMealType);
    }
  }

  Future<void> _logMeal(String mealType) async {
    if (_scanResult == null) return;

    setState(() => _isLogging = true);

    final uri = Uri.parse('http://10.0.2.2:5000/api/log-meal');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'meal_name': _scanResult!['food_name'],
          'calories': _scanResult!['calories'],
          'meal_type': mealType,
          'notes': 'Logged via Meal Scanner',
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_scanResult!['food_name']} logged as $mealType successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log meal: ${responseBody['error'] ?? 'Unknown server error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while logging: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLogging = false);
    }
  }

  Future<void> _selectAlternative(String alternativeFoodName) async {
    if (_scanResult == null || _scanResult!['meal_scan_id'] == null) return;

    setState(() {
      _isLoading = true;
      // Optimistically update the food name in UI
      _scanResult!['food_name'] = alternativeFoodName;
    });

    try {
      final updatedScanResult = await _mealScannerService.updateMealScanWithFoodName(
        _scanResult!['meal_scan_id'],
        alternativeFoodName,
      );

      if (updatedScanResult.success) {
        setState(() {
          _scanResult = updatedScanResult.toJson(); // Update _scanResult with full new data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated to "$alternativeFoodName"')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update meal: ${updatedScanResult.error ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating meal: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndDeleteScan() async {
    if (_scanResult == null || _scanResult!['meal_scan_id'] == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Scan?'),
          content: const Text('Are you sure you want to delete this meal scan? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await _mealScannerService.deleteMealScan(_scanResult!['meal_scan_id']);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal scan deleted.')),
          );
          setState(() {
            _scanResult = null;
            _selectedImage = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete meal scan.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting meal scan: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildNutrientRow(Map nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.bubble_chart, color: Colors.orange, size: 18),
          SizedBox(width: 6),
          Text('Carbs: ${nutrients['carbs'] ?? '-'} g'),
        ]),
        Row(children: [
          Icon(Icons.fitness_center, color: Colors.green, size: 18),
          SizedBox(width: 6),
          Text('Protein: ${nutrients['protein'] ?? '-'} g'),
        ]),
        Row(children: [
          Icon(Icons.opacity, color: Colors.pink, size: 18),
          SizedBox(width: 6),
          Text('Fat: ${nutrients['fat'] ?? '-'} g'),
        ]),
        Row(children: [
          Icon(Icons.grass, color: Colors.teal, size: 18),
          SizedBox(width: 6),
          Text('Fiber: ${nutrients['fiber'] ?? '-'} g'),
        ]),
        Row(children: [
          Icon(Icons.cake, color: Colors.purple, size: 18),
          SizedBox(width: 6),
          Text('Sugar: ${nutrients['sugar'] ?? '-'} g'),
        ]),
        Row(children: [
          Icon(Icons.spa, color: Colors.blue, size: 18),
          SizedBox(width: 6),
          Text('Sodium: ${nutrients['sodium'] ?? '-'} mg'),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Scanner'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fastfood, size: 60, color: Colors.blue[100]),
                              const SizedBox(height: 8),
                              Text(
                                "No image selected",
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Image'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload & Scan'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[900],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: _isLoading ? null : _uploadImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View Scan History'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealScanHistoryScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (_scanResult != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        margin: const EdgeInsets.only(top: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.restaurant_menu, color: Colors.blue[700], size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    _scanResult!['food_name']?.toString().toUpperCase() ?? '',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              if (_scanResult!['confidence'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Confidence: ${_scanResult!['confidence'].toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_scanResult!['calories']} kcal',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nutrients:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              _buildNutrientRow(_scanResult!['nutrients']),
                              const SizedBox(height: 12),
                              if (_scanResult!['alternatives'] != null && _scanResult!['alternatives'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Other possibilities:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: List<Widget>.from(
                                        (_scanResult!['alternatives'] as List)
                                            .map((alt) => ActionChip(
                                                  label: Text(alt),
                                                  onPressed: () => _selectAlternative(alt),
                                                )),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              if (_isLogging)
                                const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ))
                              else
                                Center(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.post_add),
                                    label: const Text('Log This Meal'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    ),
                                    onPressed: _showLogMealDialog,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Delete Scan', style: TextStyle(color: Colors.red)),
                                  onPressed: _confirmAndDeleteScan,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_scanResult!['image_path'] != null)
                                Text(
                                  'Image saved at: ${_scanResult!['image_path']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
