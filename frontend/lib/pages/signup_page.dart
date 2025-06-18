import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/animation.dart';

import '../main.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentPageIndex = 0;

  String? _gender;
  double _weight = 60;
  double _height = 170;
  double _ageValue = 25;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _mainGoal;
  double _targetWeight = 60;
  final TextEditingController _allergy = TextEditingController();

  String _responseMessage = '';
  bool _isLoading = false;

  // Page colors
  final List<Color> pageColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.indigo,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page?.round() ?? 0;
      });
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
          'role': '1',
          'gender': _gender,
          'weight': _weight,
          'height': _height,
          'age': _ageValue.toInt().toString(),
          'goal': _mainGoal,
          'target_weight': _targetWeight,
          'allergy': _allergy.text.isEmpty ? null : _allergy.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        _responseMessage = data['message'] ?? data['error'] ?? 'An unknown error occurred.';
        _isLoading = false;
      });

      if (response.statusCode == 200 && data['message'] == 'User registered successfully') {
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
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
    _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  pageColors[_currentPageIndex].withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          // Floating particles
          ...List.generate(5, (index) => _FloatingParticle(color: pageColors[_currentPageIndex])),
          
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildGenderSelection(),
              _buildWeightInput(),
              _buildHeightInput(),
              _buildAgeInput(),
              _buildNameInput(),
              _buildMainGoalsSelection(),
              _buildTargetWeightInput(),
              _buildAllergyForm(),
              _buildAccountForm(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection() {
    return _buildFormPage(
      title: "Select Your Gender",
      child: Column(
        children: [
          SizedBox(height: 20),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _buildGenderCard('Male', 'lib/assets/images/male.png', Colors.blue),
              _buildGenderCard('Female', 'lib/assets/images/female.png', Colors.pink),
            ],
          ),
          SizedBox(height: 40),
          _buildNextButton(
            onPressed: _gender != null ? _nextPage : null,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String genderLabel, String imagePath, Color color) {
    final isSelected = _gender == genderLabel;

    return AnimatedScale(
      duration: Duration(milliseconds: 300),
      scale: isSelected ? 1.05 : 1.0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = genderLabel;
          });
        },
        child: Container(
          width: 180, // increased from 150 to 180
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16), // increased padding from 12 to 16
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
                child: Image.asset(
                  imagePath,
                  width: 100, // increased from 80 to 100
                  height: 100, // increased from 80 to 100
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 12),
              Text(
                genderLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return _buildFormPage(
      title: "Select Your Weight (kg)",
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade100, Colors.orange.shade300],
              ),
            ),
            child: Icon(Icons.fitness_center, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
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
                  diameterRatio: 1.8,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 241,
                    builder: (context, index) {
                      final value = 30 + index * 0.5;
                      final isSelected = (_weight - value).abs() < 0.01;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 22,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.orange.shade700 : Colors.grey,
                          ),
                          child: Text(value.toStringAsFixed(1)),
                        ),
                      );
                    },
                  ),
                ),
                // Selection indicator
                Positioned(
                  top: 85,
                  child: Container(
                    width: 140,
                    height: 2,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "${_weight.toStringAsFixed(1)} kg",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 30),
          _buildNextButton(
            onPressed: _nextPage,
            color: Colors.orange,
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
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade100, Colors.green.shade400],
              ),
            ),
            child: Icon(Icons.height, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
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
                  diameterRatio: 1.8,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 241,
                    builder: (context, index) {
                      final value = 100 + index * 0.5;
                      final isSelected = (_height - value).abs() < 0.01;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 22,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.green.shade700 : Colors.grey,
                          ),
                          child: Text(value.toStringAsFixed(1)),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 85,
                  child: Container(
                    width: 140,
                    height: 2,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "${_height.toStringAsFixed(1)} cm",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 30),
          _buildNextButton(
            onPressed: _nextPage,
            color: Colors.green,
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
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade100, Colors.purple.shade400],
              ),
            ),
            child: Icon(Icons.cake, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
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
                  diameterRatio: 1.8,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 91,
                    builder: (context, index) {
                      final value = 10 + index;
                      final isSelected = (_ageValue - value).abs() < 0.01;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 22,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.purple.shade700 : Colors.grey,
                          ),
                          child: Text("$value"),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 85,
                  child: Container(
                    width: 140,
                    height: 2,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "${_ageValue.toInt()} years old",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.purple.shade800,
            ),
          ),
          SizedBox(height: 30),
          _buildNextButton(
            onPressed: _nextPage,
            color: Colors.purple,
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
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo.shade100, Colors.indigo.shade400],
              ),
            ),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.indigo.shade800,
              ),
              decoration: InputDecoration(
                hintText: "Enter your full name",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 18,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          SizedBox(height: 40),
          _buildNextButton(
            onPressed: _name.text.trim().isNotEmpty ? _nextPage : null,
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildMainGoalsSelection() {
    return _buildFormPage(
      title: "What is Your Main Fitness Goal?",
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.pink.shade100, Colors.pink.shade400],
              ),
            ),
            child: Icon(Icons.flag, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildGoalCard('Weight Loss', Icons.trending_down, Colors.red),
              _buildGoalCard('Muscle Gain', Icons.fitness_center, Colors.blue),
              _buildGoalCard('Improve Endurance', Icons.directions_run, Colors.green),
              _buildGoalCard('General Fitness', Icons.self_improvement, Colors.orange),
              _buildGoalCard('Maintain Weight', Icons.balance, Colors.purple),
            ],
          ),
          SizedBox(height: 30),
          _buildNextButton(
            onPressed: _mainGoal != null ? _nextPage : null,
            color: Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String goalLabel, IconData iconData, Color color) {
    final isSelected = _mainGoal == goalLabel;
    
    return AnimatedScale(
      duration: Duration(milliseconds: 300),
      scale: isSelected ? 1.05 : 1.0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mainGoal = goalLabel;
          });
        },
        child: Container(
          width: 140,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 40, color: isSelected ? color : color.withOpacity(0.7)),
              SizedBox(height: 12),
              Text(
                goalLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetWeightInput() {
    return _buildFormPage(
      title: "What is Your Target Weight?",
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade100, Colors.teal.shade400],
              ),
            ),
            child: Icon(Icons.track_changes, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: ((_targetWeight - 30) * 2).toInt(),
                  ),
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _targetWeight = 30 + index * 0.5;
                    });
                  },
                  perspective: 0.002,
                  diameterRatio: 1.8,
                  squeeze: 1.2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 241,
                    builder: (context, index) {
                      final value = 30 + index * 0.5;
                      final isSelected = (_targetWeight - value).abs() < 0.01;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 22,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.teal.shade700 : Colors.grey,
                          ),
                          child: Text(value.toStringAsFixed(1)),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 85,
                  child: Container(
                    width: 140,
                    height: 2,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "${_targetWeight.toStringAsFixed(1)} kg",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.teal.shade800,
            ),
          ),
          SizedBox(height: 30),
          _buildNextButton(
            onPressed: _nextPage,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyForm() {
    return _buildFormPage(
      title: "Do You Have Any Food Allergies?",
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber.shade100, Colors.amber.shade400],
              ),
            ),
            child: Icon(Icons.warning, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _allergy,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'List any food allergies you have...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 40),
          _buildNextButton(
            onPressed: _nextPage,
            color: Colors.amber,
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
          SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.cyan.shade100, Colors.cyan.shade400],
              ),
            ),
            child: Icon(Icons.account_circle, size: 50, color: Colors.white),
          ),
          SizedBox(height: 30),
          
          // Email Field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter your email",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.email, color: Colors.cyan),
              ),
            ),
          ),
          
          // Password Field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Create a secure password",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.lock, color: Colors.cyan),
              ),
            ),
          ),
          
          // Sign Up Button
          _isLoading
              ? Container(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.cyan, Colors.cyan.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.4),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _isFormValid() ? _signup : null,
                      child: Center(
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          
          SizedBox(height: 20),
          
          // Response Message
          if (_responseMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _responseMessage.contains('successfully')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _responseMessage.contains('successfully')
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                  width: 1.5,
                ),
              ),
              child: Text(
                _responseMessage,
                style: TextStyle(
                  color: _responseMessage.contains('successfully')
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          SizedBox(height: 20),
          
          // Login Link
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text.rich(
              TextSpan(
                text: "Already have an account? ",
                style: TextStyle(color: Colors.grey.shade700),
                children: [
                  TextSpan(
                    text: "Sign In",
                    style: TextStyle(
                      color: Colors.cyan.shade700,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage({required String title, required Widget child}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(9, (index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: index == _currentPageIndex ? 16 : 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _currentPageIndex 
                            ? pageColors[_currentPageIndex] 
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 20),
                
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, size: 28),
                    onPressed: () {
                      if (_pageController.page! > 0 && _pageController.page! < 9) {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }else{
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton({VoidCallback? onPressed, required Color color}) {
    return Container(
      width: 150,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Center(
            child: Text(
              "Next",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isFormValid() {
    return _email.text.trim().isNotEmpty &&
        _password.text.trim().isNotEmpty &&
        _email.text.contains('@') &&
        _password.text.length >= 6;
  }
}

class _FloatingParticle extends StatefulWidget {
  final Color color;
  
  const _FloatingParticle({required this.color});
  
  @override
  __FloatingParticleState createState() => __FloatingParticleState();
}

class __FloatingParticleState extends State<_FloatingParticle> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();
  
  double posX = 0;
  double posY = 0;
  double size = 0;
  double duration = 0;
  
  @override
  void initState() {
    super.initState();
    _initParticle();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (duration * 1000).round()),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _initParticle();
          _controller.reset();
          _controller.forward();
        }
      });
    
    _controller.forward();
  }
  
  void _initParticle() {
    posX = _random.nextDouble() * 100;
    posY = _random.nextDouble() * 100;
    size = _random.nextDouble() * 10 + 5;
    duration = _random.nextDouble() * 4 + 3;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final offsetX = sin(value * 2 * pi) * 20;
        final offsetY = cos(value * 2 * pi) * 20;
        
        return Positioned(
          left: posX + offsetX,
          top: posY + offsetY,
          child: Opacity(
            opacity: 0.7 - (value * 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}