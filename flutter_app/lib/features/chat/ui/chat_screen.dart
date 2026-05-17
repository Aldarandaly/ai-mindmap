import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/api_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();

  String username = '';

  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final name = await ApiClient().getUserName();

    setState(() {
      username = name ?? 'User';

      messages = [
        {"role": "ai", "message": "Hello $username, How can I help you?"},
      ];
    });
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text;

    // show user message instantly
    setState(() {
      messages.add({"role": "user", "message": text});
    });

    controller.clear();

    try {
      final response = await ApiClient().post(
        "/chat/send",
        data: {"project_id": 1, "message": text},
      );

      setState(() {
        messages.add({
          "role": "ai",
          "message": response['reply'] ?? "AI response",
        });
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "message": "Something went wrong"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Chat")),

      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                bool isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),

                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],

                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Text(
                      msg['message']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input
          Padding(
            padding: const EdgeInsets.all(12),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,

                    decoration: InputDecoration(
                      hintText: "Ask AI...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
