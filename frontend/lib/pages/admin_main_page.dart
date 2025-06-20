import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for json decoding
import 'fitness_page_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _username = 'Admin';
  bool _isLoading = true;
  int _totalUsers = 0; // This will now be dynamic, fetched from the backend
  int _activeUsers = 0; // Can be made dynamic later
  int _pendingFeedbacks = 12; // Can be made dynamic later
  int _reportsGenerated = 8; // Can be made dynamic later

  // IMPORTANT: Set this to the correct IP address/hostname of your backend server.
  // - For Android Emulator connected to your local machine: 'http://10.0.2.2:5000'
  // - For iOS Simulator / Desktop App (running on the same machine as backend): 'http://127.0.0.1:5000'
  // - For a physical device on the same local network: 'http://YOUR_MACHINE_IP_ADDRESS:5000'
  //   (e.g., 'http://192.168.1.5:5000')
  static const String _backendBaseUrl = 'http://10.0.2.2:5000'; // Default for Android Emulator

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // --- MODIFIED FUNCTION: Fetch total users from backend API ---
  Future<int> _fetchTotalUsersFromDatabase() async {
    final uri = Uri.parse('$_backendBaseUrl/api/users/count');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Decode the JSON response
        final Map<String, dynamic> data = json.decode(response.body);
        // Ensure the key matches what your backend sends ('total_users')
        if (data.containsKey('total_users') && data['total_users'] is int) {
          return data['total_users'] as int;
        } else {
          throw const FormatException('Invalid or missing "total_users" in API response.');
        }
      } else {
        // Handle server errors (e.g., 404, 500)
        print('Failed to load user count: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load user count from API: Status ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors (e.g., server not reachable, no internet)
      print('Network error fetching user count: $e');
      throw Exception('Network error: $e. Please ensure the backend server is running and accessible.');
    }
  }

  Future<void> _loadAdminData() async {
    try {
      // Fetch dynamic total users from the backend API
      final totalUsersCount = await _fetchTotalUsersFromDatabase();

      // Simulate other data fetches if they were also dynamic
      await Future.delayed(const Duration(milliseconds: 500)); // Shorter delay for other data

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) { // Ensure the widget is still mounted before calling setState
        setState(() {
          _username = prefs.getString('username') ?? 'Admin';
          _totalUsers = totalUsersCount; // Assign the dynamic count here
          _activeUsers = 89; // Still hardcoded for now, but can be fetched dynamically
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error, e.g., show an error message to the user
      print('Error loading admin data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading even if there's an error
          _totalUsers = 0; // Set to 0 or display an error state if data couldn't be loaded
        });
        // Optionally show a SnackBar or AlertDialog to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      // Assuming '/login' is a named route in your app's main.dart
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // Admin-specific card widget for System Overview
  Widget _adminOverviewCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // Module card widget where features are tappable
  Widget _buildHierarchyModuleCard(
      String title, IconData icon, Color color, List<Map<String, dynamic>> features) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Iterate through features to create tappable list items
            ...features.map((feature) => Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
                      title: Text(feature['name'] as String),
                      onTap: feature['onTap'] as VoidCallback?,
                      dense: true, // Make the ListTile more compact
                    ),
                    // Add a divider between items, but not after the last one
                    if (features.last != feature)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  // Helper function to show a simple dialog for demonstration
  void _showFeatureComingSoon(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(featureName),
          content: Text('This feature ($featureName) is coming soon!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
                  const SizedBox(height: 24),

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
                      // Total Users is now dynamic, fetched from backend
                      _adminOverviewCard(Icons.people, 'Total Users', '$_totalUsers', Colors.blue),
                      _adminOverviewCard(Icons.person, 'Active Users', '$_activeUsers', Colors.green),
                      _adminOverviewCard(Icons.feedback, 'Pending Feedbacks', '$_pendingFeedbacks', Colors.orange),
                      _adminOverviewCard(Icons.bar_chart, 'Reports Generated', '$_reportsGenerated', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // User Management Module
                  const Text(
                    'User Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard(
                    'User Management',
                    Icons.manage_accounts,
                    Colors.blue,
                    [
                      {
                        'name': 'Registered User Overview',
                        'onTap': () => Navigator.pushNamed(context, '/admin_registered_user_overview')
                      },
                      {
                        'name': 'User Activity Monitoring',
                        'onTap': () => Navigator.pushNamed(context, '/admin_user_activity_monitoring')
                      },
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content Management Module
                  const Text(
                    'Content Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard(
                    'Content Management',
                    Icons.dashboard_customize,
                    Colors.teal,
                    [
                      {
                        'name': 'Exercise Library Management',
                        'onTap': () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FitnessPageManagementPage(),
                          ),
                        ),
                      },
                      {
                        'name': 'Recipe Library Management',
                        'onTap': () => _showFeatureComingSoon('Recipe Library Management')
                      },
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Feedback Management Module
                  const Text(
                    'Feedback Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard(
                    'Feedback Management',
                    Icons.feedback,
                    Colors.green,
                    [
                      {'name': 'Feedback Overview', 'onTap': () => Navigator.pushNamed(context, '/admin_feedback_overview')},
                      {'name': 'Feedback Engagement', 'onTap': () => _showFeatureComingSoon('Feedback Engagement')},
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Data Analytic and Report Module
                  const Text(
                    'Data Analytic and Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard(
                    'Data Analytic and Report',
                    Icons.analytics,
                    Colors.purple,
                    [
                      {
                        'name': 'User Engagement Data Analytics',
                        'onTap': () => _showFeatureComingSoon('User Engagement Data Analytics')
                      },
                      {
                        'name': 'User Fitness Progress Data Analytics',
                        'onTap': () => _showFeatureComingSoon('User Fitness Progress Data Analytics')
                      },
                      {
                        'name': 'User Dietary Habit Data Analytics',
                        'onTap': () => _showFeatureComingSoon('User Dietary Habit Data Analytics')
                      },
                      {
                        'name': 'Report Generation',
                        'onTap': () => _showFeatureComingSoon('Report Generation')
                      },
                    ],
                  ),
                  const SizedBox(height: 24),

                  // System Settings Module
                  const Text(
                    'System Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard(
                    'System Settings',
                    Icons.settings,
                    Colors.orange,
                    [
                      {
                        'name': 'Access Control Configuration',
                        'onTap': () => _showFeatureComingSoon('Access Control Configuration')
                      },
                      {
                        'name': 'System Notifications',
                        'onTap': () => _showFeatureComingSoon('System Notifications')
                      },
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
}