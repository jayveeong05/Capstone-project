import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';

class Resetpasswordpage extends StatefulWidget{
      final String email;
      Resetpasswordpage({required this.email});

      @override
      ResetpasswordpageState createState() => ResetpasswordpageState();
}
class ResetpasswordpageState extends State<Resetpasswordpage> {
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  String _responseMessage = '';

  void _submitNewPassword() async {
  if (_newPassword.text != _confirmPassword.text) {
    setState(() {
      _responseMessage = 'Passwords do not match';
    });
    return;
  }

  final response = await http.post(
    Uri.parse('$baseUrl/reset-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': widget.email,
      'new_password': _newPassword.text,
    }),
  );

  final data = jsonDecode(response.body);
  setState(() {
    if (response.statusCode == 200) {
      _responseMessage = data['message'];
    } else {
      _responseMessage = data['error'] ?? 'Failed to reset password';
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Reset password for ${widget.email}"),
              TextField(
                controller: _newPassword,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitNewPassword,
                child: Text("Submit"),
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