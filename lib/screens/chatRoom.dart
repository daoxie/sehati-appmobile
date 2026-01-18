import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chatController.dart';
import '../models/chat_models.dart'; 

class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context); // Get controller instance

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName), // Use receiverName
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatController.getMessages(widget.receiverId), // Stream messages
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada pesan. Kirim yang pertama!'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildChatBubble(message);
                  },
                );
              },
            ),
          ),
          _buildInputPanel(context, chatController), // Pass chatController to input panel
        ],
      ),
    );
  }

  Widget _buildChatBubble(MessageModel message) {
    final isMe = message.isSentByMe; 
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: message.isImage
            ? Image.network(message.text, width: 200) // Display image from URL
            : Text(
                '${message.text} (${message.timestamp})', // Display message and timestamp
                style: const TextStyle(fontSize: 16.0),
              ),
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, ChatController controller) { // Added ChatController parameter
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.green),
            onPressed: () {
              controller.takeAndSendImage(widget.receiverId); // Call takeAndSendImage
            },
          ),
          IconButton(
            icon: const Icon(Icons.image, color: Colors.green),
            onPressed: () {
              controller.pickAndSendImage(widget.receiverId); // Call pickAndSendImage
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                controller.sendMessage(_textController.text, widget.receiverId); // Pass receiverId
                _textController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12.0),
            ),
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
