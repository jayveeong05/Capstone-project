import 'package:flutter/material.dart';
import 'package:frontend/pages/MainPage.dart';
import 'package:frontend/pages/OnboardPage.dart';
import 'pages/LoginPage.dart';
import 'pages/SignUpPage.dart';

const String baseUrl = "http://10.0.2.2:5000";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Web Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => OnboardingPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/mainpage': (context) => MainPage(),
      },
    );
  }
}