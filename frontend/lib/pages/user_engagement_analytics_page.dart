import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting

class UserEngagementAnalyticsPage extends StatefulWidget {
  const UserEngagementAnalyticsPage({super.key});

  @override
  State<UserEngagementAnalyticsPage> createState() => _UserEngagementAnalyticsPageState();
}

class _UserEngagementAnalyticsPageState extends State<UserEngagementAnalyticsPage> {
  static const String _backendBaseUrl = 'http://10.0.2.2:5000';
  bool _isLoading = true;
  Map<String, dynamic> _engagementData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEngagementData();
  }

  Future<void> _fetchEngagementData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final uri = Uri.parse('$_backendBaseUrl/api/analytics/user_engagement');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _engagementData = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Failed to fetch engagement data.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e. Please ensure the backend server is running.';
        _isLoading = false;
      });
      print('Error fetching user engagement data: $e');
    }
  }

  Widget _buildMetricCard(String title, String value, Color color, {IconData? icon}) {
    return Card(
      elevation: 6, // Increased elevation for a more modern look
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // More rounded corners
      child: Container(
        decoration: BoxDecoration(
          // Subtle gradient background
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
            children: [
              if (icon != null) ...[
                Icon(icon, size: 36, color: Colors.white.withOpacity(0.9)), // White icon with transparency
                const SizedBox(height: 10),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600, // Slightly bolder
                  color: Colors.white.withOpacity(0.8), // Lighter text color
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32, // Larger font size for value
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Pure white for value
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black26,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0), // More vertical spacing
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22, // Larger section title
          fontWeight: FontWeight.bold,
          color: Color(0xFF424242), // Darker grey for better contrast
        ),
      ),
    );
  }

  // Helper to build a styled data row for lists
  Widget _buildDataRow(String label, String value, {Color valueColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Engagement Analytics'),
        backgroundColor: const Color(0xFF673AB7), // Deeper purple for AppBar
        foregroundColor: Colors.white,
        elevation: 0, // Remove shadow for a flatter look
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEngagementData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7))) // Purple loading indicator
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 70), // Larger error icon
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _fetchEngagementData,
                          icon: const Icon(Icons.replay),
                          label: const Text('Try Again', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: const Color(0xFF673AB7),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // More rounded button
                            elevation: 5, // Button elevation
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0), // Increased overall padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Overall Activity'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.8, // Adjusted to make cards taller
                        crossAxisSpacing: 20, // Increased spacing
                        mainAxisSpacing: 20, // Increased spacing
                        children: [
                          _buildMetricCard('Total Logins', '${_engagementData['overall_logins'] ?? 0}', Colors.indigo, icon: Icons.login),
                          _buildMetricCard('Total Logouts', '${_engagementData['overall_logouts'] ?? 0}', Colors.deepOrange, icon: Icons.logout),
                          _buildMetricCard('Unique Users Overall', '${_engagementData['unique_users_overall'] ?? 0}', Colors.teal, icon: Icons.people),
                        ],
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle('Recent Activity Metrics'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.8, // Adjusted to make cards taller
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: [
                          _buildMetricCard('Logins (Last 30 Min)', '${_engagementData['logins_last_30_minutes'] ?? 0}', Colors.purple.shade400, icon: Icons.timer),
                          _buildMetricCard('Logouts (Last 30 Min)', '${_engagementData['logouts_last_30_minutes'] ?? 0}', Colors.red.shade400, icon: Icons.timer_off),
                          _buildMetricCard('Logins (Last 24 Hours)', '${_engagementData['logins_last_24_hours'] ?? 0}', Colors.blue.shade600, icon: Icons.watch_later),
                          _buildMetricCard('Logouts (Last 24 Hours)', '${_engagementData['logouts_last_24_hours'] ?? 0}', Colors.pink.shade600, icon: Icons.exit_to_app),
                          _buildMetricCard('Unique Users (Last 24 Hours)', '${_engagementData['unique_users_24h'] ?? 0}', Colors.green.shade600, icon: Icons.person_add),
                          _buildMetricCard('Logins (Last 7 Days)', '${_engagementData['logins_last_7_days'] ?? 0}', Colors.indigo.shade600, icon: Icons.calendar_today),
                          _buildMetricCard('Logouts (Last 7 Days)', '${_engagementData['logouts_last_7_days'] ?? 0}', Colors.deepOrange.shade600, icon: Icons.event_busy),
                          _buildMetricCard('Unique Users (Last 7 Days)', '${_engagementData['unique_users_7d'] ?? 0}', Colors.brown.shade600, icon: Icons.group),
                        ],
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle('Top 5 Users by Logins'),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: (_engagementData['top_users_by_logins'] as List?)?.length ?? 0,
                            itemBuilder: (context, index) {
                              final user = _engagementData['top_users_by_logins'][index];
                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                                      child: Text(
                                        '#${index + 1}',
                                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      'User ID: ${user['user_id']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    trailing: Text(
                                      '${user['login_count']} logins',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                    ),
                                  ),
                                  if (index < ((_engagementData['top_users_by_logins'] as List?)?.length ?? 0) - 1)
                                    const Divider(indent: 72, endIndent: 16), // Add divider between items
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle('Hourly Login/Logout Trends (Last 24 Hours)'),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataRow('Time', 'Logins | Logouts', valueColor: Colors.black),
                              const Divider(height: 1, color: Colors.grey),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (_engagementData['hourly_trends'] as List?)?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final trend = _engagementData['hourly_trends'][index];
                                  return _buildDataRow(
                                    trend['hour'].toString(),
                                    '${trend['logins']} | ${trend['logouts']}',
                                    valueColor: trend['logins'] > 0 ? Colors.blue.shade700 : Colors.black54,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle('Daily Login/Logout Trends (Last 7 Days)'),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataRow('Date', 'Logins | Logouts', valueColor: Colors.black),
                              const Divider(height: 1, color: Colors.grey),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (_engagementData['daily_trends'] as List?)?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final trend = _engagementData['daily_trends'][index];
                                  final formattedDate = DateFormat('MMM dd').format(DateTime.parse(trend['date']));
                                  return _buildDataRow(
                                    formattedDate,
                                    '${trend['logins']} | ${trend['logouts']}',
                                    valueColor: trend['logins'] > 0 ? Colors.blue.shade700 : Colors.black54,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}
