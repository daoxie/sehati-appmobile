import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ChatContactModel>> getChatContacts() {
    final String? currentUserId = _auth.currentUser?.uid;
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final userData = doc.data();
        return ChatContactModel(
          id: userData['uid'] ?? '',
          name: userData['name'] ?? 'No Name',
          imageUrl: userData['imageUrl'] ?? 'https://www.gravatar.com/avatar/?d=mp',
          latestMessage: '', 
          latestTimestamp: '',
        );
      }).toList();
    });
  }

  Stream<List<MessageModel>> getMessages(String receiverId) {
    final String? senderId = _auth.currentUser?.uid;
    if (senderId == null) {
      return Stream.value([]);
    }

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        String formattedTimestamp = '...';
        if (data['timestamp'] != null) {
            final timestamp = (data['timestamp'] as Timestamp).toDate().toLocal();
            formattedTimestamp = "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
        }
        
        return MessageModel(
          text: data['text'] ?? '',
          timestamp: formattedTimestamp,
          isSentByMe: data['senderId'] == senderId,
          isImage: data['isImage'] ?? false,
        );
      }).toList();
    });
  }

  void sendMessage(String text, String receiverId, {bool isImage = false}) async {
    if (text.isEmpty) return;

    final String? senderId = _auth.currentUser?.uid;
    if (senderId == null) {
      print('Error: User not logged in.');
      return;
    }

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    Map<String, dynamic> messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': isImage,
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);
  }

  Future<void> _uploadImageAndSend(XFile? pickedFile, String receiverId) async {
    if (pickedFile == null) return;

    final String? senderId = _auth.currentUser?.uid;
    if (senderId == null) {
      print('Error: User not logged in.');
      return;
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final Reference storageRef = _firebaseStorage.ref().child('chat_images').child(senderId).child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      sendMessage(downloadUrl, receiverId, isImage: true);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> pickAndSendImage(String receiverId) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    await _uploadImageAndSend(pickedFile, receiverId);
  }

  Future<void> takeAndSendImage(String receiverId) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    await _uploadImageAndSend(pickedFile, receiverId);
  }
}
