// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_import

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting

// Represents a single Feedback entry
class FeedbackData {
  final String feedbackId;
  final String userId;
  final String submittedAt;
  final String? category;
  final String feedbackText;
  String status; // Can be changed (Pending/Reviewed)

  FeedbackData({
    required this.feedbackId,
    required this.userId,
    required this.submittedAt,
    this.category,
    required this.feedbackText,
    required this.status,
  });

  // Factory constructor to create FeedbackData from a JSON map
  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      feedbackId: json['feedback_id'],
      userId: json['user_id'],
      submittedAt: json['submitted_at'],
      category: json['category'],
      feedbackText: json['feedback_text'],
      status: json['status'],
    );
  }
}

// Custom DataTableSource to provide data to PaginatedDataTable
class FeedbackDataSource extends DataTableSource {
  List<FeedbackData> _feedbacks;
  String _filterQuery = '';
  String? _filterStatus;
  String? _filterCategory;
  Function(FeedbackData feedback)? onToggleStatus; // Callback to handle status change

  FeedbackDataSource(this._feedbacks, {this.onToggleStatus});

  void filter({String? query, String? status, String? category}) {
    _filterQuery = query?.toLowerCase() ?? _filterQuery;
    _filterStatus = status;
    _filterCategory = category;
    notifyListeners(); // Rebuild the table with filtered data
  }

  List<FeedbackData> get _filteredFeedbacks {
    List<FeedbackData> filtered = _feedbacks.where((feedback) {
      bool matchesQuery = _filterQuery.isEmpty ||
                          feedback.feedbackId.toLowerCase().contains(_filterQuery) ||
                          feedback.userId.toLowerCase().contains(_filterQuery) ||
                          feedback.feedbackText.toLowerCase().contains(_filterQuery) ||
                          (feedback.category?.toLowerCase().contains(_filterQuery) ?? false) ||
                          feedback.status.toLowerCase().contains(_filterQuery);

      bool matchesStatus = _filterStatus == null || _filterStatus!.isEmpty || feedback.status == _filterStatus;
      bool matchesCategory = _filterCategory == null || _filterCategory!.isEmpty || feedback.category == _filterCategory;

      return matchesQuery && matchesStatus && matchesCategory;
    }).toList();
    
    // Sort by submitted_at by default (most recent first)
    filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return filtered;
  }

  void sort<T>(Comparable<T>? getField(FeedbackData d), bool ascending) {
    _filteredFeedbacks.sort((a, b) {
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
    if (index >= _filteredFeedbacks.length) {
      return null;
    }
    final feedback = _filteredFeedbacks[index];
    final bool isPending = feedback.status == 'Pending';

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (isPending) return Colors.yellow.withOpacity(0.1); // Light yellow for pending
        return null; // Use default row color for reviewed
      }),
      cells: [
        DataCell(Text(feedback.feedbackId)),
        DataCell(Text(feedback.userId)),
        DataCell(Text(feedback.submittedAt)),
        DataCell(Text(feedback.category ?? 'N/A')),
        DataCell(Text(feedback.feedbackText)),
        DataCell(
          Row(
            children: [
              Chip(
                label: Text(feedback.status),
                backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                labelStyle: TextStyle(
                  color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _filteredFeedbacks.length;

  @override
  int get selectedRowCount => 0;
}

class AdminFeedbackOverview extends StatefulWidget {
  const AdminFeedbackOverview({super.key});

  @override
  State<AdminFeedbackOverview> createState() => _AdminFeedbackOverviewState();
}

class _AdminFeedbackOverviewState extends State<AdminFeedbackOverview> {
  late FeedbackDataSource _feedbackDataSource;
  List<FeedbackData> _allFeedbacks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedStatusFilter;
  String? _selectedCategoryFilter;

  // For demonstration, use a placeholder. In a real app, get this from auth.
  final String _loggedInAdminUserId = 'U001';

  static const String _backendBaseUrl = 'http://10.0.2.2:5000'; // Adjust as needed

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() {
      _isLoading = true;
    });

    final uri = Uri.parse('$_backendBaseUrl/api/feedback');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        _allFeedbacks = jsonList.map((json) => FeedbackData.fromJson(json)).toList();
      } else {
        print('Failed to load feedbacks: Status Code ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load feedbacks: ${response.statusCode}')),
        );
        _allFeedbacks = [];
      }
    } catch (e) {
      print('Network error fetching feedbacks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e. Please ensure the backend server is running and accessible.')),
      );
      _allFeedbacks = [];
    } finally {
      if (mounted) {
        setState(() {
          _feedbackDataSource = FeedbackDataSource(
            _allFeedbacks,
            onToggleStatus: (feedback) {
              _toggleFeedbackStatus(feedback);
            },
          );
          _isLoading = false;
          // Apply current filters after data is loaded
          _feedbackDataSource.filter(
            query: _searchQuery,
            status: _selectedStatusFilter,
            category: _selectedCategoryFilter,
          );
        });
      }
    }
  }

  Future<void> _toggleFeedbackStatus(FeedbackData feedback) async {
    final newStatus = feedback.status == 'Pending' ? 'Reviewed' : 'Pending';
    final uri = Uri.parse('$_backendBaseUrl/api/feedback/${feedback.feedbackId}/status');

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admin_user_id': _loggedInAdminUserId,
          'new_status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback status updated to $newStatus!')),
        );
        // Optimistically update the UI, then re-fetch for consistency
        setState(() {
          feedback.status = newStatus;
          _feedbackDataSource.notifyListeners(); // Notify data source of change
        });
        _fetchFeedbacks(); // Re-fetch all data to ensure filters and sorting are correct
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to update feedback status.';
        print('Failed to update status: Status Code ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Network error updating feedback status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e. Please ensure the backend server is running and accessible.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get unique categories for the filter dropdown
    Set<String> uniqueCategories = _allFeedbacks.map((fb) => fb.category ?? '').where((c) => c.isNotEmpty).toSet();
    List<String> categories = ['All', ...uniqueCategories.toList()..sort()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Overview'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight * 2), // Increased height for filters
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search feedback...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _feedbackDataSource.filter(
                        query: _searchQuery,
                        status: _selectedStatusFilter,
                        category: _selectedCategoryFilter,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _selectedStatusFilter ?? 'All',
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatusFilter = newValue == 'All' ? null : newValue;
                            _feedbackDataSource.filter(
                              query: _searchQuery,
                              status: _selectedStatusFilter,
                              category: _selectedCategoryFilter,
                            );
                          });
                        },
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Reviewed', child: Text('Reviewed')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _selectedCategoryFilter ?? 'All',
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategoryFilter = newValue == 'All' ? null : newValue;
                            _feedbackDataSource.filter(
                              query: _searchQuery,
                              status: _selectedStatusFilter,
                              category: _selectedCategoryFilter,
                            );
                          });
                        },
                        items: categories.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allFeedbacks.isEmpty && _searchQuery.isEmpty && _selectedStatusFilter == null && _selectedCategoryFilter == null
              ? const Center(child: Text('No feedback submitted yet.'))
              : _feedbackDataSource.rowCount == 0
                ? const Center(child: Text('No matching feedback found for the current filters.'))
                : RefreshIndicator(
                    onRefresh: _fetchFeedbacks,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: PaginatedDataTable(
                          header: const Text('All User Feedback'),
                          rowsPerPage: 10,
                          source: _feedbackDataSource,
                          columnSpacing: 20,
                          horizontalMargin: 10,
                          showCheckboxColumn: false,
                          columns: [
                            DataColumn(
                              label: const Text('Feedback ID', style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (columnIndex, ascending) {
                                _feedbackDataSource.sort<String>((fb) => fb.feedbackId, ascending);
                              },
                            ),
                            DataColumn(
                              label: const Text('User ID', style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (columnIndex, ascending) {
                                _feedbackDataSource.sort<String>((fb) => fb.userId, ascending);
                              },
                            ),
                            DataColumn(
                              label: const Text('Submitted At', style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (columnIndex, ascending) {
                                _feedbackDataSource.sort<String>((fb) => fb.submittedAt, ascending);
                              },
                            ),
                            DataColumn(
                              label: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (columnIndex, ascending) {
                                _feedbackDataSource.sort<String>((fb) => fb.category, ascending);
                              },
                            ),
                            DataColumn(
                              label: const Text('Feedback Text', style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (columnIndex, ascending) {
                                _feedbackDataSource.sort<String>((fb) => fb.feedbackText, ascending);
                              },
                            ),
                            DataColumn(
                              label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                              onSort: (columnIndex, ascending) {
                                _feedbackDataSource.sort<String>((fb) => fb.status, ascending);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
    );
  }
}