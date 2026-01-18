/// Model untuk representasi user dalam sistem chat/matching
class ChatUser {
  final String uid;
  final String username;
  final String? imageUrl;
  final String? gender;
  final String? dob;
  final String? bio;

  ChatUser({
    required this.uid,
    required this.username,
    this.imageUrl,
    this.gender,
    this.dob,
    this.bio,
  });

  factory ChatUser.fromMap(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    return ChatUser(
      uid: documentId,
      username: data['name'] ?? 'No Name',
      imageUrl: data['imageUrl'],
      gender: data['gender'],
      dob: data['dob'],
      bio: data['bio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': username,
      'imageUrl': imageUrl,
      'gender': gender,
      'dob': dob,
      'bio': bio,
    };
  }
}

/// Model untuk kontak dalam daftar chat
class ChatContactModel {
  final String name;
  final String imageUrl;
  final String latestMessage;
  final String latestTimestamp;
  final String chatRoomId;
  final String id;
  final ChatUser otherUser;

  ChatContactModel({
    required this.name,
    required this.imageUrl,
    required this.latestMessage,
    required this.latestTimestamp,
    required this.chatRoomId,
    required this.id,
    required this.otherUser,
  });
}

/// Model untuk pesan dalam chat room
class MessageModel {
  final String messageId;
  final bool isSentByMe;
  final String text;
  final bool isImage;
  final String timestamp;

  MessageModel({
    required this.messageId,
    required this.isSentByMe,
    required this.text,
    required this.isImage,
    required this.timestamp,
  });
}
