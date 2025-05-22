import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}


const String baseUrl = "http://localhost:53070";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _responseMessage = '';

  Future<void> _signup() async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
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
  }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NextGen Fitness Web App")),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
              TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _signup, child: Text("Sign Up")),
                  ElevatedButton(onPressed: _login, child: Text("Login")),
                ],
              ),
              SizedBox(height: 20),
              Text(_responseMessage, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
