import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
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

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Align(
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
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Builder(
                                  builder: (context) {
                                    try {
                                      return Image.memory(
                                        base64Decode(message.text),
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 200,
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Gagal memuat gambar',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                      );
                                    } catch (e) {
                                      return Container(
                                        width: 200,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Format gambar tidak valid',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              )
                            : Text(message.text),
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
