import 'package:flutter/material.dart';
import 'package:frontend/pages/MainPage.dart';
import 'package:frontend/pages/onboard_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

const String baseUrl = "http://10.0.2.2:5000";

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // Check if user is logged in

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NextGen Fitness',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: isLoggedIn ? '/mainpage' : '/', // Set initial route based on login status
      routes: {
        '/': (context) => OnboardingPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/mainpage': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}