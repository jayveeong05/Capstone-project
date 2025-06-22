import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fitness_page.dart';
import 'all_workoutplan_page.dart';
import 'MealPlansPage.dart';
import 'MealScannerScreen.dart';
import 'ChatbotPage.dart';
import 'package:http/http.dart'as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _username = 'User'; // Default username
  int _currentIndex = 0; // For BottomNavigationBar selection
  String _currentMotivationalMessage = '';

  // List of motivational messages
  final List<String> _motivationalMessages = [
    "You don’t have to be great to start — but you do have to put down the donut. 🍩💪",
    "Sore today, strong tomorrow. And yes, you can still walk like a crab in public. 🦀",
    "Running late counts as cardio, but let’s aim higher. 🏃‍♂️🔥",
    "Your sweat is just your fat crying. Let it all out! 😭💦",
    "Warning: Side effects of working out include confidence, endorphins, and tight pants. 😎🩳",
    "Crush today. The couch will still be there tomorrow. 🛋️✨",
    "You didn’t come this far to only come this far. Keep going, beast! 🐺🔥",
    "Be the reason someone checks themselves in the mirror twice. 👀💪",
    "One more rep. One more win. You’ve got this! 🏆🎯",
    "You vs. You. Spoiler: You're winning. 🥇🔁",
    "Don’t quit now — pizza tastes better after a workout. 🍕❤️‍🔥",
    "Work out like your ex is watching. 👀💃",
    "Lift heavy. Laugh harder. Repeat. 😂🏋️‍♀️",
    "We’re not here to take it easy. We’re here to take it legendary. 🌟🔥",
    "Muscles loading… please wait. (And hydrate.) 💧⏳",
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchUserPlansWithProgress();
    _triggerDailyReminder();
    _setRandomMotivationalMessage();
  }
  // Function to load the username from SharedPreferences
  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User'; // Retrieve username or default to 'User'
    });
  }

void _launchYouTube(String url) async {
    final Uri url = Uri(
            scheme: 'https', host: 'www.youtube.com', path: '');  
            if (!await launchUrl(url,
                mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $url';
       }
  }

  
  // Function to set a random motivational message
  void _setRandomMotivationalMessage() {
    final _random = Random();
    setState(() {
      _currentMotivationalMessage = _motivationalMessages[_random.nextInt(_motivationalMessages.length)];
    });
  }
Future<void> _triggerDailyReminder() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');
  if (userId == null) return;

  final formattedUserId = 'U${userId.toString().padLeft(3, '0')}';

  final response = await http.post(Uri.parse('http://10.0.2.2:5000/reminders/check/$formattedUserId'),
  );

  if (response.statusCode == 200) {
    print("✅ Daily reminder checked for user $formattedUserId");
  } else {
    print("❌ Failed to check reminders: ${response.body}");
  }
}

Future<void> writeLog(String username, String action) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/activity_log.txt';
    final file = File(filePath);

    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss dd/MM/yyyy').format(now);
    final logLine = '-- $username has been $action at $formattedTime\n';

    await file.writeAsString(logLine, mode: FileMode.append); // Append to the file
    print('✅ Log written: $logLine');
    print('Log file stored at: ${file.path}');
  } catch (e) {
    print('❌ Failed to write log: $e');
  }
}

Future<void> _logout() async {
  final confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Logout"),
      content: Text("Are you sure you want to logout?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Logout", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User';
    final userId = prefs.getInt('user_id');
    await writeLog(username, 'logged out');
    if (userId != null) {
      try {
        final uri = Uri.parse('http://10.0.2.2:5000/logout'); // Use the correct logout endpoint
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'user_id': userId}),
        );

        if (response.statusCode == 200) {
          print('✅ Backend: Logout activity logged successfully for user $userId');
        } else {
          print('❌ Backend: Failed to log logout activity. Status: ${response.statusCode}, Body: ${response.body}');
        }
      } catch (e) {
        print('❌ Backend: Error sending logout request: $e');
      }
    } else {
      print('❌ No user ID found in SharedPreferences for backend logout logging.');
    }    



    // Show SnackBar before navigating away
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Logged out successfully"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Delay a bit so SnackBar is visible
    await Future.delayed(Duration(seconds: 1));

    // Navigate to main.dart or login screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
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

void _showNotifications(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');
  if (userId == null) return;
  final formattedUserId = 'U${userId.toString().padLeft(3, '0')}';
  final response = await http.get(
    Uri.parse('http://10.0.2.2:5000/notifications/$formattedUserId'),
  );

  if (response.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Failed to fetch notifications.')),
    );
    return;
  }

  final List<dynamic> notifications = json.decode(response.body);

  // Filter to show only unchecked notifications
  final List<dynamic> unchecked = notifications.where((n) => n['checked'] == 0).toList();

  if (unchecked.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🎉 No new notifications.")),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔔 Your Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...unchecked.map<Widget>((notif) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(
                    notif['type'] == 'daily reminder'
                        ? Icons.fitness_center
                        : Icons.notifications_active,
                    color: Colors.orangeAccent,
                  ),
                  title: Text(notif['type'].toString().toUpperCase()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notif['details'] != null)
                        Text(notif['details'], style: const TextStyle(fontSize: 14)),
                      Text("📅 ${notif['created_at']}"),
                    ],
                  ),
                  trailing: ElevatedButton(
                      onPressed: () async {
                        final res = await http.post(
                          Uri.parse('http://10.0.2.2:5000/notifications/check/${notif['notification_id']}'),
                        );

                        if (res.statusCode == 200) {
                          // ✅ After successful check, also update the progress
                          final planId = notif['plan_id'];
                          if (planId != null) {
                            await http.post(
                              Uri.parse('http://10.0.2.2:5000/check_workout_progress/$planId'),
                            );
                          }

                          Navigator.pop(context); // Close modal
                          _showNotifications(context); // Refresh with updated state
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("❌ Failed to mark as checked")),
                          );
                        }
                      },

                      child: const Text("Check"),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

int? _selectedPlanId;
List<Map<String, dynamic>> _userPlans = [];

Future<void> _fetchUserPlansWithProgress() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');
  if (userId == null) return;

  final formattedUserId = 'U${userId.toString().padLeft(3, '0')}';
  final uri = Uri.parse('http://10.0.2.2:5000/get-plans/$formattedUserId');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final plans = List<Map<String, dynamic>>.from(data['plans']);

      setState(() {
        _userPlans = plans;

        // Auto-select the latest or first plan if none selected
        if (_selectedPlanId == null && plans.isNotEmpty) {
          _selectedPlanId = plans.first['plan_id'];
        }
      });
    } else {
      throw Exception('Failed to fetch workout plans. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error in _fetchUserPlansWithProgress: $e');
  }
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
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
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
                child: Image.asset(
                  'lib/assets/images/user_avatar.png',
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, color: Colors.blueAccent, size: 28);
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
                        'Your Workout Plan Progress',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 16),
                      if (_userPlans.isEmpty)
                        const Text("No workout plans found."),
                      if (_userPlans.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<int>(
                              value: _selectedPlanId,
                              hint: const Text("Select Plan"),
                              items: _userPlans.map<DropdownMenuItem<int>>((plan) {
                                return DropdownMenuItem<int>(
                                  value: plan['plan_id'],
                                  child: Text("Plan ${plan['plan_id']} (${plan['duration_months']} month${plan['duration_months'] > 1 ? 's' : ''})"),
                                );
                              }).toList(),
                              onChanged: (int? newId) {
                                setState(() => _selectedPlanId = newId);
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_selectedPlanId != null)
                              Builder(
                                builder: (context) {
                                  final selectedPlan = _userPlans.firstWhere(
                                    (plan) => plan['plan_id'] == _selectedPlanId,
                                    orElse: () => {},
                                  );

                                  if (selectedPlan.isEmpty) return SizedBox();

                                  return _buildProgressBar(
                                    'Progress for Plan ${selectedPlan['plan_id']}',
                                    (selectedPlan['progress'] ?? 0) / 100,
                                    '${selectedPlan['progress']}% Completed',
                                    Colors.blueAccent,
                                  );
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
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
                  _buildQuickActionButton(Icons.add_task, 'Youtube', () {
                    _launchYouTube('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
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
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _currentMotivationalMessage,
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
