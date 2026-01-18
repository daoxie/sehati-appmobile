import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/matchingController.dart';
import 'chatList.dart'; // Import ChatListScreen

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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        });
      };
    });
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
    final currentProfile = controller.profiles.first;

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
          controller.swipeRight(currentProfile.id);
        } else {
          controller.swipeLeft(currentProfile.id);
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
  Widget _buildProfileCard(DocumentSnapshot profileDoc, {bool isCurrent = true}) {
    final Map<String, dynamic> profileData = profileDoc.data() as Map<String, dynamic>;
    final String name = profileData['name'] ?? 'No Name';
    final String username = profileData['username'] ?? 'No Username';
    final String? imageUrl = profileData['imageUrl']; // Base64 image data

    ImageProvider profileImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(imageUrl));
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image(
              image: profileImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 80));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '@$username',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                // Add more profile details here if desired
              ],
            ),
          ),
        ],
      ),
    );
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

          if (controller.errorMessage != null) {
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
                    scale: 0.95,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildProfileCard(controller.profiles[1], isCurrent: false),
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
                      width: _screenSize.width * 0.9,
                      height: _screenSize.height * 0.7,
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: _buildProfileCard(controller.profiles.first),
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
                          controller.swipeLeft(controller.profiles.first.id);
                          _resetCardPosition();
                        },
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      FloatingActionButton(
                        heroTag: 'likeBtn',
                        onPressed: () {
                          controller.swipeRight(controller.profiles.first.id);
                          _resetCardPosition();
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