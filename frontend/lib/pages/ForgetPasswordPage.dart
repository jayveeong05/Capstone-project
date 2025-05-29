import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';
import 'ResetPasswordPage.dart';

class ForgetPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _email = TextEditingController();
  String _responseMessage = '';

  Future<void> _resetPassword() async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _email.text}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Resetpasswordpage(email: _email.text),
        ),
      );
    } else {
      setState(() {
        _responseMessage = data['error'] ?? 'Unknown error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password")),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _email,
                decoration: InputDecoration(labelText: 'Enter your registered email'),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _resetPassword, child: Text("Reset Password")),
              SizedBox(height: 10),
              Text(_responseMessage, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
