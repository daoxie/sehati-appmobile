import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chatController.dart';
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
      body: ListView.builder(
        itemCount: chatController.chatContacts.length,
        itemBuilder: (context, index) {
          final contact = chatController.chatContacts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(contact.imageUrl),
              ),
              title: Text(contact.name),
              subtitle: Text(contact.latestMessage),
              trailing: Text(contact.latestTimestamp),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(contact: contact),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
