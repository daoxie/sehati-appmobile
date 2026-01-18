import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/matchingController.dart';
import '../models/chat_models.dart';
import 'chatRoom.dart'; // Import ChatRoomScreen

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Alignment> _animation;
  Alignment _dragAlignment = Alignment.center;
  double _rotation = 0.0;
  double _opacity = 1.0;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<MatchingController>(context, listen: false);
      controller.loadProfiles();
      // Register callback for match found
      controller.onMatchFound = () {
        // Use a post-frame callback to ensure navigation happens after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if the user is still on the matching screen before showing dialog/navigating
          if (mounted) {
            final matchedUser = controller.lastMatchedUser;
            if (matchedUser != null) {
              // Retrieve chatRoomId (assuming it's available after match creation)
              // This might need to be passed back from _createMatch or fetched again
              // For now, let's assume it's created and can be derived.
              // A more robust solution might pass the chatRoomId directly in the onMatchFound callback.
              String chatRoomId = _generateChatRoomId(controller._currentUser!.uid, matchedUser.uid);

              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('It\'s a Match!'),
                    content: Text('You matched with ${matchedUser.username}!'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Start Chat'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          // Navigate to chat room
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                chatRoomId: chatRoomId,
                                receiverId: matchedUser.uid,
                                receiverName: matchedUser.username,
                                otherUser: matchedUser,
                              ),
                            ),
                          );
                          controller.clearErrorMessage(); // Clear message after action
                        },
                      ),
                      TextButton(
                        child: const Text('Keep Swiping'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          controller.clearErrorMessage(); // Clear message after action
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
        });
      };
    });
  }

  // Helper function to generate chatRoomId (duplicated from controller for UI nav)
  String _generateChatRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _runAnimation(Offset pixelsPerSecond, Size size) {
    _animation = _animationController.drive(
      AlignmentTween(
        begin: _dragAlignment,
        end: Alignment.center,
      ),
    );
    _animationController.reset();
    _animationController.forward();
  }

  void _onPanStart(DragStartDetails details) {
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragAlignment += Alignment(
        details.delta.dx / (_screenSize.width / 2),
        details.delta.dy / (_screenSize.height / 2),
      );

      _rotation = -_dragAlignment.x * 0.2; // Max rotation 20 degrees
      _opacity = 1 - (_dragAlignment.x.abs() + _dragAlignment.y.abs()) / 2; // Fade out

      if (_opacity < 0) _opacity = 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final controller = Provider.of<MatchingController>(context, listen: false);
    if (controller.profiles.isEmpty) { // Prevent interaction if no profiles
      _resetCardPosition();
      return;
    }
    final ChatUser currentProfile = controller.profiles.first; // Get current profile here

    const double swipeThreshold = 0.4; // Percentage of screen width to swipe

    if (_dragAlignment.x.abs() > swipeThreshold || _dragAlignment.y.abs() > swipeThreshold) {
      // Swiped far enough - animate it off screen
      _animation = _animationController.drive(
        AlignmentTween(
          begin: _dragAlignment,
          end: Alignment(
            _dragAlignment.x > 0 ? 5.0 : -5.0, // Fly off screen right or left
            _dragAlignment.y + (_dragAlignment.y > 0 ? 2.0 : -2.0), // A bit more vertical
          ),
        ),
      );
      _animationController.forward().then((_) {
        // After animation completes, perform the action and reset
        if (_dragAlignment.x > 0) {
          controller.swipeRight(currentProfile.uid); // Use uid
        } else {
          controller.swipeLeft(currentProfile.uid); // Use uid
        }
        _resetCardPosition();
      });
    } else {
      // Not swiped far enough, snap back to center
      _runAnimation(details.velocity.pixelsPerSecond, _screenSize);
      setState(() {
        _rotation = 0.0;
        _opacity = 1.0;
      });
    }
  }

  void _resetCardPosition() {
    setState(() {
      _dragAlignment = Alignment.center;
      _rotation = 0.0;
      _opacity = 1.0;
    });
  }
  
  // Helper to build a single profile card
  // Updated to accept ChatUser instead of DocumentSnapshot
  Widget _buildProfileCard(ChatUser profile, {bool isCurrent = true}) {
    final String name = profile.username;
    final String username = profile.username; // Assuming username is also the display name for @
    final String? imageUrl = profile.profilePictureUrl;
    // Assuming you don't have gender or dob in ChatUser model now.
    // If you need them, you'll have to add them to ChatUser model and Firestore data.

    ImageProvider profileImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        if (imageUrl.startsWith('http')) {
          profileImage = NetworkImage(imageUrl);
        } else {
          profileImage = MemoryImage(base64Decode(imageUrl));
        }
      } catch (e) {
        profileImage = const NetworkImage('https://www.gravatar.com/avatar/?d=mp');
      }
    } else {
      profileImage = const NetworkImage('https://www.gravatar.com/avatar/?d=mp');
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: profileImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
              },
            ),
          ),
          // Gradient overlay for better text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withAlpha((255 * 0.7).round())],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, // Removed age for simplicity, as it's not in ChatUser
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@$username', // Removed gender for simplicity
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withAlpha((255 * 0.8).round()),
                  ),
                ),
                Text(
                  profile.bio ?? 'No bio available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha((255 * 0.8).round()),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tambahkan fungsi untuk load lebih banyak profile jika habis
  void _checkAndReloadProfiles(MatchingController controller) {
    if (controller.profiles.length <= 1) {
      controller.loadProfiles(); // Pastikan loadProfiles bisa fetch data baru/infinite
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching'),
        backgroundColor: Colors.pink,
      ),
      body: Consumer<MatchingController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && !controller.errorMessage!.startsWith('It\'s a Match')) {
            return Center(child: Text(controller.errorMessage!));
          }

          if (controller.profiles.isEmpty) {
            return const Center(child: Text('No more profiles to show.'));
          }

          return Stack(
            children: [
              // Next card (scaled down and slightly behind)
              if (controller.profiles.length > 1)
                Align(
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: 0.93, // Slightly smaller next card
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildProfileCard(controller.profiles[1], isCurrent: false), // Pass ChatUser
                    ),
                  ),
                ),
              // Current card
              Align(
                alignment: _animationController.isAnimating
                    ? _animation.value
                    : _dragAlignment,
                child: Transform.rotate(
                  angle: _rotation,
                  child: Opacity(
                    opacity: _opacity,
                    child: SizedBox(
                      width: _screenSize.width * 0.85, // Smaller width
                      height: _screenSize.height * 0.65, // Smaller height
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: _buildProfileCard(controller.profiles.first), // Pass ChatUser
                      ),
                    ),
                  ),
                ),
              ),
              // Swipe buttons
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'dislikeBtn',
                        onPressed: () {
                          final controller = Provider.of<MatchingController>(context, listen: false);
                          controller.swipeLeft(controller.profiles.first.uid);
                          _resetCardPosition();
                          _checkAndReloadProfiles(controller);
                        },
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      FloatingActionButton(
                        heroTag: 'likeBtn',
                        onPressed: () async {
                          final controller = Provider.of<MatchingController>(context, listen: false);
                          final ChatUser likedUser = controller.profiles.first;
                          await controller.swipeRight(likedUser.uid); // Swipe right

                          // Buat chat room dan kirim pesan otomatis
                          String chatRoomId = _generateChatRoomId(controller.currentUser!.uid, likedUser.uid);
                          await controller.createChatRoomIfNotExists(chatRoomId, likedUser.uid);
                          await controller.sendMessage(chatRoomId, likedUser.uid, "Hai, saya suka profil kamu!");

                          _resetCardPosition();
                          _checkAndReloadProfiles(controller);
                        },
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
