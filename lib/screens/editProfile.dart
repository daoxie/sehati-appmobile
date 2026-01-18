import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/profileController.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ProfileController>(context, listen: false);
      controller.loadProfileData().then((_) {
        if (controller.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
  }

  void _showImagePickerOption(ProfileController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSave(ProfileController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await controller.saveProfile();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Gagal menyimpan profil.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: () {
                            if (controller.pickedXFile != null) {
                              if (kIsWeb) {
                                return NetworkImage(
                                    controller.pickedXFile!.path);
                              } else {
                                return FileImage(
                                    File(controller.pickedXFile!.path));
                              }
                            }

                            if (controller.imageUrl != null &&
                                controller.imageUrl!.isNotEmpty) {
                              try {
                                if (controller.imageUrl!.startsWith('http')) {
                                  return NetworkImage(controller.imageUrl!);
                                } else {
                                  return MemoryImage(
                                      base64Decode(controller.imageUrl!));
                                }
                              } catch (e) {
                                return const NetworkImage(
                                    'https://www.gravatar.com/avatar/?d=mp');
                              }
                            }

                            return const NetworkImage(
                                'https://www.gravatar.com/avatar/?d=mp');
                          }() as ImageProvider,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _showImagePickerOption(controller),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Ubah Foto Profil'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller.nikController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'NIK',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: controller.validateNIK,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: controller.validateName,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: controller.gender,
                    decoration: InputDecoration(
                      labelText: 'Jenis Kelamin',
                      prefixIcon: const Icon(Icons.wc),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Pilih Jenis Kelamin'),
                    items: const ['Laki-laki', 'Perempuan']
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      controller.gender = value;
                    },
                    validator: controller.validateGender,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.dobController,
                    readOnly: true,
                    onTap: () => controller.selectDate(context),
                    decoration: InputDecoration(
                      labelText: 'Tanggal Lahir',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: controller.validateDOB,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Alamat',
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: controller.validateAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => _onSave(controller),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}