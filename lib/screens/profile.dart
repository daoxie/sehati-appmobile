import 'package:flutter/material.dart';
import '/controllers/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();
  }

  void _saveProfile() {
    // First, validate the form.
    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    
    if (!isFormValid || _profileController.gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // If valid, save profile and show success.
    if (_profileController.saveProfile()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // A light grey background
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1.0, // A subtle shadow
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Profile picture section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.green.shade800,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement image picker
                      },
                      child: const Text('Ganti Foto', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // NIK
              TextFormField(
                controller: _profileController.nikController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'NIK',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _profileController.validateNIK,
              ),
              const SizedBox(height: 16),

              // Nama
              TextFormField(
                controller: _profileController.nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _profileController.validateName,
              ),
              const SizedBox(height: 16),

              // Jenis Kelamin using DropdownButtonFormField
              DropdownButtonFormField<String>(
                value: _profileController.gender,
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
                    _profileController.gender = newValue;
                  });
                },
                validator: _profileController.validateGender,
              ),
              const SizedBox(height: 16),

              // Tanggal Lahir
              TextFormField(
                controller: _profileController.dobController,
                readOnly: true,
                onTap: () => _profileController.selectDate(context),
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _profileController.validateDOB,
              ),
              const SizedBox(height: 16),

              // Alamat
              TextFormField(
                controller: _profileController.addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: const Icon(Icons.home),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _profileController.validateAddress,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Green button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Simpan Profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}