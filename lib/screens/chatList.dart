import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/chatController.dart';
import '/models/chatModels.dart';
import 'chatRoom.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan'), backgroundColor: Colors.green),
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
            return const Center(
              child: Text('Tidak ada kontak untuk ditampilkan.'),
            );
          }

          final chatContacts = snapshot.data!;

          return ListView.builder(
            itemCount: chatContacts.length,
            itemBuilder: (context, index) {
              final contact = chatContacts[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(contact.imageUrl),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.latestMessage),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(contact.latestTimestamp),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Chat'),
                              content: Text(
                                'Yakin ingin menghapus chat dengan ${contact.name}? Semua pesan akan dihapus.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    chatController.deleteChat(
                                      contact.chatRoomId,
                                      contact.id,
                                    );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Chat dengan ${contact.name} dihapus',
                                        ),
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
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatRoomId: contact.chatRoomId,
                          receiverId: contact.id,
                          receiverName: contact.name,
                          otherUser: contact.otherUser,
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
