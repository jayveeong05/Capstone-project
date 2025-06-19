import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _username = 'Admin';
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _pendingFeedbacks = 12;
  int _reportsGenerated = 8;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    // Simulating API calls to get admin data
    await Future.delayed(const Duration(seconds: 1));
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Admin';
      _totalUsers = 142;
      _activeUsers = 89;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // Admin-specific card widget
  Widget _adminCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(String title, IconData icon, Color color, List<String> features) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.circle, size: 8),
                  const SizedBox(width: 8),
                  Text(feature),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with welcome message
                  Text(
                    'Welcome, $_username',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // System Overview Cards
                  const Text(
                    'System Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _adminCard(Icons.people, 'Total Users', '$_totalUsers', Colors.blue),
                      _adminCard(Icons.person, 'Active Users', '$_activeUsers', Colors.green),
                      _adminCard(Icons.feedback, 'Pending Feedbacks', '$_pendingFeedbacks', Colors.orange),
                      _adminCard(Icons.bar_chart, 'Reports Generated', '$_reportsGenerated', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Module
                  const Text(
                    'Action Module',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleCard(
                    'User Management',
                    Icons.manage_accounts,
                    Colors.blue,
                    [
                      'User Accounts Management',
                      'Role & Permissions Management',
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Feedback Management
                  const Text(
                    'Feedback Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleCard(
                    'Feedback System',
                    Icons.feedback,
                    Colors.green,
                    [
                      'Feedback Overview Dashboard',
                      'Feedback Response & Engagement',
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Data Analysis and Report
                  const Text(
                    'Data Analysis and Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleCard(
                    'Analytics & Reporting',
                    Icons.analytics,
                    Colors.purple,
                    [
                      'User Engagement Analytics',
                      'User Progress Reports',
                      'Group Tracking & Evaluation',
                      'Automated Report Generation',
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // System Settings
                  const Text(
                    'System Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleCard(
                    'Configuration',
                    Icons.settings,
                    Colors.orange,
                    [
                      'Access Control Configuration',
                      'System Notification Settings',
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Content Management
                  const Text(
                    'Content Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildUtilityCard(
                        Icons.fitness_center,
                        'Workout Plan Management',
                        Colors.deepPurple,
                        () {},
                      ),
                      _buildUtilityCard(
                        Icons.restaurant_menu,
                        'Diet Plan Management',
                        Colors.teal,
                        () {},
                      ),
                      _buildUtilityCard(
                        Icons.video_library,
                        'Exercise Library',
                        Colors.redAccent,
                        () {},
                      ),
                      _buildUtilityCard(
                        Icons.menu_book,
                        'Meal Library',
                        Colors.deepOrange,
                        () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}