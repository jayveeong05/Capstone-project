// profile_page.dart
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
  final TextEditingController _currentPasswordController = TextEditingController(); // New
  final TextEditingController _newPasswordController = TextEditingController(); // New
  final TextEditingController _confirmNewPasswordController = TextEditingController(); // New


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
    _currentPasswordController.dispose(); // New
    _newPasswordController.dispose(); // New
    _confirmNewPasswordController.dispose(); // New
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

  // New function to show password reset dialog
  Future<void> _showResetPasswordDialog() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current Password'),
                ),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                TextField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm New Password'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Reset Password'),
              onPressed: () {
                _resetPassword();
              },
            ),
          ],
        );
      },
    );
  }

  // New function to handle password reset logic
  Future<void> _resetPassword() async {
    if (_userId == null || _userId!.isEmpty) {
      _showSnackBar('User not logged in or user ID is missing.', Colors.red);
      return;
    }

    // --- ADDED MODIFICATION HERE ---
    // Ensure the user ID is formatted with 'U' and padded to 3 digits
    String formattedUserId = _userId!;
    if (!formattedUserId.startsWith('U')) {
      int? userIdInt = int.tryParse(formattedUserId);
      if (userIdInt != null) {
        formattedUserId = 'U${userIdInt.toString().padLeft(3, '0')}';
      } else {
        print('Warning: _userId could not be parsed as an integer for formatting: $_userId');
        _showSnackBar('User ID is in an unexpected format. Cannot reset password.', Colors.red);
        return;
      }
    }
    // --- END ADDED MODIFICATION ---

    final String currentPassword = _currentPasswordController.text;
    final String newPassword = _newPasswordController.text;
    final String confirmNewPassword = _confirmNewPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty) {
      _showSnackBar('All password fields are required.', Colors.red);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('New password must be at least 6 characters long.', Colors.red);
      return;
    }

    if (newPassword != confirmNewPassword) {
      _showSnackBar('New password and confirm password do not match.', Colors.red);
      return;
    }

    // UPDATED URL: Pointing to the new backend endpoint for profile password reset
    final url = Uri.parse('http://10.0.2.2:5000/api/profile/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': formattedUserId, // Use the formattedUserId here
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar('Password reset successfully!', Colors.green);
        Navigator.of(context).pop(); // Close the dialog
      } else {
        _showSnackBar('Failed to reset password: ${responseData['error']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', Colors.red);
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
                      const SizedBox(height: 24),
                      // Reset Password Button
                      ElevatedButton(
                        onPressed: _showResetPasswordDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Reset Password',
                          style: TextStyle(color: _cardColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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
                      _buildEditableField('Your Fitness Goals', _fitnessGoalsController, hint: 'Lose weight, Gain muscle, etc.', maxLines: 2),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Feedback Section
                  _buildSection(
                    title: "Feedback",
                    icon: Icons.feedback_outlined,
                    children: [
                      _buildFeedbackCategoryDropdown(),
                      const SizedBox(height: 16),
                      _buildFeedbackTextField(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Submit Feedback',
                          style: TextStyle(color: _cardColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Save Button
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: _saveProfileData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(color: _cardColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: _primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, size: 60, color: _primaryColor),
        ),
        const SizedBox(height: 16),
        Text(
          _usernameController.text,
          style: TextStyle(
            color: _textColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryColor, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
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
            color: _isEditing ? Colors.grey[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? _primaryColor.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controller,
              enabled: _isEditing,
              maxLines: maxLines,
              style: TextStyle(color: _textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
            color: _isEditing ? Colors.grey[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? _primaryColor.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _locationController,
              enabled: false, // Location is picked via dialog
              style: TextStyle(color: _textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Select your location',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                suffixIcon: _isEditing ? Icon(Icons.arrow_drop_down, color: _primaryColor) : null,
              ),
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
          'Feedback Category',
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedFeedbackCategory,
                hint: Text(
                  'Select a category',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFeedbackCategory = newValue;
                  });
                },
                items: <String>['General', 'Bug Report', 'Feature Request', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
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
