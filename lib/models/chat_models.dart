class ChatContactModel {
  String id;
  String name;
  String imageUrl;
  String latestMessage;
  String latestTimestamp;

  ChatContactModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.latestMessage,
    required this.latestTimestamp,
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
