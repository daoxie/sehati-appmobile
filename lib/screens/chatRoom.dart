import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/chatController.dart';
import '/models/chatModels.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverId;
  final String receiverName;
  final ChatUser otherUser;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.receiverId,
    required this.receiverName,
    required this.otherUser,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Panggilan Suara',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur panggilan suara segera hadir!'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur video call segera hadir!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatController.getMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Kirim pesan pertama Anda!'));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Pesan'),
                            content: const Text(
                              'Yakin ingin menghapus pesan ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  chatController.deleteMessage(
                                    widget.chatRoomId,
                                    message.messageId,
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pesan dihapus'),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Align(
                        alignment: message.isSentByMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: message.isSentByMe
                                ? Colors.blue[100]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: message.isImage
                              ? Image.network(message.text, width: 150)
                              : Text(message.text),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan Anda...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  tooltip: 'Kirim Gambar',
                  onPressed: () => chatController.pickAndSendImage(
                    widget.chatRoomId,
                    widget.receiverId,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Ambil Foto',
                  onPressed: () => chatController.takeAndSendImage(
                    widget.chatRoomId,
                    widget.receiverId,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () {
                    chatController.sendMessage(
                      _messageController.text,
                      widget.chatRoomId,
                      widget.receiverId,
                    );
                    _messageController.clear();
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
