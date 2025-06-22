import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminSendNotificationPage extends StatefulWidget {
  @override
  _AdminSendNotificationPageState createState() => _AdminSendNotificationPageState();
}

class _AdminSendNotificationPageState extends State<AdminSendNotificationPage> {
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedType;
  bool _isSending = false;

  final List<String> _types = ['system update', 'system maintenance'];

  Future<void> _sendNotification() async {
    if (_selectedType == null || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a type and write the details")),
      );
      return;
    }

    setState(() => _isSending = true);

    final uri = Uri.parse('http://10.0.2.2:5000/admin/send-notification');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': _selectedType,
        'details': _detailsController.text,
      }),
    );

    setState(() => _isSending = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Notification sent!")),
      );
      _detailsController.clear();
      setState(() => _selectedType = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send notification")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send System Notification")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _types.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              decoration: InputDecoration(labelText: "Notification Type"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _detailsController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  labelText: "Notification Details (like email content)",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotification,
              icon: Icon(Icons.send),
              label: Text(_isSending ? "Sending..." : "Send to All Users"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
