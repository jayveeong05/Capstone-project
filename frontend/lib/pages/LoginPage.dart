import 'package:flutter/material.dart';
import 'package:frontend/pages/MainPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';
import 'ForgetPasswordPage.dart'; // <-- import it here

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _responseMessage = '';

  Future<void> _login() async {
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
      _responseMessage = data['message'] ?? data['error'];
    });

    // Check for success (adjust condition as per your API)
    if (_responseMessage == 'Login successful') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
              TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: Text("Login")),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgetPasswordPage()),
                  );
                },
                child: Text("Forgot Password?"),
              ),
              SizedBox(height: 10),
              Text(_responseMessage, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}