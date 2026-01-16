import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sehati_appmobile/controllers/profileController.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileController controller;

  const EditProfilePage({Key? key, required this.controller}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.controller.clearAllExceptName();
    widget.controller.onImageSelected = () {
      setState(() {});
    };
  }

  @override
  void dispose() {
    widget.controller.onImageSelected = null;
    super.dispose();
  }

  
  void _showImagePickerOption() {
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
                  widget.controller.pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  widget.controller.pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      backgroundImage: widget.controller.imageFile != null
                          ? FileImage(widget.controller.imageFile!)
                          : const AssetImage('assets/images/user.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _showImagePickerOption,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ubah Foto Profil'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

            
              TextFormField(
                controller: widget.controller.nikController,
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
                validator: widget.controller.validateNIK,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: widget.controller.nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: widget.controller.validateName,
              ),

              const SizedBox(height: 16),

          
              DropdownButtonFormField<String>(
                value: widget.controller.gender,
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
                  setState(() {
                    widget.controller.gender = value;
                  });
                },
                validator: widget.controller.validateGender,
              ),

              const SizedBox(height: 16),

          
              TextFormField(
                controller: widget.controller.dobController,
                readOnly: true,
                onTap: () => widget.controller.selectDate(context),
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: widget.controller.validateDOB,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: widget.controller.addressController,
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
                validator: widget.controller.validateAddress,
              ),

              const SizedBox(height: 24),

           
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (widget.controller.saveProfile()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil berhasil disimpan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
