import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'fitness_page.dart';
import 'generate_workout_plan.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Welcome, User! 👋',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage(userId: userId!)),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: AssetImage('lib/assets/images/user_avatar.png'),
              ),
            ),
          )
        ],
      ),
body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FitnessPage()),
          );
        },
        child: Text("Fitness Page"),
      ),
      SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GenerateWorkoutPlanPage()),
          );
        },
        child: Text("Generate Workout Plan"),
      ),
    ],
    ),
  ),
    );
  }
}
