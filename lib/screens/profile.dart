import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'editProfile.dart';
import '/controllers/profileController.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Pengguna tidak login."));
    }

    // Use a StreamBuilder to listen to the user's document in Firestore
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
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

        // Get user data from the snapshot
        final userData = snapshot.data!.data()!;
        final String name = userData['name'] ?? 'No Name';
        final String? imageUrl = userData['imageUrl'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Pengguna'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : const NetworkImage('https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200')
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
                      // Get the ProfileController from Provider
                      final profileController = Provider.of<ProfileController>(context, listen: false);

                      // Pre-fill the controller with current data before navigating
                      profileController.nameController.text = userData['name'] ?? '';
                      profileController.nikController.text = userData['nik'] ?? '';
                      profileController.addressController.text = userData['address'] ?? '';
                      profileController.dobController.text = userData['dob'] ?? '';
                      profileController.gender = userData['gender'];
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // EditProfilePage will get the controller from Provider
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 32),
                  // ... (rest of the widgets like 'Premium' card)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}