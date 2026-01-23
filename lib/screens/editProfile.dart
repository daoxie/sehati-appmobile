import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/profileController.dart';
import '/models/deepMatchingModel.dart';

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
          appBar: AppBar(title: const Text('Edit Profile')),
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
                          backgroundImage: controller.pickedImageBytes != null
                              ? MemoryImage(controller.pickedImageBytes!)
                              : (controller.imageUrl != null &&
                                    controller.imageUrl!.isNotEmpty)
                              ? MemoryImage(base64Decode(controller.imageUrl!))
                              : const NetworkImage(
                                      'https://www.gravatar.com/avatar/?d=mp',
                                    )
                                    as ImageProvider,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Pilih Jenis Kelamin'),
                    items: const ['Laki-laki', 'Perempuan']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
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
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: controller.validateAddress,
                  ),
                  const SizedBox(height: 16),

                  // === FIELD BARU: AGAMA ===
                  DropdownButtonFormField<String>(
                    value: controller.agama,
                    decoration: InputDecoration(
                      labelText: 'Agama',
                      prefixIcon: const Icon(Icons.self_improvement),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Pilih Agama'),
                    items: AgamaHelper.daftarAgama
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      controller.setAgama(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // === FIELD BARU: HOBI ===
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.interests, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            const Text(
                              'Hobi (Pilih beberapa)',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: HobiHelper.daftarHobi.map((hobi) {
                            final isSelected = controller.selectedHobi.contains(
                              hobi,
                            );
                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(HobiHelper.getIcon(hobi)),
                                  const SizedBox(width: 4),
                                  Text(hobi),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => controller.toggleHobi(hobi),
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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
