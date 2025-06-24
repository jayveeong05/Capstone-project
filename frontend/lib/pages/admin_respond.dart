import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminRespondPage extends StatefulWidget {
  const AdminRespondPage({Key? key}) : super(key: key);

  @override
  _AdminRespondPageState createState() => _AdminRespondPageState();
}

class _AdminRespondPageState extends State<AdminRespondPage> {
  List<dynamic> feedbackList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/admin/feedbacks'));

    if (response.statusCode == 200) {
      setState(() {
        feedbackList = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load feedbacks.")),
      );
    }
  }

  Future<void> _submitResponse(String feedbackId, String userId, String responseText) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/admin/respond-feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'feedback_id': feedbackId,
        'user_id': userId,
        'response_text': responseText,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Response submitted")),
      );
      _fetchFeedbacks(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to submit response")),
      );
    }
  }

  void _showRespondDialog(Map<String, dynamic> feedback) {
    final TextEditingController _responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Write a Response"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${feedback['category']}"),
            const SizedBox(height: 8),
            Text("Feedback: ${feedback['feedback_text']}"),
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write your response here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitResponse(feedback['feedback_id'], feedback['user_id'], _responseController.text);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Respond to Feedback"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final feedback = feedbackList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("Category: ${feedback['category']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("From User ID: ${feedback['user_id']}"),
                        Text("Submitted: ${feedback['submitted_at']}"),
                        const SizedBox(height: 6),
                        Text("Message: ${feedback['feedback_text']}"),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showRespondDialog(feedback),
                      child: const Text("Respond"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
