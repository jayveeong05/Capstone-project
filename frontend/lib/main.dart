import 'package:flutter/material.dart';
import 'package:frontend/pages/GroceryShopLocator.dart';
import 'package:frontend/pages/admin_feedback_overview.dart';
import 'package:frontend/pages/admin_registered_user_overview.dart';
import 'package:frontend/pages/admin_user_activity_monitoring.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:frontend/pages/onboard_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages//profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/admin_main_page.dart'; // Import admin_main_page.dart


const String baseUrl = "http://10.0.2.2:5000";

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // Check if user is logged in
  int? role = prefs.getInt('role'); // Get the user's role

  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int? role; // Add role to MyApp

  const MyApp({Key? key, required this.isLoggedIn, this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String initialRoute;
    if (isLoggedIn) {
      if (role == 0) { // Assuming 0 is admin role
        initialRoute = '/admin_main_page'; // New route for admin
      } else {
        initialRoute = '/mainpage';
      }
    } else {
      initialRoute = '/';
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NextGen Fitness',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialRoute, // Set initial route based on login status and role
      routes: {
        '/': (context) => OnboardingPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/mainpage': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
        '/groceryLocator': (context) => GroceryShopLocator(),
        '/admin_registered_user_overview': (context) => AdminRegisteredUserOverview(),
        '/admin_user_activity_monitoring': (context) => AdminUserActivityMonitoring(),
        '/admin_feedback_overview': (context) => AdminFeedbackOverview(),
        '/admin_main_page': (context) => AdminDashboard(), // Define the route for AdminDashboard
      },
    );
  }
}