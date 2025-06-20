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

  @override
  void initState() {
    super.initState();
    // Add a welcome message when the page loads
    _messages.add({
      'role': 'bot',
      'text': "👋 Hi! I'm your AI Coach. Ask me anything about workouts or diet to get started."
    });
  }

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

  Widget _buildMessage(Map<String, String> msg) {
    bool isBot = msg['role'] == 'bot';
    return Row(
      mainAxisAlignment:
          isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBot)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 4.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.smart_toy, color: Colors.deepPurple),
            ),
          ),
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isBot ? Colors.grey[200] : Colors.blue[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(isBot ? 0 : 16),
                bottomRight: Radius.circular(isBot ? 16 : 0),
              ),
            ),
            child: Text(
              msg['text'] ?? '',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
        if (!isBot)
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 4.0, top: 4.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue[400],
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                )),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        _sendMessage(_controller.text.trim());
                        _controller.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}