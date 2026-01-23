import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/chatModels.dart';
import '/models/genderModel.dart';

class MatchingController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  List<ChatUser> _profiles = []; // Renamed from _usersToMatch
  bool _isLoading = false;
  String? _errorMessage;
  List<ChatUser> _allAvailableProfiles = []; // Renamed from _allAvailableUsers
  Gender _selectedGenderFilter = Gender.semua; // Filter gender aktif

  // New: Callback for when a match is found
  Function? onMatchFound;
  ChatUser? _lastMatchedUser; // To store the user that was just matched

  List<ChatUser> get profiles => _profiles; // Renamed getter
  ChatUser? get lastMatchedUser =>
      _lastMatchedUser; // Getter for the last matched user
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Gender get selectedGenderFilter =>
      _selectedGenderFilter; // Getter untuk filter gender

  String? get currentUserId =>
      _currentUser?.uid; // New getter for current user's UID
  String? get currentMatchChatRoomId {
    // New getter for chatRoomId after a match
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

  /// Mengatur filter gender dan memuat ulang profil
  Future<void> setGenderFilter(Gender gender) async {
    if (_selectedGenderFilter == gender) return;
    _selectedGenderFilter = gender;
    await loadProfiles(); // Reload profil dengan filter baru
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
      print(
        'Total documents in "users" collection: ${usersSnapshot.docs.length}',
      );

      List<ChatUser> fetchedAllUsers = [];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('Warning: Document ${doc.id} has no data and will be skipped.');
          continue;
        }
        fetchedAllUsers.add(ChatUser.fromMap(data, documentId: doc.id));
      }
      print(
        'Valid ChatUsers parsed from DB (including current user): ${fetchedAllUsers.length}',
      );

      // Filter out the current user and store as all available users
      _allAvailableProfiles = fetchedAllUsers
          .where((user) => user.uid != _currentUser!.uid)
          .toList();
      print(
        'All available users (excluding current user): ${_allAvailableProfiles.length}',
      );

      // Filter berdasarkan gender jika ada filter aktif
      final genderFilterString = GenderFilter.toFirebaseString(
        _selectedGenderFilter,
      );
      if (genderFilterString != null) {
        _allAvailableProfiles = _allAvailableProfiles
            .where((user) => user.gender == genderFilterString)
            .toList();
        print(
          'Filtered by gender ($genderFilterString): ${_allAvailableProfiles.length}',
        );
      }

      // Get already swiped users by current user (both liked and disliked)
      QuerySnapshot swipedUsersSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('swipes')
          .get();
      Set<String> swipedUserIds = swipedUsersSnapshot.docs
          .map((doc) => doc.id)
          .toSet();
      print('Users already swiped by current user: ${swipedUserIds.length}');

      // Filter out already swiped users for the initial load
      _profiles = _allAvailableProfiles
          .where((user) => !swipedUserIds.contains(user.uid))
          .toList();

      // Shuffle profiles untuk mengacak urutan setiap kali load
      _profiles.shuffle();

      print(
        'Profiles to match initially (not yet swiped): ${_profiles.length}',
      );

      if (_profiles.isEmpty && _allAvailableProfiles.isNotEmpty) {
        // Jika sudah swipe semua, tampilkan ulang dengan urutan acak
        print('No new profiles. Showing all users in random order.');
        _profiles = List.from(_allAvailableProfiles);
        _profiles
            .shuffle(); // Acak urutan agar tidak selalu mulai dari orang yang sama
      } else if (_profiles.isEmpty) {
        _errorMessage = 'Tidak ada pengguna untuk dicocokkan.';
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
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('swipes')
          .doc(swipedUser.uid)
          .set({
            'liked': isLiked,
            'timestamp': FieldValue.serverTimestamp(),
            'targetUserId': swipedUser
                .uid, // Ditambahkan untuk mendukung collectionGroup query
          });

      if (isLiked) {
        // Langsung Match jika kita menyukai (agar bisa langsung chat)
        await _createMatch(swipedUser);
        _lastMatchedUser = swipedUser; // Store the matched user
        // Tetap gunakan awalan "It's a Match" agar logika UI di MatchingScreen menyembunyikan pesan error ini
        _errorMessage = 'It\'s a Match with ${swipedUser.username}!';
        onMatchFound?.call(); // Trigger the callback
      }

      _profiles.removeWhere((user) => user.uid == swipedUser!.uid);
      if (_profiles.isEmpty && _allAvailableProfiles.isNotEmpty) {
        //menampilkan urutan acak
        print('Menampilkan semua pengguna dalam urutan acak');
        _profiles = List.from(_allAvailableProfiles);
        _profiles.shuffle(); //urutan acak
      } else if (_profiles.isEmpty) {
        _errorMessage = 'Tidak ada pengguna untuk dicocokkan.';
      }
    } catch (e) {
      _errorMessage = 'Error performing swipe action: $e';
      print('Eror saat melakukan aksi: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _createMatch(ChatUser matchedUser) async {
    if (_currentUser == null) return;

    String chatRoomId = _generateChatRoomId(_currentUser!.uid, matchedUser.uid);
    //match keuser kita
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('matches')
        .doc(matchedUser.uid)
        .set({
          'matchedAt': FieldValue.serverTimestamp(),
          'chatRoomId': chatRoomId,
          'otherUserId': matchedUser.uid,
        });

    //match keuser lawan
    await _firestore
        .collection('users')
        .doc(matchedUser.uid)
        .collection('matches')
        .doc(_currentUser!.uid)
        .set({
          'matchedAt': FieldValue.serverTimestamp(),
          'chatRoomId': chatRoomId,
          'otherUserId': _currentUser!.uid,
        });

    //buat room chat baru
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'users': [_currentUser!.uid, matchedUser.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Match baru! Say hay dia sekarang.',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _generateChatRoomId(String uid1, String uid2) {
    //id ruang obrolan
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
