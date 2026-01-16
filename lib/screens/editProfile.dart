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
    widget.controller.onImageSelected = () {
      setState(() {}); // Rebuild the widget when image is selected
    };
  }

  @override
  void dispose() {
    widget.controller.onImageSelected = null; // Clear the callback
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Pick from Gallery'),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.controller.pickImageFromGallery();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take Photo'),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.controller.pickImageFromCamera();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.controller.imageFile != null
                        ? FileImage(widget.controller.imageFile!)
                        : const NetworkImage(
                                'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200')
                            as ImageProvider, // Placeholder or existing image
                    child: widget.controller.imageFile == null
                        ? const Icon(Icons.camera_alt,
                            size: 40, color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: widget.controller.nikController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'NIK',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: widget.controller.validateNIK,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.controller.nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text('Pilih Jenis Kelamin'),
                items: <String>['Laki-laki', 'Perempuan']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    widget.controller.gender = newValue;
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Harap lengkapi semua data.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}