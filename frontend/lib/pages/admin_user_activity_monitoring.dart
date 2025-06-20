import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Represents a single SystemLog entry
class SystemLogData {
  final String logEntryId;
  final String? userId; // Can be null for system-level actions
  final String action;
  final String timestamp;
  final String? details; // Can be null

  SystemLogData({
    required this.logEntryId,
    this.userId,
    required this.action,
    required this.timestamp,
    this.details,
  });

  // Factory constructor to create SystemLogData from a JSON map
  factory SystemLogData.fromJson(Map<String, dynamic> json) {
    return SystemLogData(
      logEntryId: json['log_entry_id'],
      userId: json['user_id'],
      action: json['action'],
      timestamp: json['timestamp'],
      details: json['details'],
    );
  }
}

// Custom DataTableSource to provide data to PaginatedDataTable
class SystemLogDataSource extends DataTableSource {
  List<SystemLogData> _logs;
  String _filter = '';

  SystemLogDataSource(this._logs);

  void filterLogs(String query) {
    _filter = query.toLowerCase();
    notifyListeners(); // Rebuild the table with filtered data
  }

  List<SystemLogData> get _filteredLogs {
    if (_filter.isEmpty) {
      return _logs;
    } else {
      return _logs.where((log) {
        return log.logEntryId.toLowerCase().contains(_filter) ||
               (log.userId?.toLowerCase().contains(_filter) ?? false) ||
               log.action.toLowerCase().contains(_filter) ||
               log.timestamp.toLowerCase().contains(_filter) ||
               (log.details?.toLowerCase().contains(_filter) ?? false);
      }).toList();
    }
  }

  void sort<T>(Comparable<T>? getField(SystemLogData d), bool ascending) {
    _filteredLogs.sort((a, b) {
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
    if (index >= _filteredLogs.length) {
      return null;
    }
    final log = _filteredLogs[index];
    return DataRow(
      cells: [
        DataCell(Text(log.logEntryId)),
        DataCell(Text(log.userId ?? 'N/A')), // Display N/A if userId is null
        DataCell(Text(log.action)),
        DataCell(Text(log.timestamp)),
        DataCell(Text(log.details ?? 'No details')), // Display 'No details' if null
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _filteredLogs.length;

  @override
  int get selectedRowCount => 0;
}

class AdminUserActivityMonitoring extends StatefulWidget {
  const AdminUserActivityMonitoring({super.key});

  @override
  State<AdminUserActivityMonitoring> createState() => _AdminUserActivityMonitoringState();
}

class _AdminUserActivityMonitoringState extends State<AdminUserActivityMonitoring> {
  late SystemLogDataSource _logDataSource;
  List<SystemLogData> _allLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const String _backendBaseUrl = 'http://10.0.2.2:5000'; // Adjust as needed

  @override
  void initState() {
    super.initState();
    _fetchSystemLogs();
  }

  Future<void> _fetchSystemLogs() async {
    setState(() {
      _isLoading = true;
    });

    final uri = Uri.parse('$_backendBaseUrl/api/systemlogs');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        _allLogs = jsonList.map((json) => SystemLogData.fromJson(json)).toList();
      } else {
        print('Failed to load system logs: Status Code ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load system logs: ${response.statusCode}')),
        );
        _allLogs = [];
      }
    } catch (e) {
      print('Network error fetching system logs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e. Please ensure the backend server is running and accessible.')),
      );
      _allLogs = [];
    } finally {
      if (mounted) {
        setState(() {
          _logDataSource = SystemLogDataSource(_allLogs);
          _isLoading = false;
          _logDataSource.filterLogs(_searchQuery); // Apply filter after fetching
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activity Monitoring'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _logDataSource.filterLogs(_searchQuery);
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Activities',
                hintText: 'Search by User ID, Action, Details, etc.',
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
          : RefreshIndicator(
              onRefresh: _fetchSystemLogs,
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  header: const Text('System Activities Log'),
                  rowsPerPage: 10,
                  columns: [
                    DataColumn(
                      label: const Text('Log ID', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (columnIndex, ascending) {
                        _logDataSource.sort<String>((log) => log.logEntryId, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('User ID', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (columnIndex, ascending) {
                        _logDataSource.sort<String>((log) => log.userId, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (columnIndex, ascending) {
                        _logDataSource.sort<String>((log) => log.action, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (columnIndex, ascending) {
                        _logDataSource.sort<String>((log) => log.timestamp, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (columnIndex, ascending) {
                        _logDataSource.sort<String>((log) => log.details, ascending);
                      },
                    ),
                  ],
                  source: _logDataSource,
                ),
              ),
            ),
    );
  }
}