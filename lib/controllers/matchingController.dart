import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MatchingController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of profiles to display in the matching queue
  List<DocumentSnapshot> _profiles = [];
  List<DocumentSnapshot> get profiles => _profiles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VoidCallback? onMatchFound;

  MatchingController() {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        _errorMessage = "User not logged in.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Fetch current user's profile and preferences
      final DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) {
        _errorMessage = "Current user profile not found.";
        _isLoading = false;
        notifyListeners();
        return;
      }
      final Map<String, dynamic> currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      final String? searchGender = currentUserData['searchGender'];
      final int? minAge = currentUserData['minAge'];
      final int? maxAge = currentUserData['maxAge'];
      final String? currentUserGender = currentUserData['gender'];

      // 2. Fetch users current user has already liked/disliked
      final QuerySnapshot likedUsersSnapshot = await _firestore.collection('users').doc(currentUserId).collection('likes').get();
      final List<String> likedUserIds = likedUsersSnapshot.docs.map((doc) => doc.id).toList();

      final QuerySnapshot dislikedUsersSnapshot = await _firestore.collection('users').doc(currentUserId).collection('dislikes').get();
      final List<String> dislikedUserIds = dislikedUsersSnapshot.docs.map((doc) => doc.id).toList();

      final List<String> excludedUserIds = [...likedUserIds, ...dislikedUserIds, currentUserId];

      // 3. Construct the query for potential matches
      Query query = _firestore.collection('users');

      // Filter by gender preference
      if (searchGender != null && searchGender != 'Semua') {
        query = query.where('gender', isEqualTo: searchGender);
      } else if (currentUserGender != null) {
        // If current user is looking for 'Semua' or has no preference,
        // still make sure not to show users of the same gender if not desired
        // (This is a simplified logic, can be made more complex)
        // For now, if 'Semua', show all genders. If current user has gender,
        // and searchGender is null/empty, assume they want opposite gender.
        // This needs to be refined based on actual app logic.
      }

      // Filter by age range
      // Age calculation based on DOB (assuming 'dob' is stored as 'dd MMMM yyyy')
      // This part is tricky and often better handled with calculated age fields or server-side functions.
      // For a client-side filter, we would fetch all and then filter.
      // Firebase doesn't allow range queries on non-indexed fields or complex client-side calculations efficiently.
      // For now, let's fetch all eligible by gender and then filter by age on client side.

      final QuerySnapshot potentialMatchesSnapshot = await query.get();
      
      List<DocumentSnapshot> allPotentialProfiles = potentialMatchesSnapshot.docs;
      
      // Client-side filtering for age and exclusion
      _profiles = allPotentialProfiles.where((doc) {
        if (excludedUserIds.contains(doc.id)) {
          return false;
        }

        final Map<String, dynamic> targetUserData = doc.data() as Map<String, dynamic>;
        final String? targetUserDobString = targetUserData['dob'];
        
        if (targetUserDobString != null && minAge != null && maxAge != null) {
          try {
            final DateTime targetUserDob = DateFormat('dd MMMM yyyy').parse(targetUserDobString);
            final int targetUserAge = (DateTime.now().difference(targetUserDob).inDays / 365).floor();
            if (targetUserAge < minAge || targetUserAge > maxAge) {
              return false;
            }
          } catch (e) {
            print("Error parsing DOB for user ${doc.id}: $e");
            return false; // Exclude if DOB parsing fails
          }
        }
        return true;
      }).toList();

      _profiles.shuffle(); // Shuffle the profiles for variety

    } catch (e) {
      _errorMessage = "Failed to load profiles: $e";
      print("Error loading profiles: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Placeholder for swipe actions
  Future<void> swipeLeft(String profileId) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).collection('dislikes').doc(profileId).set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Remove from _profiles list
      _profiles.removeWhere((profile) => profile.id == profileId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to record dislike: $e";
      print("Error recording dislike: $e");
      notifyListeners();
    }
  }

  Future<void> swipeRight(String profileId) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).collection('likes').doc(profileId).set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Remove from _profiles list
      _profiles.removeWhere((profile) => profile.id == profileId);
      notifyListeners();

      // After liking, check for a match
      await _checkForMatch(currentUserId, profileId);

    } catch (e) {
      _errorMessage = "Failed to record like or check for match: $e";
      print("Error recording like or checking for match: $e");
      notifyListeners();
    }
  }

  // Helper function to check for a match
  Future<void> _checkForMatch(String currentUserId, String targetUserId) async {
    try {
      final targetUserLikes = await _firestore.collection('users').doc(targetUserId).collection('likes').doc(currentUserId).get();

      if (targetUserLikes.exists) {
        // It's a match!
        final matchId = _getMatchId(currentUserId, targetUserId);
        await _firestore.collection('matches').doc(matchId).set({
          'users': [currentUserId, targetUserId],
          'timestamp': FieldValue.serverTimestamp(),
          'lastMessage': '', // Initialize for chat
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
        print("Match found between $currentUserId and $targetUserId!");
        onMatchFound?.call();
        // TODO: Trigger navigation to chat or show a match dialog
      }
    } catch (e) {
      _errorMessage = "Error checking for match: $e";
      print("Error checking for match: $e");
      // Don't notifyListeners here as it might interfere with ongoing UI updates
    }
  }

  // Helper to create a consistent match ID
  String _getMatchId(String user1, String user2) {
    List<String> userIds = [user1, user2];
    userIds.sort(); // Ensure consistent order
    return userIds.join('_');
  }

  @override
  void dispose() {
    // Clean up resources if any
    super.dispose();
  }
}
