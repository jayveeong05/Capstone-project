import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart'; // Your baseUrl should be defined here
import 'LoginPage.dart'; // Adjust the import if LoginPage is in a different path

class Resetpasswordpage extends StatefulWidget {
  final String email;
  Resetpasswordpage({required this.email});

  @override
  ResetpasswordpageState createState() => ResetpasswordpageState();
}

class ResetpasswordpageState extends State<Resetpasswordpage> {
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _responseMessage = '';

  void _submitNewPassword() async {
    if (_newPassword.text.isEmpty || _confirmPassword.text.isEmpty) {
      setState(() {
        _responseMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_newPassword.text != _confirmPassword.text) {
      setState(() {
        _responseMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'new_password': _newPassword.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _responseMessage = data['message'] ?? 'Password reset successful';
        });

        // Wait 2 seconds and redirect to login page
        await Future.delayed(Duration(seconds: 2));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _responseMessage = data['error'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitNewPassword,
      icon: Icon(Icons.check_circle_outline),
      label: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text("Submit"),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMessage() {
    return AnimatedOpacity(
      opacity: _responseMessage.isNotEmpty ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Text(
        _responseMessage,
        style: TextStyle(
          color: _responseMessage.toLowerCase().contains("success")
              ? Colors.green
              : Colors.red,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 80, color: Theme.of(context).primaryColor),
                SizedBox(height: 20),
                Text(
                  "Reset password for:",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.email,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                _buildPasswordField(
                  label: "New Password",
                  controller: _newPassword,
                  obscureText: _obscureNew,
                  toggle: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                ),
                SizedBox(height: 20),
                _buildPasswordField(
                  label: "Confirm Password",
                  controller: _confirmPassword,
                  obscureText: _obscureConfirm,
                  toggle: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
                SizedBox(height: 30),
                _buildSubmitButton(),
                SizedBox(height: 20),
                _buildMessage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
