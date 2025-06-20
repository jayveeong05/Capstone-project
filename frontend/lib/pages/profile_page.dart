import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _locationController = TextEditingController(); // New location controller
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _foodPreferencesController = TextEditingController();
  final TextEditingController _fitnessGoalsController = TextEditingController();
  final TextEditingController _medicalConditionsController = TextEditingController();

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
    _locationController.dispose(); // Dispose location controller
    _allergiesController.dispose();
    _foodPreferencesController.dispose();
    _fitnessGoalsController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('username') ?? 'User';
      _heightController.text = prefs.getString('height') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
      _ageController.text = prefs.getString('age') ?? '';
      _locationController.text = prefs.getString('location') ?? ''; // Load location
      _allergiesController.text = prefs.getString('allergies') ?? '';
      _foodPreferencesController.text = prefs.getString('foodPreferences') ?? '';
      _fitnessGoalsController.text = prefs.getString('fitnessGoals') ?? '';
      _medicalConditionsController.text = prefs.getString('medicalConditions') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('age', _ageController.text);
    await prefs.setString('location', _locationController.text); // Save location
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

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  void _openLocationPicker() async {
    // In a real app, you would integrate with a map API or location service
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
      onTap: () => Navigator.pop(context, title),
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
                              child: _buildLocationField(), // Special location field
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
}