import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chatController.dart';
import '../models/chat_models.dart';
import 'chatRoom.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<List<ChatContactModel>>(
        stream: chatController.getChatContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada kontak untuk ditampilkan.'));
          }

          final chatContacts = snapshot.data!;

          return ListView.builder(
            itemCount: chatContacts.length,
            itemBuilder: (context, index) {
              final contact = chatContacts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(contact.imageUrl),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.latestMessage), // Re-enabled
                  trailing: Text(contact.latestTimestamp), // Re-enabled
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatRoomId: contact.chatRoomId, // Pass chatRoomId
                          receiverId: contact.id, // Pass the receiver ID
                          receiverName: contact.name, // Pass the receiver name for AppBar title
                          otherUser: contact.otherUser, // Pass the full otherUser object
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
