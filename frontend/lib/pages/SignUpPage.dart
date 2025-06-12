import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart'; // for baseUrl - ensure this path is correct for your project structure

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final PageController _pageController = PageController();

  String? _gender;
  double _weight = 60;
  double _height = 170;
  double _ageValue = 25;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _mainGoal; // Renamed for single main goal selection
  final TextEditingController _allergy = TextEditingController();

  String _responseMessage = '';
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _name.text,
          'password': _password.text,
          'email': _email.text,
          'role': '1', // Assuming '1' is the role for regular users
          'gender': _gender,
          'weight': _weight,
          'height': _height,
          'age': _ageValue.toInt().toString(), // Ensure age is sent as string if backend expects it
          'goal': _mainGoal, // Send the single selected main goal
          'allergy': _allergy.text.isEmpty ? null : _allergy.text, // Send null if empty
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        _responseMessage = data['message'] ?? data['error'] ?? 'An unknown error occurred.';
        _isLoading = false;
      });

      if (response.statusCode == 200 && data['message'] == 'User registered successfully') {
        // Delay for better UX before navigation
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        // Handle specific errors from the backend if needed
        print('Signup failed: ${data['error'] ?? data['message']}');
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Failed to connect to the server. Please try again.';
        _isLoading = false;
      });
      print('Error during signup: $e');
    }
  }

  void _nextPage() {
    _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Disables swipe
        children: [
          _buildGenderSelection(),
          _buildWeightInput(),
          _buildHeightInput(),
          _buildAgeInput(),
          _buildNameInput(),
          _buildMainGoalsSelection(), // Updated Main Goal Selection Page
          _buildAllergyForm(),
          _buildAccountForm(),
        ],
      ),
    );
  }

  // --- EXISTING WIDGETS (unchanged) ---

  Widget _buildGenderSelection() {
    return _buildFormPage(
      title: "Select Your Gender",
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderCard('Male', 'lib/assets/images/male.png'),
              _buildGenderCard('Female', 'lib/assets/images/female.png'),
            ],
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _gender != null ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Consistent color
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String genderLabel, String imagePath) {
    final isSelected = _gender == genderLabel;

    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = genderLabel;
        });
      },
      child: Container(
        width: 130,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300, // Lighter grey for unselected
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10),
            Text(
              genderLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return _buildFormPage(
      title: "Select Your Weight (kg)",
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(Icons.fitness_center, size: 50, color: Colors.orange),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.orange.shade50, Colors.white],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: ((_weight - 30) * 2).toInt(),
                  ),
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _weight = 30 + index * 0.5;
                    });
                  },
                  perspective: 0.002,
                  diameterRatio: 1.5,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 241, // Range for 30kg to 150kg (241 items for 0.5 increments)
                    builder: (context, index) {
                      final value = 30 + index * 0.5;
                      final isSelected = (_weight - value).abs() < 0.01;

                      return Center(
                        child: Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            color: isSelected ? Colors.orange.shade700 : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 75,
                child: Container(
                  width: 120,
                  height: 2,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "${_weight.toStringAsFixed(1)} kg",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightInput() {
    return _buildFormPage(
      title: "Select Your Height (cm)",
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(Icons.height, size: 50, color: Colors.green),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.green.shade50, Colors.white],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: ((_height - 100) * 2).toInt(),
                  ),
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _height = 100 + index * 0.5;
                    });
                  },
                  perspective: 0.002,
                  diameterRatio: 1.5,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 241, // Range for 100cm to 220cm
                    builder: (context, index) {
                      final value = 100 + index * 0.5;
                      final isSelected = (_height - value).abs() < 0.01;

                      return Center(
                        child: Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            color: isSelected ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 75,
                child: Container(
                  width: 120,
                  height: 2,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "${_height.toStringAsFixed(1)} cm",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeInput() {
    return _buildFormPage(
      title: "Select Your Age",
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(Icons.cake, size: 50, color: Colors.deepPurple),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepPurple.shade50, Colors.white],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: (_ageValue - 10).toInt(),
                  ),
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _ageValue = 10 + index.toDouble();
                    });
                  },
                  perspective: 0.002,
                  diameterRatio: 1.5,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 91, // Ages 10-100
                    builder: (context, index) {
                      final value = 10 + index;
                      final isSelected = (_ageValue - value).abs() < 0.01;

                      return Center(
                        child: Text(
                          "$value",
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            color: isSelected ? Colors.deepPurple.shade700 : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Selection indicator line
              Positioned(
                top: 75,
                child: Container(
                  width: 120,
                  height: 2,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "${_ageValue.toInt()} years old",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return _buildFormPage(
      title: "What's Your Name?",
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(Icons.person, size: 50, color: Colors.indigo),
          SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.indigo.shade50, Colors.white],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: _name,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild when text changes
                },
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo.shade700,
                ),
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(
                    color: Colors.indigo.shade600,
                    fontSize: 16,
                  ),
                  hintText: "Enter your full name",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: Colors.indigo.shade400,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _name.text.trim().isNotEmpty ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _name.text.trim().isNotEmpty ? Colors.indigo : Colors.grey,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: Text(
              "Next",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED WIDGET FOR MAIN GOAL SELECTION ---

  Widget _buildMainGoalsSelection() {
    return _buildFormPage(
      title: "What is Your Main Fitness Goal?",
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(Icons.track_changes, size: 50, color: Colors.purple),
          SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2, // Two columns
            crossAxisSpacing: 16, // Horizontal spacing
            mainAxisSpacing: 16, // Vertical spacing
            shrinkWrap: true, // Prevents GridView from taking infinite height
            physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildGoalCard('Weight Loss', Icons.trending_down, Colors.red),
              _buildGoalCard('Muscle Gain', Icons.fitness_center, Colors.blue),
              _buildGoalCard('Improve Endurance', Icons.directions_run, Colors.green),
              _buildGoalCard('General Fitness', Icons.self_improvement, Colors.orange),
              _buildGoalCard('Maintain Weight', Icons.balance, Colors.purple),
            ],
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _mainGoal != null ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Updated helper method for building individual goal cards
  Widget _buildGoalCard(String goalLabel, IconData iconData, Color color) {
    final isSelected = _mainGoal == goalLabel;

    return GestureDetector(
      onTap: () {
        setState(() {
          _mainGoal = goalLabel; // Update the single selected goal
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 40, color: isSelected ? color : color.withOpacity(0.6)),
            SizedBox(height: 10),
            Text(
              goalLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- EXISTING WIDGETS (unchanged) ---

  Widget _buildAllergyForm() {
    return _buildFormPage(
      title: "Do You Have Any Food Allergies?",
      child: Column(
        children: [
          TextField(
            controller: _allergy,
            decoration: InputDecoration(
              labelText: 'Allergies (Optional)',
              hintText: 'e.g., Peanuts, Dairy, Gluten',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.sick_outlined, color: Colors.blueGrey), // Consistent icon style
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueGrey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueGrey, width: 2),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey, // A new color for this page's button
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountForm() {
    return _buildFormPage(
      title: "Create Your Account",
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(Icons.account_circle, size: 50, color: Colors.teal),
          SizedBox(height: 24),

          // Email Input Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.teal.shade50, Colors.white],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild for validation
                    },
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal.shade700,
                    ),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: TextStyle(
                        color: Colors.teal.shade600,
                        fontSize: 14,
                      ),
                      hintText: "Enter your email",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade500, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.teal.shade400,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild for validation
                    },
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal.shade700,
                    ),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(
                        color: Colors.teal.shade600,
                        fontSize: 14,
                      ),
                      hintText: "Create a secure password",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade500, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.teal.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // Sign Up Button
          _isLoading
              ? Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                )
              : ElevatedButton(
                  onPressed: _isFormValid() ? _signup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid() ? Colors.teal : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

          SizedBox(height: 16),

          // Response Message
          if (_responseMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _responseMessage.contains('successfully')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _responseMessage.contains('successfully')
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _responseMessage.contains('successfully')
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _responseMessage.contains('successfully')
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _responseMessage,
                      style: TextStyle(
                        color: _responseMessage.contains('successfully')
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 24),

          // Login Link
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.teal.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for form validation (only applies to the final account form)
  bool _isFormValid() {
    return _email.text.trim().isNotEmpty &&
        _password.text.trim().isNotEmpty &&
        _email.text.contains('@') &&
        _password.text.length >= 6;
  }

  // Helper method for building consistent form pages
  Widget _buildFormPage({required String title, required Widget child}) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          left: 16,
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Only navigate back if not on the first page
              if (_pageController.page != null && _pageController.page! > 0) {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // If on the first page, navigate back to previous screen (e.g., welcome/intro)
                Navigator.pop(context);
              }
            },
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60), // Space for the back button
                  Text(
                    title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}