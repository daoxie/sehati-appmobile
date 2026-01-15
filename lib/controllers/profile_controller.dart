import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileController {
  //input
  final TextEditingController nikController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  //gender dan tanggal
  String? gender;
  DateTime? selectedDate;

  //validasi NIK
  String? validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK wajib diisi';
    }
    return null;
  }

  //validasi Nama
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  //validasi Jenis Kelamin
  String? validateGender(String? value) {
    if (value == null) {
      return 'Jenis kelamin wajib dipilih';
    }
    return null;
  }

  //validasi Tanggal Lahir
  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal lahir wajib diisi';
    }
    return null;
  }

  //validasi Alamat
  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alamat wajib diisi';
    }
    return null;
  }

  //kalender
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      dobController.text = DateFormat('dd MMMM yyyy').format(picked);
    }
  }

  //menyimpan profil
  bool saveProfile() {
    if (gender == null) {
      return false;
    }
    
    //cetak data profil
    print('NIK: ${nikController.text}');
    print('Nama: ${nameController.text}');
    print('Jenis Kelamin: $gender');
    print('Tanggal Lahir: ${dobController.text}');
    print('Alamat: ${addressController.text}');
    
    return true;
  }

  //bersihkan resources
  void dispose() {
    nikController.dispose();
    nameController.dispose();
    addressController.dispose();
    dobController.dispose();
  }
}
