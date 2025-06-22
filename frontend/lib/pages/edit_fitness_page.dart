import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'exercise_model.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AddOrEditExercisePage extends StatefulWidget {
  final Exercise? exercise;
  const AddOrEditExercisePage({Key? key, this.exercise}) : super(key: key);

  @override
  _AddOrEditExercisePageState createState() => _AddOrEditExercisePageState();
}

class _AddOrEditExercisePageState extends State<AddOrEditExercisePage> {
  final _formKey = GlobalKey<FormState>();
  File? _image0;
  File? _image1;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController instructionsController;

  String? _selectedLevel;
  String? _selectedMechanic;
  String? _selectedEquipment;
  String? _selectedCategory;
  List<String> _selectedPrimaryMuscles = [];

  final List<String> levels = ['beginner', 'intermediate', 'expert'];
  final List<String> mechanics = ['null', 'compound', 'isolation'];
  final List<String> equipments = [
    'null', 'medicine ball', 'dumbbell', 'body only', 'bands', 'kettlebells',
    'foam roll', 'cable', 'machine', 'barbell', 'exercise ball', 'e-z curl bar', 'other'
  ];
  final List<String> primaryMuscles = [
    "abdominals", "abductors", "adductors", "biceps", "calves", "chest", "forearms",
    "glutes", "hamstrings", "lats", "lower back", "middle back", "neck", "quadriceps",
    "shoulders", "traps", "triceps"
  ];
  final List<String> categories = [
    "powerlifting", "strength", "stretching", "cardio",
    "olympic weightlifting", "strongman", "plyometrics"
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    nameController = TextEditingController(text: ex?.name ?? '');
    instructionsController = TextEditingController(
        text: ex != null ? ex.instructions.join('. ') : '');

    _selectedLevel = ex?.level;
    _selectedMechanic = ex?.mechanic;
    _selectedEquipment = ex?.equipment;
    _selectedCategory = ex?.category;

    if (ex?.primaryMuscles != null) {
      _selectedPrimaryMuscles = ex!.primaryMuscles
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  Future<void> _pickImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (index == 0) _image0 = File(picked.path);
        if (index == 1) _image1 = File(picked.path);
      });
    }
  }

  String? _nullableText(String? text) =>
      text == null || text.trim().isEmpty ? null : text.trim();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final url = widget.exercise == null
        ? Uri.parse('http://10.0.2.2:5000/add-exercise')
        : Uri.parse('http://10.0.2.2:5000/update-exercise/${widget.exercise!.id}');

    final body = jsonEncode({
      'name': nameController.text.trim(),
      'level': _nullableText(_selectedLevel),
      'mechanic': _nullableText(_selectedMechanic),
      'equipment': _nullableText(_selectedEquipment),
      'primaryMuscles': _selectedPrimaryMuscles.join(','),
      'category': _nullableText(_selectedCategory),
      'instructions': instructionsController.text.trim(),
    });

    final headers = {'Content-Type': 'application/json'};
    final response = widget.exercise == null
        ? await http.post(url, headers: headers, body: body)
        : await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      final int exerciseId = widget.exercise?.id ?? resData['id'];
      await _uploadImages(exerciseId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.exercise == null ? 'Exercise added!' : 'Exercise updated!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save exercise')),
      );
    }
  }

  Future<void> _uploadImages(int exerciseId) async {
    if (_image0 == null || _image1 == null) return;

    final uri = Uri.parse('http://10.0.2.2:5000/upload-exercise-images/$exerciseId');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image0', _image0!.path));
    request.files.add(await http.MultipartFile.fromPath('image1', _image1!.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed')),
      );
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: options.map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.exercise != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Exercise' : 'Add Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, 'Name'),
              _buildDropdown('Level', _selectedLevel, levels, (val) => setState(() => _selectedLevel = val)),
              _buildDropdown('Mechanic', _selectedMechanic, mechanics, (val) => setState(() => _selectedMechanic = val)),
              _buildDropdown('Equipment', _selectedEquipment, equipments, (val) => setState(() => _selectedEquipment = val)),
              _buildDropdown('Category', _selectedCategory, categories, (val) => setState(() => _selectedCategory = val)),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MultiSelectDialogField<String>(
                  items: primaryMuscles.map((e) => MultiSelectItem(e, e)).toList(),
                  initialValue: _selectedPrimaryMuscles,
                  title: const Text("Primary Muscles"),
                  buttonText: const Text("Select Primary Muscles"),
                  listType: MultiSelectListType.CHIP,
                  onConfirm: (values) {
                    setState(() {
                      _selectedPrimaryMuscles = values;
                    });
                  },
                  validator: (values) =>
                      values == null || values.isEmpty ? 'Please select at least one muscle' : null,
                ),
              ),
              _buildTextField(instructionsController, 'Instructions (separated by periods)', maxLines: 5),
              const Text("Upload Exercise Images (0.png & 1.png)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(0),
                    icon: Icon(Icons.image),
                    label: Text('Pick 0.png'),
                  ),
                  const SizedBox(width: 10),
                  _image0 != null ? Image.file(_image0!, width: 60, height: 60) : Text("No image"),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(1),
                    icon: Icon(Icons.image),
                    label: Text('Pick 1.png'),
                  ),
                  const SizedBox(width: 10),
                  _image1 != null ? Image.file(_image1!, width: 60, height: 60) : Text("No image"),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}