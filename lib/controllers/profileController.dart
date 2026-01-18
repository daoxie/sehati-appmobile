import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //input
  final TextEditingController nikController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  //gender dan tanggal
  String? gender;
  DateTime? selectedDate;
  File? imageFile;
  String? imageUrl; // Add imageUrl property

  final ImagePicker _picker = ImagePicker();
  // No longer need a manual callback
  // VoidCallback? onImageSelected;

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

  // Image picking methods
  Future<void> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners(); // Notify listeners of the change
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners(); // Notify listeners of the change
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //menyimpan profil
  Future<bool> saveProfile() async {
    isLoading = true;
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      isLoading = false;
      return false; // Not logged in
    }

    try {
      String? newImageUrl;
      // If there is a new image file, upload it
      if (imageFile != null) {
        final ref = _storage.ref().child('profile_images').child('$uid.jpg');
        await ref.putFile(imageFile!);
        newImageUrl = await ref.getDownloadURL();
      }

      // Prepare data to be saved
      Map<String, dynamic> userData = {
        'name': nameController.text,
        'nik': nikController.text,
        'address': addressController.text,
        'dob': dobController.text,
        'gender': gender,
        'imageUrl': newImageUrl ?? imageUrl, // Use new URL, or fall back to existing
      };

      // Update user document in Firestore
      await _firestore.collection('users').doc(uid).update(userData);

      isLoading = false;
      return true;
    } catch (e) {
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
      return; // Not logged in
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
        imageUrl = data['imageUrl']; // Load the image URL
        notifyListeners(); // Notify UI of loaded data
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      isLoading = false;
    }
  }
  
  //bersihkan semua field kecuali nama
  void clearAllExceptName() {
    nikController.clear();
    addressController.clear();
    dobController.clear();
    gender = null;
    selectedDate = null;
    imageFile = null;
    imageUrl = null; // Also clear imageUrl
  }

  //bersihkan resources
  @override
  void dispose() {
    nikController.dispose();
    nameController.dispose();
    addressController.dispose();
    dobController.dispose();
    super.dispose();
  }
}
