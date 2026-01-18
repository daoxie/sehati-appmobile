class ChatContactModel {
  String id; // ID of the other user
  String name; // Name of the other user
  String imageUrl; // Profile picture of the other user
  String latestMessage;
  String latestTimestamp;
  String chatRoomId; // The ID of the chat room
  ChatUser otherUser; // The full ChatUser object of the other user

  ChatContactModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.latestMessage,
    required this.latestTimestamp,
    required this.chatRoomId,
    required this.otherUser,
  });
}

class MessageModel {
  String text;
  String timestamp;
  bool isSentByMe;
  bool isImage;

  MessageModel({
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.isImage = false,
  });
}

class ChatUser {
  final String uid;
  final String username;
  final String? profilePictureUrl;
  final String? bio;

  ChatUser({
    required this.uid,
    required this.username,
    this.profilePictureUrl,
    this.bio,
  });

  factory ChatUser.fromMap(Map<String, dynamic> data, {required String documentId}) {
    return ChatUser(
      uid: (data['uid'] as String?) ?? documentId,
      username: data['username'] as String? ?? 'Unknown User',
      profilePictureUrl: data['profilePictureUrl'] as String?,
      bio: data['bio'] as String?,
    );
  }
}
