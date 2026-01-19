import 'dart:convert';
import 'dart:async';
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
  final TextEditingController minAgeController = TextEditingController();
  final TextEditingController maxAgeController = TextEditingController();

  String? gender;
  DateTime? selectedDate;
  String? searchGender;
  Uint8List? _pickedImageBytes;
  Uint8List? get pickedImageBytes => _pickedImageBytes;
  String? imageUrl;

  int _likesGivenCount = 0;
  int get likesGivenCount => _likesGivenCount;

  int _likesReceivedCount = 0;
  int get likesReceivedCount => _likesReceivedCount;

  final ImagePicker _picker = ImagePicker();

  StreamSubscription<QuerySnapshot>? _likesGivenSub;
  StreamSubscription<QuerySnapshot>? _likesReceivedSub;

  ProfileController() {
    // Otomatis memuat data saat controller dibuat atau status login berubah
    if (_auth.currentUser != null) {
      loadProfileData();
    }
    _auth.authStateChanges().listen((user) {
      if (user != null) loadProfileData();
    });
  }

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

  //validasi Min Age
  String? validateMinAge(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    if (int.tryParse(value) == null) {
      return 'Umur minimal harus angka';
    }
    return null;
  }

  //validasi Max Age
  String? validateMaxAge(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    if (int.tryParse(value) == null) {
      return 'Umur maksimal harus angka';
    }
    return null;
  }

  //validasi Search Gender
  String? validateSearchGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Preferensi jenis kelamin wajib dipilih';
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
            colorScheme: const ColorScheme.light(primary: Colors.green),
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
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 400,
    );
    if (pickedFile != null) {
      _pickedImageBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
      maxWidth: 400,
    );
    if (pickedFile != null) {
      _pickedImageBytes = await pickedFile.readAsBytes();
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

      if (_pickedImageBytes != null) {
        imageBase64 = base64Encode(_pickedImageBytes!);
      }

      Map<String, dynamic> userData = {
        'name': nameController.text,
        'nik': nikController.text,
        'address': addressController.text,
        'dob': dobController.text,
        'gender': gender,
        'searchGender': searchGender,
        'minAge': int.tryParse(minAgeController.text) ?? null,
        'maxAge': int.tryParse(maxAgeController.text) ?? null,
      };

      if (imageBase64 != null) {
        userData['imageUrl'] = imageBase64;
      }

      // Gunakan set dengan merge: true agar tidak error jika dokumen belum ada atau data parsial
      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

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
        searchGender = data['searchGender'];
        minAgeController.text = (data['minAge'] ?? '').toString();
        maxAgeController.text = (data['maxAge'] ?? '').toString();
        imageUrl = data['imageUrl'];
        errorMessage = null;
        _startListeningToLikeCounts(
          uid,
        ); // Mulai dengarkan data like secara realtime
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

  //untuk Like
  void _startListeningToLikeCounts(String userId) {
    _likesGivenSub?.cancel();
    _likesReceivedSub?.cancel();

    //yang kita like
    _likesGivenSub = _firestore
        .collection('users')
        .doc(userId)
        .collection('swipes')
        .where('liked', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          _likesGivenCount = snapshot.docs.length;
          notifyListeners();
        });

    //melihat siapa yg like
    _likesReceivedSub = _firestore
        .collectionGroup('swipes')
        .where(
          'targetUserId',
          isEqualTo: userId,
        ) // Cari dokumen dimana targetUserId adalah kita (artinya kita yang di-swipe)
        .where('liked', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            _likesReceivedCount = snapshot.docs.length;
            notifyListeners();
          },
          onError: (e) {
            print(
              'Error listening to received likes (Mungkin butuh Index Firestore): $e',
            );
          },
        );
  }

  void clearAllExceptName() {
    nikController.clear();
    addressController.clear();
    dobController.clear();
    minAgeController.clear();
    maxAgeController.clear();
    gender = null;
    searchGender = null;
    selectedDate = null;
    _pickedImageBytes = null;
    imageUrl = null;
  }

  @override
  void dispose() {
    nikController.dispose();
    nameController.dispose();
    addressController.dispose();
    dobController.dispose();
    minAgeController.dispose();
    maxAgeController.dispose();
    _likesGivenSub?.cancel();
    _likesReceivedSub?.cancel();
    super.dispose();
  }
}
