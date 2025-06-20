import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealScannerScreen extends StatefulWidget {
  final String userId;
  const MealScannerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MealScannerScreen> createState() => _MealScannerScreenState();
}

class _MealScannerScreenState extends State<MealScannerScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _scanResult;

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
      appBar: AppBar(title: const Text('Meal Scanner')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fastfood, size: 60, color: Colors.deepPurple[100]),
                              SizedBox(height: 8),
                              Text("No image selected", style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Image'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          backgroundColor: Colors.deepPurple[100],
                          foregroundColor: Colors.deepPurple[800],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          backgroundColor: Colors.deepPurple[200],
                          foregroundColor: Colors.deepPurple[900],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _uploadImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_scanResult != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        margin: const EdgeInsets.only(top: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.restaurant_menu, color: Colors.deepPurple, size: 28),
                                  SizedBox(width: 10),
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
                                  const Icon(Icons.local_fire_department, color: Colors.red),
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
                                            .map((alt) => Chip(label: Text(alt))),
                                      ),
                                    ),
                                  ],
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
