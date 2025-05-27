import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart'; // for baseUrl

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String _responseMessage = '';

  Future<void> _signup() async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _username.text,
        'password': _password.text,
        'email': _email.text,
      }),
    );

    final data = jsonDecode(response.body);
    setState(() {
      _responseMessage = data['message'] ?? data['error'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
              TextField(controller: _email, decoration: InputDecoration(labelText:'Email' )),
              TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _signup, child: Text("Sign Up")),
              SizedBox(height: 10),
              Text(_responseMessage, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
