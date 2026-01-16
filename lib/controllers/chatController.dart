import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../models/chat_models.dart';

class ChatController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  final List<ChatContactModel> chatContacts = [
    ChatContactModel(
      id: '1',
      name: 'Jane Doe',
      imageUrl: 'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200',
      latestMessage: 'Hey, how are you?',
      latestTimestamp: '10:30 AM',
    ),
    ChatContactModel(
      id: '2',
      name: 'John Smith',
      imageUrl: 'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200',
      latestMessage: 'See you tomorrow!',
      latestTimestamp: 'Yesterday',
    ),
  ];

  final List<MessageModel> _messages = [
    MessageModel(
      text: 'Hey, how are you?',
      timestamp: '10:30 AM',
      isSentByMe: false,
    ),
    MessageModel(
      text: 'I am good, thanks! How about you?',
      timestamp: '10:31 AM',
      isSentByMe: true,
    ),
  ];

  List<MessageModel> get messages => _messages;

  void sendMessage(String text) {
    if (text.isEmpty) return;

    final message = MessageModel(
      text: text,
      timestamp: '10:32 AM', // Dummy timestamp
      isSentByMe: true,
    );
    _messages.add(message);
    notifyListeners();
    _simulateReply();
  }

  Future<void> pickAndSendImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final message = MessageModel(
        text: pickedFile.path,
        timestamp: '10:33 AM', // Dummy timestamp
        isSentByMe: true,
        isImage: true,
      );
      _messages.add(message);
      notifyListeners();
      _simulateReply();
    }
  }

  Future<void> takeAndSendImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final message = MessageModel(
        text: pickedFile.path,
        timestamp: '10:33 AM', // Dummy timestamp
        isSentByMe: true,
        isImage: true,
      );
      _messages.add(message);
      notifyListeners();
      _simulateReply();
    }
  }

  void _simulateReply() {
    Timer(const Duration(seconds: 2), () {
      final reply = MessageModel(
        text: 'Awesome!',
        timestamp: '10:34 AM', // Dummy timestamp
        isSentByMe: false,
      );
      _messages.add(reply);
      notifyListeners();
    });
  }
}
