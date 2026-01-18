import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nikController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  String? gender;
  DateTime? selectedDate;
  XFile? _pickedXFile;
  XFile? get pickedXFile => _pickedXFile;
  String? imageUrl;

  final ImagePicker _picker = ImagePicker();

  String? validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK wajib diisi';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  String? validateGender(String? value) {
    if (value == null) {
      return 'Jenis kelamin wajib dipilih';
    }
    return null;
  }

  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal lahir wajib diisi';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alamat wajib diisi';
    }
    return null;
  }

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

  Future<void> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 40, maxWidth: 400);
    if (pickedFile != null) {
      _pickedXFile = pickedFile;
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 40, maxWidth: 400);
    if (pickedFile != null) {
      _pickedXFile = pickedFile;
      notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    isLoading = true;
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      isLoading = false;
      return false;
    }

    try {
      String? imageBase64;

      if (_pickedXFile != null) {
        Uint8List imageBytes = await _pickedXFile!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      Map<String, dynamic> userData = {
        'name': nameController.text,
        'nik': nikController.text,
        'address': addressController.text,
        'dob': dobController.text,
        'gender': gender,
      };

      if (imageBase64 != null) {
        userData['imageUrl'] = imageBase64;
      }

      await _firestore.collection('users').doc(uid).update(userData);

      isLoading = false;
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = 'Terjadi kesalahan: $e';
      print('Error saving profile: $e');
      isLoading = false;
      return false;
    }
  }

  Future<void> loadProfileData() async {
    isLoading = true;
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      isLoading = false;
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        nikController.text = data['nik'] ?? '';
        addressController.text = data['address'] ?? '';
        dobController.text = data['dob'] ?? '';
        gender = data['gender'];
        imageUrl = data['imageUrl'];
        errorMessage = null;
        notifyListeners();
      } else {
        errorMessage = 'Profil pengguna tidak ditemukan.';
      }
    } on FirebaseException catch (e) {
      errorMessage = 'Error Firebase: ${e.message}';
      print('Error loading profile data: $e');
    } catch (e) {
      errorMessage = 'Terjadi kesalahan tak terduga saat memuat profil: $e';
      print('Error loading profile data: $e');
    } finally {
      isLoading = false;
    }
  }

  void clearAllExceptName() {
    nikController.clear();
    addressController.clear();
    dobController.clear();
    gender = null;
    selectedDate = null;
    _pickedXFile = null;
    imageUrl = null;
  }

  @override
  void dispose() {
    nikController.dispose();
    nameController.dispose();
    addressController.dispose();
    dobController.dispose();
    super.dispose();
  }
}