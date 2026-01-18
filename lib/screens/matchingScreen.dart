import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/matchingController.dart';
import '/models/chatModels.dart';
import 'chatRoom.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with SingleTickerProviderStateMixin {
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

    // Memuat profil saat layar pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MatchingController>();
      controller.loadProfiles();

      // Setup listener untuk Match Found
      controller.onMatchFound = () {
        if (!mounted) return;
        final matchedUser = controller.lastMatchedUser;
        final chatRoomId = controller.currentMatchChatRoomId;

        if (matchedUser != null && chatRoomId != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("AYO CHATTING🎉"),
              content: Text("Kamu cocok dengan ${matchedUser.username}?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    controller.clearErrorMessage();
                  },
                  child: const Text('Nanti Saja'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
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
                    controller.clearErrorMessage();
                  },
                  child: const Text('Chat Sekarang'),
                ),
              ],
            ),
          );
        }
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
      AlignmentTween(begin: _dragAlignment, end: Alignment.center),
    );
    _animationController.reset();
    _animationController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragAlignment += Alignment(
        details.delta.dx / (_screenSize.width / 2),
        details.delta.dy / (_screenSize.height / 2),
      );

      _rotation = -_dragAlignment.x * 0.2;
      _opacity = 1 - (_dragAlignment.x.abs() + _dragAlignment.y.abs()) / 2;

      if (_opacity < 0) _opacity = 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final controller = context.read<MatchingController>();
    if (controller.profiles.isEmpty) return;

    final ChatUser currentProfile = controller.profiles.first;
    const double swipeThreshold = 0.4;

    if (_dragAlignment.x.abs() > swipeThreshold ||
        _dragAlignment.y.abs() > swipeThreshold) {
      // Swiped far enough
      _animation = _animationController.drive(
        AlignmentTween(
          begin: _dragAlignment,
          end: Alignment(
            _dragAlignment.x > 0 ? 5.0 : -5.0,
            _dragAlignment.y + (_dragAlignment.y > 0 ? 2.0 : -2.0),
          ),
        ),
      );
      _animationController.forward().then((_) {
        if (_dragAlignment.x > 0) {
          controller.swipeRight(currentProfile.uid);
        } else {
          controller.swipeLeft(currentProfile.uid);
        }
        _resetCardPosition();
      });
    } else {
      // Snap back
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Background hijau muda
      body: Consumer<MatchingController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          //Tampilkan error hanya jika bukan pesan "It's a Match" (karena itu ditangani dialog)
          if (controller.errorMessage != null &&
              !controller.errorMessage!.startsWith("It's a Match") &&
              controller.profiles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadProfiles(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.profiles.isEmpty) {
            return const Center(child: Text('Tidak ada profil ditemukan.'));
          }

          return Stack(
            children: [
              // Kartu berikutnya (di belakang)
              if (controller.profiles.length > 1)
                Align(
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: 0.93,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCard(controller.profiles[1]),
                    ),
                  ),
                ),

              // Kartu saat ini (di depan, bisa digeser)
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
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: _buildCard(controller.profiles.first),
                      ),
                    ),
                  ),
                ),
              ),

              // Tombol Aksi
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'pass',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          controller.swipeLeft(controller.profiles.first.uid);
                          _resetCardPosition();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: 'like',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          controller.swipeRight(controller.profiles.first.uid);
                          _resetCardPosition();
                        },
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.green,
                          size: 32,
                        ),
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

  Widget _buildCard(ChatUser user) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gambar Profil
          if (user.imageUrl != null && user.imageUrl!.isNotEmpty)
            _buildImage(user.imageUrl!)
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 100, color: Colors.white),
            ),

          // Gradient Overlay untuk teks
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.gender != null)
                    Text(
                      user.gender!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  if (user.bio != null)
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    try {
      if (imageUrl.startsWith('http')) {
        return Image.network(imageUrl, fit: BoxFit.cover);
      } else {
        return Image.memory(base64Decode(imageUrl), fit: BoxFit.cover);
      }
    } catch (e) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 50),
      );
    }
  }
}
