import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'editProfile.dart';
import '/controllers/profileController.dart';
import 'setLocation.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Pengguna tidak login."));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Profil tidak ditemukan.'));
        }

        final userData = snapshot.data!.data()!;
        final String name = userData['name'] ?? 'No Name';
        final String? imageUrl = userData['imageUrl'];

        return Scaffold(
          appBar: AppBar(title: const Text('Profil Pengguna')),
          body: Consumer<ProfileController>(
            builder: (context, profileController, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            () {
                                  if (imageUrl != null && imageUrl.isNotEmpty) {
                                    try {
                                      if (imageUrl.startsWith('http')) {
                                        return NetworkImage(imageUrl);
                                      } else {
                                        return MemoryImage(
                                          base64Decode(imageUrl),
                                        );
                                      }
                                    } catch (e) {
                                      return const NetworkImage(
                                        'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200',
                                      );
                                    }
                                  }
                                  return const NetworkImage(
                                    'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200',
                                  );
                                }()
                                as ImageProvider,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Prefill the controller with current data before navigating
                          profileController.nameController.text =
                              userData['name'] ?? '';
                          profileController.nikController.text =
                              userData['nik'] ?? '';
                          profileController.addressController.text =
                              userData['address'] ?? '';
                          profileController.dobController.text =
                              userData['dob'] ?? '';
                          profileController.gender = userData['gender'];
                          profileController.searchGender =
                              userData['searchGender'];
                          profileController.minAgeController.text =
                              (userData['minAge'] ?? '').toString();
                          profileController.maxAgeController.text =
                              (userData['maxAge'] ?? '').toString();
                          profileController.imageUrl = userData['imageUrl'];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),                
                          );
                        },
                        child: const Text('Edit Profile'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SetLocationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('Atur Lokasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Likes Diberikan',
                            profileController.likesGivenCount,
                          ),
                          _buildStatCard(
                            'Likes Diterima',
                            profileController.likesReceivedCount,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upgrade to Premium',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unlock exclusive features and enhance your experience!',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Go to Upgrade Screen'),
                                    ),
                                  );
                                },
                                child: const Text('Learn More'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tombol Keluar
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        color: Colors.red[50],
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Keluar',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            // Konfirmasi logout
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi'),
                                content: const Text(
                                  'Yakin ingin keluar dari akun?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseAuth.instance.signOut();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Widget _buildStatCard(String title, int count) {
  return Expanded(
    child: Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}