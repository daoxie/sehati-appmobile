import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '/models/chatModels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ChatContactModel>> getChatContacts() {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('matches') // Get matches for the current user
        .snapshots()
        .asyncMap((matchesSnapshot) async {
          List<ChatContactModel> contacts = [];

          for (var matchDoc in matchesSnapshot.docs) {
            final matchData = matchDoc.data();
            final String otherUserId = matchData['otherUserId'];
            final String chatRoomId = matchData['chatRoomId'];

            // Fetch the other user's profile data
            DocumentSnapshot otherUserDoc = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();
            if (otherUserDoc.exists) {
              final otherUserData = otherUserDoc.data() as Map<String, dynamic>;
              final ChatUser otherUser = ChatUser.fromMap(
                otherUserData,
                documentId: otherUserDoc.id,
              );

              // Fetch latest message from chatRoom
              DocumentSnapshot chatRoomDoc = await _firestore
                  .collection('chatRooms')
                  .doc(chatRoomId)
                  .get();
              String latestMessage = '';
              String latestTimestamp = '';

              if (chatRoomDoc.exists) {
                final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
                latestMessage = chatRoomData['lastMessage'] ?? '';
                final Timestamp? lastMessageTime =
                    chatRoomData['lastMessageTime'] as Timestamp?;
                if (lastMessageTime != null) {
                  final dateTime = lastMessageTime.toDate().toLocal();
                  latestTimestamp =
                      "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
                }
              }

              contacts.add(
                ChatContactModel(
                  id: otherUser.uid,
                  name: otherUser.username,
                  imageUrl:
                      otherUser.imageUrl ??
                      'https://www.gravatar.com/avatar/?d=mp',
                  latestMessage: latestMessage,
                  latestTimestamp: latestTimestamp,
                  chatRoomId: chatRoomId,
                  otherUser: otherUser,
                ),
              );
            }
          }
          return contacts;
        });
  }

  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    // Updated to use chatRoomId directly
    final String? senderId = _auth.currentUser?.uid;
    if (senderId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chatRooms') // Messages are now under chatRooms
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            String formattedTimestamp = '...';
            if (data['timestamp'] != null) {
              final timestamp = (data['timestamp'] as Timestamp)
                  .toDate()
                  .toLocal();
              formattedTimestamp =
                  "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
            }

            return MessageModel(
              messageId: doc.id,
              text: data['text'] ?? '',
              timestamp: formattedTimestamp,
              isSentByMe: data['senderId'] == senderId,
              isImage: data['isImage'] ?? false,
            );
          }).toList();
        });
  }

  void sendMessage(
    String text,
    String chatRoomId,
    String receiverId, {
    bool isImage = false,
  }) async {
    if (text.isEmpty) return;

    final String? senderId = _auth.currentUser?.uid;
    if (senderId == null) {
      print('Error: User not logged in.');
      return;
    }

    Map<String, dynamic> messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': isImage,
    };

    print('Sending message: isImage=$isImage, text length=${text.length}');

    // Add message to the specific chat room's messages subcollection
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update lastMessage and lastMessageTime in the chatRoom document
    // Untuk gambar, tampilkan "[Gambar]" bukan URL
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'lastMessage': isImage ? '[Gambar]' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('Message sent successfully');
  }

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  Future<void> _uploadImageAndSend(
    XFile? pickedFile,
    String chatRoomId,
    String receiverId,
  ) async {
    if (pickedFile == null) return;

    final String? senderId = _auth.currentUser?.uid;
    if (senderId == null) {
      print('Error: User not logged in.');
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      // Baca gambar sebagai bytes dan konversi ke base64
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('Image converted to base64, size: ${bytes.length} bytes');

      // Kirim base64 sebagai pesan
      sendMessage(base64Image, chatRoomId, receiverId, isImage: true);
      print('Image message sent successfully');
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndSendImage(String chatRoomId, String receiverId) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress untuk ukuran lebih kecil
      maxWidth: 800,
    );
    await _uploadImageAndSend(pickedFile, chatRoomId, receiverId);
  }

  Future<void> takeAndSendImage(String chatRoomId, String receiverId) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Compress untuk ukuran lebih kecil
      maxWidth: 800,
    );
    await _uploadImageAndSend(pickedFile, chatRoomId, receiverId);
  }

  /// Hapus pesan individual dari chat room
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      print('Message deleted: $messageId');
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  /// Hapus chat dan semua data terkait dari Firebase
  Future<void> deleteChat(String chatRoomId, String otherUserId) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('Error: User not logged in.');
      return;
    }

    try {
      // 1. Hapus semua pesan di chatRoom
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Hapus dokumen chatRoom
      await _firestore.collection('chatRooms').doc(chatRoomId).delete();

      // 3. Hapus match dari current user
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('matches')
          .doc(otherUserId)
          .delete();

      // 4. Hapus match dari other user
      await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('matches')
          .doc(currentUserId)
          .delete();

      print('Chat deleted successfully: $chatRoomId');
      notifyListeners();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }
}
