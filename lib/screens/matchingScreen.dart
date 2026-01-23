import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/matchingController.dart';
import '/models/chatModels.dart';
import '/models/genderModel.dart';
import '/models/deepMatchingModel.dart';
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
              title: const Text('AYO CHATTING🎉'),
              content: Text('Kamu cocok dengan ${matchedUser.username}?'),
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
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        title: const Text(
          'Matching',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Deep Filter Icon
          Consumer<MatchingController>(
            builder: (context, controller, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    tooltip: 'Filter Mendalam',
                    onPressed: () => _showDeepFilterDialog(context, controller),
                  ),
                  // Indicator jika filter aktif
                  if (controller.isDeepFilterEnabled)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Gender Filter di header
          Consumer<MatchingController>(
            builder: (context, controller, _) {
              return _buildGenderFilterDropdown(controller);
            },
          ),
        ],
      ),
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
          //Gambar Profil
          if (user.imageUrl != null && user.imageUrl!.isNotEmpty)
            _buildImage(user.imageUrl!)
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 100, color: Colors.white),
            ),

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

  /// Widget dropdown untuk filter gender di AppBar
  Widget _buildGenderFilterDropdown(MatchingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Gender>(
          value: controller.selectedGenderFilter,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Colors.green[600],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: GenderFilter.allOptions.map((gender) {
            return DropdownMenuItem<Gender>(
              value: gender,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GenderFilter.getIcon(gender),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    GenderFilter.getDisplayName(gender),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Gender? newValue) {
            if (newValue != null) {
              controller.setGenderFilter(newValue);
            }
          },
        ),
      ),
    );
  }

  /// Dialog untuk filter mendalam (agama, hobi, umur)
  void _showDeepFilterDialog(
    BuildContext context,
    MatchingController controller,
  ) {
    // State lokal untuk dialog
    String? selectedAgama = controller.deepFilter.filterAgama;
    List<String> selectedHobi = List.from(controller.deepFilter.filterHobi);
    RangeValues umurRange = RangeValues(
      (controller.deepFilter.minUmur ?? 18).toDouble(),
      (controller.deepFilter.maxUmur ?? 50).toDouble(),
    );
    bool useUmurFilter =
        controller.deepFilter.minUmur != null ||
        controller.deepFilter.maxUmur != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Mendalam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedAgama = null;
                              selectedHobi = [];
                              useUmurFilter = false;
                              umurRange = const RangeValues(18, 50);
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Agama Filter
                          const Text(
                            '🙏 Agama',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedAgama,
                            decoration: InputDecoration(
                              hintText: 'Semua Agama',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Semua Agama'),
                              ),
                              ...AgamaHelper.daftarAgama.map((agama) {
                                return DropdownMenuItem<String>(
                                  value: agama,
                                  child: Text(agama),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedAgama = value;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // Hobi Filter
                          const Text(
                            '🎯 Hobi (Pilih yang ingin dicari)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: HobiHelper.daftarHobi.map((hobi) {
                              final isSelected = selectedHobi.contains(hobi);
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(HobiHelper.getIcon(hobi)),
                                    const SizedBox(width: 4),
                                    Text(
                                      hobi,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setDialogState(() {
                                    if (isSelected) {
                                      selectedHobi.remove(hobi);
                                    } else {
                                      selectedHobi.add(hobi);
                                    }
                                  });
                                },
                                selectedColor: Colors.green.shade100,
                                checkmarkColor: Colors.green,
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Umur Filter
                          Row(
                            children: [
                              const Text(
                                '🎂 Range Umur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: useUmurFilter,
                                onChanged: (value) {
                                  setDialogState(() {
                                    useUmurFilter = value;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                          if (useUmurFilter) ...[
                            Text(
                              '${umurRange.start.toInt()} - ${umurRange.end.toInt()} tahun',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            RangeSlider(
                              values: umurRange,
                              min: 18,
                              max: 60,
                              divisions: 42,
                              activeColor: Colors.green,
                              labels: RangeLabels(
                                '${umurRange.start.toInt()}',
                                '${umurRange.end.toInt()}',
                              ),
                              onChanged: (values) {
                                setDialogState(() {
                                  umurRange = values;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Apply Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Apply filter
                          final filter = DeepMatchingFilter(
                            filterAgama: selectedAgama,
                            filterHobi: selectedHobi,
                            minUmur: useUmurFilter
                                ? umurRange.start.toInt()
                                : null,
                            maxUmur: useUmurFilter
                                ? umurRange.end.toInt()
                                : null,
                          );
                          controller.setDeepFilter(filter);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Terapkan Filter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
