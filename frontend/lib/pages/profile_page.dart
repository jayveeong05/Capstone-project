import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _foodPreferencesController = TextEditingController();
  final TextEditingController _fitnessGoalsController = TextEditingController();
  final TextEditingController _medicalConditionsController = TextEditingController();
  final TextEditingController _feedbackTextController = TextEditingController(); // New feedback controller

  String? _selectedFeedbackCategory; // New for feedback category
  String? _userId; // To store the logged-in user's ID

  bool _isLoading = true;
  bool _isEditing = false;


  // Modern color scheme
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2D3748);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _allergiesController.dispose();
    _foodPreferencesController.dispose();
    _fitnessGoalsController.dispose();
    _medicalConditionsController.dispose();
    _feedbackTextController.dispose(); // Dispose feedback controller
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    print('Loading profile data...'); // Debug print
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Safely load all values, converting to string if necessary
      // This handles cases where any preference might have been
      // accidentally stored as a different type (e.g., int, bool).
      var getSafeString = (String key) {
        var value = prefs.get(key);
        return value != null ? value.toString() : '';
      };

      var rawUserId = prefs.get('user_id');
      _userId = rawUserId != null ? rawUserId.toString() : null;
      print('Loaded _userId: $_userId'); // Debug print: Check the loaded user ID

      _usernameController.text = getSafeString('username') ?? 'User';

      _heightController.text = (prefs.getDouble('height')?.toString() ?? '');
      _weightController.text = (prefs.getDouble('weight')?.toString() ?? '');
      _ageController.text = (prefs.getInt('age')?.toString() ?? '');

      _locationController.text = getSafeString('location');
      _allergiesController.text = getSafeString('allergies');
      _foodPreferencesController.text = getSafeString('foodPreferences');
      _fitnessGoalsController.text = getSafeString('fitnessGoals');
      _medicalConditionsController.text = getSafeString('medicalConditions');
      _isLoading = false;
      print('Profile data loaded. _isLoading set to false.'); // Debug print
    });
  }

  Future<void> _saveProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    
    // Save numerical values as their correct types
    await prefs.setDouble('height', double.tryParse(_heightController.text) ?? 0.0);
    await prefs.setDouble('weight', double.tryParse(_weightController.text) ?? 0.0);
    await prefs.setInt('age', int.tryParse(_ageController.text) ?? 0);

    await prefs.setString('location', _locationController.text);
    await prefs.setString('allergies', _allergiesController.text);
    await prefs.setString('foodPreferences', _foodPreferencesController.text);
    await prefs.setString('fitnessGoals', _fitnessGoalsController.text);
    await prefs.setString('medicalConditions', _medicalConditionsController.text);

    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_userId == null || _userId!.isEmpty) { // Added check for empty userId
      _showSnackBar('User not logged in or user ID is missing.', Colors.red);
      print('Feedback submission failed: _userId is null or empty.'); // Debug print
      return;
    }
    if (_feedbackTextController.text.isEmpty) {
      _showSnackBar('Feedback text cannot be empty.', Colors.red);
      return;
    }
    if (_selectedFeedbackCategory == null) {
      _showSnackBar('Please select a feedback category.', Colors.red);
      return;
    }

    // --- MODIFICATION STARTS HERE ---
    // Ensure the user ID is formatted with 'U' and padded to 3 digits
    String formattedUserId = _userId!;
    if (!formattedUserId.startsWith('U')) {
      // Attempt to parse the numeric part and format it
      int? userIdInt = int.tryParse(formattedUserId);
      if (userIdInt != null) {
        formattedUserId = 'U${userIdInt.toString().padLeft(3, '0')}';
      } else {
        // Fallback if parsing fails, or handle as an error
        print('Warning: _userId could not be parsed as an integer for formatting: $_userId');
        // You might want to show an error to the user or stop submission here
        _showSnackBar('User ID is in an unexpected format. Cannot submit feedback.', Colors.red);
        return;
      }
    }
    // --- MODIFICATION ENDS HERE ---

    final url = Uri.parse('http://10.0.2.2:5000/api/feedback'); // REMINDER: Replace with your actual backend URL
    print('Submitting feedback with user_id: $formattedUserId, category: $_selectedFeedbackCategory, text: ${_feedbackTextController.text}'); // Debug print: Check data being sent
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': formattedUserId, // Use the formattedUserId here
          'category': _selectedFeedbackCategory,
          'feedback_text': _feedbackTextController.text,
        }),
      );

      if (response.statusCode == 201) {
        _showSnackBar('Feedback submitted successfully!', Colors.green);
        _feedbackTextController.clear();
        setState(() {
          _selectedFeedbackCategory = null;
        });
        print('Feedback submitted successfully. Response: ${response.body}'); // Debug print
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('Failed to submit feedback: ${errorData['error']}', Colors.red);
        print('Feedback submission failed. Status: ${response.statusCode}, Error: ${errorData['error']}'); // Debug print
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', Colors.red);
      print('Caught exception during feedback submission: $e'); // Debug print
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  void _openLocationPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Location'),
        children: [
          _buildLocationOption(Icons.location_on, 'Current Location'),
          _buildLocationOption(Icons.search, 'Search on Map'),
          _buildLocationOption(Icons.home, 'Home Address'),
          _buildLocationOption(Icons.work, 'Work Address'),
        ],
      ),
    );

    if (result != null) {
      setState(() => _locationController.text = result);
    }
  }

  ListTile _buildLocationOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _primaryColor),
      title: Text(title),
      onTap: () => Navigator.pop(context, title)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: _primaryColor),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header with Avatar
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  
                  // Personal Info Section
                  _buildSection(
                    title: "Personal Information",
                    icon: Icons.person_outline,
                    children: [
                      _buildEditableField('Username', _usernameController),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildEditableField('Height (cm)', _heightController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildEditableField('Weight (kg)', _weightController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildEditableField('Age', _ageController)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isEditing ? _openLocationPicker : null,
                              child: _buildLocationField(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Health Section
                  _buildSection(
                    title: "Dietary & Health Details",
                    icon: Icons.health_and_safety_outlined,
                    children: [
                      _buildEditableField('Allergies', _allergiesController, hint: 'Peanuts, Dairy, etc.'),
                      const SizedBox(height: 16),
                      _buildEditableField('Food Preferences', _foodPreferencesController, hint: 'Vegetarian, Keto, etc.'),
                      const SizedBox(height: 16),
                      _buildEditableField('Medical Conditions', _medicalConditionsController, hint: 'Diabetes, Hypertension, etc.', maxLines: 2),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Fitness Goals Section
                  _buildSection(
                    title: "Fitness Goals",
                    icon: Icons.fitness_center_outlined,
                    children: [
                      _buildEditableField('Goals', _fitnessGoalsController, hint: 'Lose 5kg, Build muscle, etc.', maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Feedback Section
                  _buildSection(
                    title: "Send Feedback",
                    icon: Icons.feedback_outlined,
                    children: [
                      _buildFeedbackCategoryDropdown(),
                      const SizedBox(height: 16),
                      _buildFeedbackTextField(),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _submitFeedback,
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text('SUBMIT FEEDBACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  if (_isEditing) ...[
                    ElevatedButton(
                      onPressed: _saveProfileData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: _primaryColor.withOpacity(0.3),
                      ),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/images/user_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 50,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Container(
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: _cardColor, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: () {
                    // Add image picker functionality here
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _usernameController.text,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (_locationController.text.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _locationController.text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24), // Add margin bottom for spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? Colors.grey[50] : _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? _primaryColor.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              enabled: _isEditing,
              maxLines: maxLines,
              style: TextStyle(color: _textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                suffixIcon: _isEditing
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () => controller.clear(),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Special location field with interactive icon
  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? Colors.grey[50] : _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? _primaryColor.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    enabled: _isEditing,
                    style: TextStyle(color: _textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'City, Country',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.location_on, color: _primaryColor),
                    onPressed: _openLocationPicker,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // New Widget for Feedback Category Dropdown
  Widget _buildFeedbackCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryColor.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedFeedbackCategory,
              hint: Text('Select a category', style: TextStyle(color: Colors.grey[400])),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              style: TextStyle(color: _textColor, fontSize: 16),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFeedbackCategory = newValue;
                });
              },
              items: <String>['Bug Report', 'Feature Request', 'General Feedback', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // New Widget for Feedback Text Field
  Widget _buildFeedbackTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Feedback',
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _feedbackTextController,
              maxLines: 5,
              style: TextStyle(color: _textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Type your feedback here...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}