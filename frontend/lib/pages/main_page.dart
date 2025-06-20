import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fitness_page.dart';
import 'all_workoutplan_page.dart';
import 'MealPlansPage.dart';
import 'MealScannerScreen.dart';
import 'ChatbotPage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _username = 'User'; // Default username
  int _currentIndex = 0; // For BottomNavigationBar selection

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Load existing profile data when the page initializes
  }
  // Function to load the username from SharedPreferences
  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User'; // Retrieve username or default to 'User'
    });
  }

  // Function to handle logout
    Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all data in SharedPreferences (including 'isLoggedIn' and 'username')
    // Ensure you have a login route defined in your MaterialApp
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }


  // Helper widget to build a standardized section card
  Widget _buildSectionCard({required Widget child, Color? color, double elevation = 4}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: elevation,
      color: color ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }

  // Helper widget to build a quick stat item
  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Expanded( // Use Expanded for even distribution
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // Helper widget to build a progress bar
  Widget _buildProgressBar(
      String title, double progressValue, String progressText, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            progressText,
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }

  // Helper widget to build a quick action button (e.g., Meal Log, Voice Log)
  Widget _buildQuickActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a utility card (e.g., Exercise Library, AI Recipe)
  Widget _buildUtilityCard(
      IconData icon, String title, Color color, VoidCallback onPressed) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
void _showNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // Dummy list of notifications (you can replace with real data)
      final List<String> notifications = [
        'Don’t forget your workout today!',
        'New workout plan available.',
        'Check your progress in the Profile section.',
      ];

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...notifications.map((note) => ListTile(
              leading: Icon(Icons.notification_important_outlined, color: Colors.blueAccent),
              title: Text(note),
              onTap: () {
                Navigator.pop(context); // Close after tap
              },
            )),
          ],
        ),
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for modern feel
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          'Welcome, $_username! 👋', // Display personalized username
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Inter', // Assuming Inter font is available or set globally
          ),
        ),
        actions: [
          // Profile Avatar/Button (can be tapped to go to profile settings)
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () => _showNotifications(context),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile'); // Navigate to Profile Page
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                // Using a placeholder image for now, replace with actual user_avatar.png
                // Make sure 'lib/assets/images/user_avatar.png' exists
                // or use a different Asset, NetworkImage, or Icon as fallback
                child: Image.asset(
                  'lib/assets/images/user_avatar.png',
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      color: Colors.blueAccent,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Stats/Highlights Card (Your Daily Progress)
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Daily Progress',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                            Icons.local_fire_department, 'Calories Left', '1200 kcal', Colors.orange),
                        _buildStatItem(Icons.run_circle_outlined, 'Steps', '5,200 / 8,000', Colors.green),
                        _buildStatItem(Icons.fitness_center, 'Workouts', '1/2 Done', Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProgressBar(
                      'Overall Goal Progress',
                      0.6, // Example value
                      '60% Completed',
                      Colors.blueAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Quick Actions Section
              const Text(
                'Quick Actions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2, // Two items per row
                childAspectRatio: 2.1, // Adjusted aspect ratio to make buttons slightly shorter
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildQuickActionButton(Icons.restaurant_menu, 'Log Meal', () {
                    // TODO: Open Meal Logging Interface
                    print('Open Meal Logging');
                  }),
                  _buildQuickActionButton(Icons.mic, 'Voice Log', () {
                    // TODO: Activate Voice Logging
                    print('Activate Voice Log');
                  }),
                  _buildQuickActionButton(Icons.camera_alt, 'Meal Scan', () {
                    // TODO: Open Meal Scanner
                    // print('Open Meal Scanner');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MealScannerScreen(userId: 'user123')), // TODO: Replace with actual user ID
                    );
                  }),
                  _buildQuickActionButton(Icons.add_task, 'Set Goals', () {
                    // TODO: Navigate to Goal Setting Page (or a modal)
                    print('Set Goals');
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Motivational Message / Daily Reminder
              _buildSectionCard(
                color: Colors.blueAccent.withOpacity(0.9),
                elevation: 6, // Slightly higher elevation for emphasis
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.white, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Great job! You’re only 30 minutes away from your daily workout goal. Keep pushing!",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Explore & Learn (Utility Features - formerly "Your Journey At A Glance")
              const Text(
                'Explore & Learn',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
                children: [
                    _buildUtilityCard(
                      Icons.accessibility_new,
                      'Workout Plans',
                      Colors.deepPurple,
                      () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        int? userId = prefs.getInt('user_id');
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllWorkoutPlansPage(userId: userId),
                    
                            ),
                          );
                        } else {
                          print('❌ No user ID found in SharedPreferences');
                        }
                      },
                    ),
                  _buildUtilityCard(
                      Icons.restaurant_menu, 'Meal Plans', Colors.teal,
                      () {
                    // TODO: Navigate to Meal Plan Page
                    // print('Navigate to Meal Plan');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MealPlansPage()),
                    );
                  }),
                  _buildUtilityCard(
                      Icons.video_library, 'Exercise Library', Colors.redAccent,
                      () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FitnessPage()),
                    );
                  }),
                  _buildUtilityCard(
                      Icons.menu_book, 'Meal Library', Colors.deepOrangeAccent, // Changed from 'AI Recipe Ideas' to 'Meal Library'
                      () {
                    // TODO: Navigate to Meal Library
                    print('Navigate to Meal Library');
                  }),
                  _buildUtilityCard(
                      Icons.chat, 'Chat with AI Coach', Colors.lightGreen, () {
                    // TODO: Open Chatbot
                    //print('Open Chatbot');
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChatbotPage(userId: 'user123'),
                    ));
                  }),
                  _buildUtilityCard(
                      Icons.gps_fixed, 'Grocery Locator', Colors.blueGrey, () {
                    // TODO: Navigate to Grocery Shop Locator
                    print('Navigate to Grocery Locator');
                  }),
                ],
              ),
              const SizedBox(height: 20), // Added buffer at the very bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Handle navigation for bottom bar based on the documentation
          switch (index) {
            case 0: // Home
              // Already on Home, perhaps scroll to top or refresh
              print('Navigated to Home');
              break;
            case 1: // Customize (Changed from Plans)
              // TODO: Navigate to a consolidated Plans/Customize page or directly to Workout/Diet overview
              print('Navigated to Customize');
              // Example: Navigator.of(context).pushNamed('/customize');
              break;
            case 2: // Progress
              // TODO: Navigate to Detailed Progress Tracking page
              print('Navigated to Progress');
              Navigator.of(context).pushNamed('/progress'); // Assuming a '/progress' route
              break;
            case 3: // Settings (aligned with Profile in this case)
              // TODO: Navigate to Settings/Profile page
              print('Navigated to Settings');
              Navigator.of(context).pushNamed('/profile'); // Assuming '/profile' route
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Customize'), // Changed label to 'Customize', and icon to tune_outlined/tune
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), activeIcon: Icon(Icons.insights), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
