import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for json decoding

// Represents a single user object
class UserData {
  final String userId;
  final String username;
  final String email;
  final String role; // Assuming role is a string like 'Admin', 'User', 'Banned'
  final String? fullName;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? location;
  final String? profilePicture; // This would typically be a URL or base64 string

  UserData({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.fullName,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.bmi,
    this.location,
    this.profilePicture,
  });

  // Factory constructor to create UserData from a JSON map (e.g., from backend)
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      // The backend now returns role as 'Admin', 'User', or 'Banned' string
      role: json['role'],
      fullName: json['full_name'],
      age: json['age'],
      gender: json['gender'],
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      location: json['location'],
      profilePicture: json['profile_picture'],
    );
  }
}

// Custom DataTableSource to provide data to PaginatedDataTable
class UserDataSource extends DataTableSource {
  List<UserData> _users;
  String _filter = '';
  Function(UserData user)? onViewUser;
  Function(UserData user)? onEditUser;
  Function(UserData user)? onDeleteUser; // NEW: Callback for delete action

  UserDataSource(this._users, {this.onViewUser, this.onEditUser, this.onDeleteUser}); // MODIFIED

  void filterUsers(String query) {
    _filter = query.toLowerCase();
    notifyListeners(); // Rebuild the table with filtered data
  }

  // Returns the filtered list of users
  List<UserData> get _filteredUsers {
    if (_filter.isEmpty) {
      return _users;
    } else {
      return _users.where((user) {
        return user.userId.toLowerCase().contains(_filter) ||
               user.username.toLowerCase().contains(_filter) ||
               user.email.toLowerCase().contains(_filter) ||
               user.role.toLowerCase().contains(_filter) ||
               (user.fullName?.toLowerCase().contains(_filter) ?? false) ||
               (user.location?.toLowerCase().contains(_filter) ?? false);
      }).toList();
    }
  }

  // Sorts the users based on the given column and ascending order
  void sort<T>(Comparable<T>? getField(UserData d), bool ascending) {
    _filteredUsers.sort((a, b) {
      final Comparable<T>? aValue = getField(a);
      final Comparable<T>? bValue = getField(b);

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;

      final int comparisonResult = aValue.compareTo(bValue as T);
      return ascending ? comparisonResult : -comparisonResult;
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _filteredUsers.length) {
      return null;
    }
    final user = _filteredUsers[index];
    return DataRow(
      cells: [
        DataCell(Text(user.userId)),
        DataCell(Text(user.username)),
        DataCell(Text(user.email)),
        DataCell(Text(user.role)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                tooltip: 'View User',
                onPressed: () => onViewUser?.call(user),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.green),
                tooltip: 'Edit User',
                onPressed: () => onEditUser?.call(user),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: 'Delete User',
                onPressed: () {
                  // Call the onDeleteUser callback when the delete button is pressed
                  onDeleteUser?.call(user); // MODIFIED
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _filteredUsers.length;

  @override
  int get selectedRowCount => 0;
}

class AdminRegisteredUserOverview extends StatefulWidget {
  const AdminRegisteredUserOverview({super.key});

  @override
  State<AdminRegisteredUserOverview> createState() => _AdminRegisteredUserOverviewState();
}

class _AdminRegisteredUserOverviewState extends State<AdminRegisteredUserOverview> {
  late UserDataSource _userDataSource;
  List<UserData> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // IMPORTANT: Replace with the actual user ID of the logged-in administrator.
  // This should come from your app's state management after a successful admin login.
  // For demonstration purposes, 'U001' is used as a placeholder.
  final String _loggedInAdminUserId = 'U001'; // Ensure this is dynamically set after login

  static const String _backendBaseUrl = 'http://10.0.2.2:5000'; // Adjust as needed for your Flask server

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    final uri = Uri.parse('$_backendBaseUrl/api/users');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        _allUsers = jsonList.map((json) => UserData.fromJson(json)).toList();
      } else {
        print('Failed to load users: Status Code ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: ${response.statusCode}')),
        );
        _allUsers = [];
      }
    } catch (e) {
      print('Network error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e. Please ensure the backend server is running and accessible.')),
      );
      _allUsers = [];
    } finally {
      if (mounted) {
        setState(() {
          _userDataSource = UserDataSource(
            _allUsers,
            onViewUser: (user) {
              _showUserDetailDialog(user, 'View');
            },
            onEditUser: (user) {
              _showUserDetailDialog(user, 'Edit');
            },
            // Pass the _confirmAndDeleteUser method to the UserDataSource
            onDeleteUser: (user) {
              _confirmAndDeleteUser(user);
            },
          );
          _isLoading = false;
          _userDataSource.filterUsers(_searchQuery);
        });
      }
    }
  }

  // NEW: Method to confirm and delete user
  Future<void> _confirmAndDeleteUser(UserData user) async {
    // Prevent an admin from deleting another admin or themselves
    if (user.role == 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete an administrator account.')),
      );
      return;
    }
    if (user.userId == _loggedInAdminUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete user "${user.username}" (ID: ${user.userId})? This action cannot be undone and will delete ALL associated data.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false; // In case the dialog is dismissed by tapping outside

    if (confirm) {
      _deleteUser(user.userId);
    }
  }

  // NEW: Method to delete user via API
  Future<void> _deleteUser(String userIdToDelete) async {
    final uri = Uri.parse('$_backendBaseUrl/api/users/$userIdToDelete');
    try {
      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admin_user_id': _loggedInAdminUserId, // Pass the logged-in admin's ID for authorization
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $userIdToDelete and all associated data deleted successfully!')),
        );
        _fetchUsers(); // Refresh the list of users after deletion
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to delete user.';
        print('Failed to delete user: Status Code ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Network error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e. Please ensure the backend server is running and accessible.')),
      );
    }
  }

  // Existing method to update user role via API (provided in previous context)
  Future<void> _updateUserRole(String userId, int newRole) async {
    // Client-side check to prevent admin from changing their own role.
    // The backend also enforces this for security.
    if (userId == _loggedInAdminUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot change your own role.')),
      );
      return;
    }
    final uri = Uri.parse('$_backendBaseUrl/api/users/$userId/role');
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admin_user_id': _loggedInAdminUserId, // Pass the logged-in admin's ID
          'new_role': newRole,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User role updated successfully!')),
        );
        Navigator.of(context).pop(); // Close the dialog
        _fetchUsers(); // Refresh the list of users
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to update user role.';
        print('Failed to update role: Status Code ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Network error updating role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  void _showUserDetailDialog(UserData user, String type) {
    // Convert role string to integer for the dropdown: 0 for Admin, 1 for User, 2 for Banned
    int? _selectedRole;
    if (user.role == 'Admin') {
      _selectedRole = 0;
    } else if (user.role == 'User') {
      _selectedRole = 1;
    } else if (user.role == 'Banned') {
      _selectedRole = 2;
    }

    // Determine if the role dropdown should be disabled
    final bool isCurrentUserBeingEdited = user.userId == _loggedInAdminUserId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use a StateSetter to update the dialog's internal state
        return StatefulBuilder(
          builder: (context, setStateSB) { // setStateSB is specific to this dialog's state
            return AlertDialog(
              title: Text('$type User: ${user.username}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('User ID: ${user.userId}'),
                    Text('Username: ${user.username}'),
                    Text('Email: ${user.email}'),
                    // Display current role (always visible)
                    Text('Current Role: ${user.role}'),
                    // Role selection for editing (only visible in 'Edit' mode)
                    if (type == 'Edit') ...[
                      const SizedBox(height: 16),
                      const Text('Change Role:'),
                      DropdownButton<int>(
                        value: _selectedRole,
                        // Disable the dropdown if the user is the currently logged-in admin
                        onChanged: isCurrentUserBeingEdited ? null : (int? newValue) {
                          if (newValue != null) {
                            setStateSB(() { // Use setStateSB to update dialog's state
                              _selectedRole = newValue;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text('User'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Banned'),
                          ),
                        ],
                      ),
                    ],
                    // Display other profile details if available
                    if (user.fullName != null && user.fullName!.isNotEmpty) Text('Full Name: ${user.fullName}'),
                    if (user.age != null) Text('Age: ${user.age}'),
                    if (user.gender != null && user.gender!.isNotEmpty) Text('Gender: ${user.gender}'),
                    if (user.height != null) Text('Height: ${user.height} cm'),
                    if (user.weight != null) Text('Weight: ${user.weight} kg'),
                    if (user.bmi != null) Text('BMI: ${user.bmi?.toStringAsFixed(2)}'),
                    if (user.location != null && user.location!.isNotEmpty) Text('Location: ${user.location}'),
                    // Add more fields as needed based on your UserData model
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                if (type == 'Edit')
                  TextButton(
                    child: const Text('Save Changes'),
                    onPressed: () {
                      if (_selectedRole != null) {
                        _updateUserRole(user.userId, _selectedRole!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a role.')),
                        );
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered User Overview'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _userDataSource.filterUsers(_searchQuery);
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Users',
                hintText: 'Search by User ID, Username, Email, Role, etc.',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // Added RefreshIndicator for easy data refresh
              onRefresh: _fetchUsers,
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  header: const Text('All Registered Users'),
                  rowsPerPage: 10,
                  columns: [
                        DataColumn(
                          label: const Text('User ID', style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (columnIndex, ascending) {
                            _userDataSource.sort<String>((user) => user.userId, ascending);
                          },
                        ),
                        DataColumn(
                          label: const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (columnIndex, ascending) {
                            _userDataSource.sort<String>((user) => user.username, ascending);
                          },
                        ),
                        DataColumn(
                          label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (columnIndex, ascending) {
                            _userDataSource.sort<String>((user) => user.email, ascending);
                          },
                        ),
                        DataColumn(
                          label: const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                          onSort: (columnIndex, ascending) {
                            _userDataSource.sort<String>((user) => user.role, ascending);
                          },
                        ),
                        const DataColumn(
                          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                  source: _userDataSource,
                ),
              ),
      ),
    );
  }
}