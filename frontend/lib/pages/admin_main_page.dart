import 'package:flutter/material.dart';
import 'package:frontend/pages/user_engagement_analytics_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'fitness_page_management.dart';
import 'package:intl/intl.dart';

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
  int _pendingFeedbacks = 0;
  int _reportsGenerated = 0;

  static const String _backendBaseUrl = 'http://10.0.2.2:5000';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<int> _fetchTotalUsersFromDatabase() async {
    final uri = Uri.parse('$_backendBaseUrl/api/users/count');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('total_users') && data['total_users'] is int) {
          return data['total_users'] as int;
        } else {
          throw const FormatException('Invalid or missing "total_users" in API response.');
        }
      } else {
        print('Failed to load user count: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load user count from API: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Network error fetching user count: $e');
      throw Exception('Network error: $e. Please ensure the backend server is running and accessible.');
    }
  }

  Future<int> _fetchPendingFeedbacksFromDatabase() async {
    final uri = Uri.parse('$_backendBaseUrl/api/feedbacks/pending/count');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('pending_feedbacks') && data['pending_feedbacks'] is int) {
          return data['pending_feedbacks'] as int;
        } else {
          throw const FormatException('Invalid or missing "pending_feedbacks" in API response.');
        }
      } else {
        print('Failed to load pending feedbacks count: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load pending feedbacks from API: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Network error fetching pending feedbacks: $e');
      throw Exception('Network error: $e. Please ensure the backend server is running and accessible.');
    }
  }

  Future<int> _fetchReportsGeneratedFromDatabase() async {
    final uri = Uri.parse('$_backendBaseUrl/api/reports/count');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('reports_generated') && data['reports_generated'] is int) {
          return data['reports_generated'] as int;
        } else {
          throw const FormatException('Invalid or missing "reports_generated" in API response.');
        }
      } else {
        print('Failed to load reports generated count: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load reports generated from API: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Network error fetching reports generated: $e');
      throw Exception('Network error: $e. Please ensure the backend server is running and accessible.');
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

  Future<void> _loadAdminData() async {
    try {
      final totalUsersCount = await _fetchTotalUsersFromDatabase();
      final pendingFeedbacksCount = await _fetchPendingFeedbacksFromDatabase();
      final reportsGeneratedCount = await _fetchReportsGeneratedFromDatabase();
      await Future.delayed(const Duration(milliseconds: 500));
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _username = prefs.getString('username') ?? 'Admin';
          _totalUsers = totalUsersCount;
          _activeUsers = 1;
          _pendingFeedbacks = pendingFeedbacksCount;
          _reportsGenerated = reportsGeneratedCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading admin data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _totalUsers = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: ${e.toString()}')),
        );
      }
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

  Future<void> _showLogDialog() async {
  try {
    final file = File('/data/user/0/com.example.frontend/app_flutter/activity_log.txt');
    final exists = await file.exists();
    if (!exists) {
      await file.writeAsString('No log entries yet.');
    }

    final content = await file.readAsLines();

    // Only get the last 100 lines (or fewer if not enough)
    final lastLines = content.length > 100 ? content.sublist(content.length - 100) : content;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login/Logout Logs (Last 100 Lines)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(lastLines.join('\n')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              // Optional: View Full Log
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Full Log File'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 500,
                    child: SingleChildScrollView(
                      child: Text(content.join('\n')),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('View Full Log'),
          ),
        ],
      ),
    );
  } catch (e) {
    print('Error reading log file: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error reading log file: $e')),
    );
  }
}
Future<void> _showAccessControlDialog() async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Access Control Configuration'),
        content: const Text('Do you want to disable or enable the system for regular users?'),
        actions: [
          TextButton(
            child: const Text('Disable System'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _toggleSystemStatus(true); // Call function to disable
            },
          ),
          TextButton(
            child: const Text('Enable System'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _toggleSystemStatus(false); // Call function to enable
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
          ),
        ],
      );
    },
  );
}

Future<void> _toggleSystemStatus(bool disable) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final adminUserId = prefs.getInt('user_id');

  if (adminUserId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Admin User ID not found.')),
    );
    return;
  }

  final String endpoint = disable ? '/api/system/disable' : '/api/system/enable';
  final String actionText = disable ? 'disabling' : 'enabling';

  final uri = Uri.parse('$_backendBaseUrl$endpoint');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'admin_user_id': adminUserId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ System successfully $actionText.')),
      );
      // Optionally reload admin data to reflect changes if necessary
      _loadAdminData();
    } else {
      final Map<String, dynamic> data = json.decode(response.body);
      String errorMessage = data['message'] ?? data['error'] ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to $actionText system: $errorMessage')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error during system $actionText: $e')),
    );
  }
}
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

  Widget _buildHierarchyModuleCard(String title, IconData icon, Color color, List<Map<String, dynamic>> features) {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...features.map((feature) => Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
                      title: Text(feature['name'] as String),
                      onTap: feature['onTap'] as VoidCallback?,
                      dense: true,
                    ),
                    if (features.last != feature)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  void _showFeatureComingSoon(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(featureName),
          content: Text('This feature ($featureName) is coming soon!'),
          actions: [
            TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
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
          IconButton(icon: const Icon(Icons.article_outlined), onPressed: _showLogDialog),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $_username', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  const Text('System Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _adminOverviewCard(Icons.people, 'Total Users', '$_totalUsers', Colors.blue),
                      _adminOverviewCard(Icons.person, 'Active Users', '$_activeUsers', Colors.green),
                      _adminOverviewCard(Icons.feedback, 'Pending Feedbacks', '$_pendingFeedbacks', Colors.orange),
                      _adminOverviewCard(Icons.bar_chart, 'Reports Generated', '$_reportsGenerated', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text('User Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard('User Management', Icons.manage_accounts, Colors.blue, [
                    {
                      'name': 'Registered User Overview',
                      'onTap': () => Navigator.pushNamed(context, '/admin_registered_user_overview')
                    },
                    {
                      'name': 'User Activity Monitoring',
                      'onTap': () => Navigator.pushNamed(context, '/admin_user_activity_monitoring')
                    },
                  ]),

                  const SizedBox(height: 24),
                  const Text('Content Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard('Content Management', Icons.dashboard_customize, Colors.teal, [
                    {
                      'name': 'Exercise Library Management',
                      'onTap': () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FitnessPageManagementPage()),
                      ),
                    },
                    {'name': 'Recipe Library Management', 'onTap': () => _showFeatureComingSoon('Recipe Library Management')},
                  ]),

                  const SizedBox(height: 24),
                  const Text('Feedback Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard('Feedback Management', Icons.feedback, Colors.green, [
                    {'name': 'Feedback Overview', 'onTap': () => Navigator.pushNamed(context, '/admin_feedback_overview')},
                    {'name': 'Feedback Engagement', 'onTap': () => _showFeatureComingSoon('Feedback Engagement')},
                  ]),

                  const SizedBox(height: 24),
                  const Text('Data Analytic and Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard('Data Analytic and Report', Icons.analytics, Colors.purple, [
                    {
                      'name': 'User Engagement Data Analytics',
                      'onTap': () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserEngagementAnalyticsPage()),
                      ),
                    },
                    {'name': 'User Fitness Progress Data Analytics', 'onTap': () => _showFeatureComingSoon('User Fitness Progress Data Analytics')},
                    {'name': 'User Dietary Habit Data Analytics', 'onTap': () => _showFeatureComingSoon('User Dietary Habit Data Analytics')},
                    {'name': 'Report Generation', 'onTap': () => _showFeatureComingSoon('Report Generation')},
                  ]),

                  const SizedBox(height: 24),
                  const Text('System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHierarchyModuleCard('System Settings', Icons.settings, Colors.orange, [
                    {'name': 'Access Control Configuration', 'onTap': _showAccessControlDialog},
                    {'name': 'System Notifications', 'onTap': () => _showFeatureComingSoon('System Notifications')},
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
