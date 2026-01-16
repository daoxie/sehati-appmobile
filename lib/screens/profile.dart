import 'package:flutter/material.dart';
import 'package:sehati_appmobile/screens/editProfile.dart';
import 'package:sehati_appmobile/controllers/profileController.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String name;
  final ProfileController controller;

  const ProfilePage({Key? key, required this.name, required this.controller}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.onImageSelected = () {
      setState(() {}); // Rebuild the widget when image is selected
    };
  }

  @override
  void dispose() {
    widget.controller.onImageSelected = null; // Clear the callback
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // User Image
              CircleAvatar(
                radius: 60,
                backgroundImage: widget.controller.imageFile != null
                    ? FileImage(widget.controller.imageFile!)
                    : const NetworkImage(
                            'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200')
                        as ImageProvider, // Placeholder image
              ),
              const SizedBox(height: 16),

              // User Name
              Text(
                widget.controller.nameController.text.isNotEmpty
                    ? widget.controller.nameController.text
                    : widget.name, // Use name from controller if available, else from widget
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16), // Added spacing

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(controller: widget.controller),
                    ),
                  );
                },
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 32),

              // Premium Feature Promotion Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dapatkan Fitur Premium!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tingkatkan pengalaman Anda dengan fitur eksklusif mode komitmen dan anda bisa like tanpa terbatas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement navigation to premium subscription page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur Ready'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Upgrade Premium sekarang',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
