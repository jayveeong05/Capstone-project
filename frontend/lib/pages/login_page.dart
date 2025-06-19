// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:frontend/pages/admin_main_page.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

import '../main.dart';
import 'forget_password_page.dart';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _responseMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.blue[200],
      end: Colors.blue[700],
    ).animate(_animationController);
    
    // Start animations with a slight delay for better visual effect
    Future.delayed(Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username.text,
          'password': _password.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        _responseMessage = data['message'] ?? data['error'] ?? 'Unknown error';
      });
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (_responseMessage == 'Login successful') {
        String userId = responseData['user_id'];
        int numericUserId = int.parse(userId.replaceAll(RegExp(r'\D'), ''));
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', numericUserId);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', _username.text);
        
        // Store user role
        int role = data['role'] ?? 1; // Default to normal user
        await prefs.setInt('role', role);

        // Navigate based on role
        if (role == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Network error, please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _colorAnimation.value ?? Colors.blue[200]!,
                  Colors.white,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.popAndPushNamed(context, '/'),
                  ),
                ),
                
                // Floating particles
                Positioned(
                  top: 100,
                  right: 30,
                  child: _FloatingCircle(
                    size: 20,
                    delay: 0,
                  ),
                ),
                Positioned(
                  top: 180,
                  left: 40,
                  child: _FloatingCircle(
                    size: 15,
                    delay: 200,
                  ),
                ),
                Positioned(
                  bottom: 200,
                  right: 50,
                  child: _FloatingCircle(
                    size: 25,
                    delay: 400,
                  ),
                ),
                
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo/App name
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fitness_center, 
                                        size: 32, 
                                        color: theme.primaryColor),
                                    SizedBox(width: 10),
                                    Text(
                                      "NEXTGEN FITNESS",
                                      style: theme.textTheme.headline6?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "Welcome Back",
                                  style: theme.textTheme.headline5?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Sign in to continue your fitness journey",
                                  style: theme.textTheme.subtitle1?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 32),
                                
                                // Username Field
                                TextField(
                                  controller: _username,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                  ),
                                ),
                                SizedBox(height: 20),
                                
                                // Password Field
                                TextField(
                                  controller: _password,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                          ? Icons.visibility_off 
                                          : Icons.visibility,
                                      ),
                                      onPressed: () => setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      }),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                  ),
                                ),
                                SizedBox(height: 20),
                                
                                // Login Button
                                Material(
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 5,
                                  child: Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.primaryColor,
                                          theme.primaryColor.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _isLoading ? null : _login,
                                      child: Center(
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 3,
                                                ),
                                              )
                                            : Text(
                                                "Login",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                // Forgot Password
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ForgetPasswordPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                
                                // Response Message
                                if (_responseMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      _responseMessage,
                                      style: TextStyle(
                                        color: _responseMessage == 'Login successful' 
                                            ? Colors.green 
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                SizedBox(height: 20),
                                
                                // Sign Up Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.pushReplacementNamed(
                                          context, 
                                          '/signup'
                                        );
                                      },
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension on TextTheme {
  get headline6 => null;
  
  get subtitle1 => null;
  
  get headline5 => null;
}

// Floating circle animation for background decoration
class _FloatingCircle extends StatefulWidget {
  final double size;
  final int delay;

  const _FloatingCircle({required this.size, required this.delay});

  @override
  __FloatingCircleState createState() => __FloatingCircleState();
}

class __FloatingCircleState extends State<_FloatingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });

    // Start animation after delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      _controller.forward();
    });
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
        return Transform.translate(
          offset: Offset(0, -20 * _animation.value),
          child: Opacity(
            opacity: 0.6 - (0.3 * _animation.value),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[100],
              ),
            ),
          ),
        );
      },
    );
  }
}