import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  final String userId;
  const ChatbotPage({required this.userId});
  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  Future<void> _sendMessage(String text) async {
    setState(() => _messages.add({'role': 'user', 'text': text}));
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/chatbot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.userId, 'message': text}),
    );
    final data = jsonDecode(response.body);
    setState(() => _messages.add({'role': 'bot', 'text': data['reply'] ?? 'No response'}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _messages.map((msg) => ListTile(
                leading: msg['role'] == 'bot' ? Icon(Icons.smart_toy) : null,
                trailing: msg['role'] == 'user' ? Icon(Icons.person) : null,
                title: Text(msg['text'] ?? ''),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      _sendMessage(_controller.text.trim());
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}