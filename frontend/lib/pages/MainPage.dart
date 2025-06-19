import 'package:flutter/material.dart';
import 'MealSuggestionPage.dart';
import 'MealScannerScreen.dart';
import 'ChatbotPage.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
            child: CircleAvatar(
              backgroundImage: AssetImage('lib/assets/images/user_avatar.png'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today’s Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.6, color: Colors.greenAccent),
                      SizedBox(height: 8),
                      Text('1200 / 2000 kcal')
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(              mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildQuickAction(Icons.camera_alt, 'Scan Meal', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MealScannerScreen(userId: 'user123')), // TODO: Replace with actual user ID
                    );
                  }),
                  buildQuickAction(Icons.mic, 'Voice Log', onTap: () {}),
                  buildQuickAction(Icons.fitness_center, 'Workout', onTap: () {}),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.restaurant_menu),
                  label: Text('Go to Meal Plans'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MealPlansPage()),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Card(
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Keep it up! You’re only 30 mins away from your daily goal.",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildUtilityCard(Icons.access_alarm, 'Set Reminder', Colors.orange, () {
                    // Reminder action
                  }),
                  _buildUtilityCard(Icons.chat, 'Chat with AI Coach', Colors.lightGreen, () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChatbotPage(userId: 'user123'),
                    ));
                  }),
                  _buildUtilityCard(Icons.help, 'Help & Support', Colors.redAccent, () {
                    // Help action
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // handle navigation
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
  Widget buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildUtilityCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
