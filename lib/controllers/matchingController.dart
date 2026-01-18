import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';

class MatchingController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  List<ChatUser> _profiles = []; // Renamed from _usersToMatch
  bool _isLoading = false;
  String? _errorMessage;
  List<ChatUser> _allAvailableProfiles = []; // Renamed from _allAvailableUsers

  // New: Callback for when a match is found
  Function? onMatchFound;
  ChatUser? _lastMatchedUser; // To store the user that was just matched

  List<ChatUser> get profiles => _profiles; // Renamed getter
  ChatUser? get lastMatchedUser => _lastMatchedUser; // Getter for the last matched user
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => _currentUser?.uid; // New getter for current user's UID
  String? get currentMatchChatRoomId { // New getter for chatRoomId after a match
    if (_currentUser != null && _lastMatchedUser != null) {
      return _generateChatRoomId(_currentUser!.uid, _lastMatchedUser!.uid);
    }
    return null;
  }

  MatchingController() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      loadProfiles(); // Call loadProfiles from constructor
    }
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        loadProfiles();
      } else {
        _profiles = [];
        _allAvailableProfiles = [];
        _lastMatchedUser = null;
        notifyListeners();
      }
    });
  }

  // Renamed _fetchUsersToMatch to loadProfiles
  Future<void> loadProfiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentUser == null) {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      print('Current User UID: ${_currentUser!.uid}');

      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      print('Total documents in "users" collection: ${usersSnapshot.docs.length}');

      List<ChatUser> fetchedAllUsers = [];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('Warning: Document ${doc.id} has no data and will be skipped.');
          continue;
        }
        fetchedAllUsers.add(ChatUser.fromMap(data, documentId: doc.id));
      }
      print('Valid ChatUsers parsed from DB (including current user): ${fetchedAllUsers.length}');

      // Filter out the current user and store as all available users
      _allAvailableProfiles = fetchedAllUsers
          .where((user) => user.uid != _currentUser!.uid)
          .toList();
      print('All available users (excluding current user): ${_allAvailableProfiles.length}');

      // Get already swiped users by current user (both liked and disliked)
      QuerySnapshot swipedUsersSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('swipes')
          .get();
      Set<String> swipedUserIds = swipedUsersSnapshot.docs.map((doc) => doc.id).toSet();
      print('Users already swiped by current user: ${swipedUserIds.length}');

      // Filter out already swiped users for the initial load
      _profiles = _allAvailableProfiles
          .where((user) => !swipedUserIds.contains(user.uid))
          .toList();
      print('Profiles to match initially (not yet swiped): ${_profiles.length}');

      if (_profiles.isEmpty) {
        // If no new profiles, display all available profiles again (reset)
        print('No new profiles. Resetting cards from all available users.');
        _profiles = List.from(_allAvailableProfiles); // Populate with all users
        if (_profiles.isEmpty) {
          _errorMessage = 'Tidak ada pengguna baru untuk dicocokkan.';
        }
      } else {
          _errorMessage = 'Semua pengguna sudah di-swipe. Kartu akan diulang.'; // Inform user
        }

    } catch (e) {
      _errorMessage = 'Error fetching profiles: $e';
      print('Error fetching profiles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New swipe methods for manual implementation
  Future<void> swipeRight(String profileId) async {
    await _handleSwipe(profileId, true);
  }

  Future<void> swipeLeft(String profileId) async {
    await _handleSwipe(profileId, false);
  }

  Future<void> _handleSwipe(String profileId, bool isLiked) async {
    if (_currentUser == null) {
      _errorMessage = 'User not logged in.';
      notifyListeners();
      return;
    }

    ChatUser? swipedUser;
    try {
      swipedUser = _profiles.firstWhere((user) => user.uid == profileId);
    } catch (e) {
      print('Error: Profile with ID $profileId not found in current profiles.');
      return;
    }

    try {
      // Record the swipe action
      await _firestore.collection('users').doc(_currentUser!.uid).collection('swipes').doc(swipedUser.uid).set({
        'liked': isLiked,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isLiked) {
        // Check if the swiped user has also liked the current user
        DocumentSnapshot swipedUserSwipeDoc = await _firestore.collection('users').doc(swipedUser.uid).collection('swipes').doc(_currentUser!.uid).get();

        if (swipedUserSwipeDoc.exists && (swipedUserSwipeDoc.data() as Map<String, dynamic>)['liked'] == true) {
          // It's a match!
          await _createMatch(swipedUser);
          _lastMatchedUser = swipedUser; // Store the matched user
          _errorMessage = 'It\'s a Match with ${swipedUser.username}!'; // Use errorMessage to show match status
          onMatchFound?.call(); // Trigger the callback
        }
      }
      
      // Remove the swiped user from the list
      _profiles.removeWhere((user) => user.uid == swipedUser.uid);
      if (_profiles.isEmpty) {
        print('All cards swiped. Resetting cards from all available users.');
        _profiles = List.from(_allAvailableProfiles); // Reset cards
        if (_profiles.isEmpty) {
          _errorMessage = 'Tidak ada pengguna baru untuk dicocokkan.'; // Still empty, no users at all
        }
      } else {
          _errorMessage = 'Semua pengguna sudah di-swipe. Kartu akan diulang.'; // Inform user
        }
    } catch (e) {
      _errorMessage = 'Error performing swipe action: $e';
      print('Error performing swipe action: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _createMatch(ChatUser matchedUser) async {
    if (_currentUser == null) return;

    String chatRoomId = _generateChatRoomId(_currentUser!.uid, matchedUser.uid);

    // Add to current user's matches
    await _firestore.collection('users').doc(_currentUser!.uid).collection('matches').doc(matchedUser.uid).set({
      'matchedAt': FieldValue.serverTimestamp(),
      'chatRoomId': chatRoomId,
      'otherUserId': matchedUser.uid,
    });

    // Add to matched user's matches
    await _firestore.collection('users').doc(matchedUser.uid).collection('matches').doc(_currentUser!.uid).set({
      'matchedAt': FieldValue.serverTimestamp(),
      'chatRoomId': chatRoomId,
      'otherUserId': _currentUser!.uid,
    });

    // Create a chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'users': [_currentUser!.uid, matchedUser.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Match baru! Sapa dia sekarang.',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _generateChatRoomId(String uid1, String uid2) {
    // Ensure consistent chat room ID regardless of user order
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // Helper to clear error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}