import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  final TextEditingController usernameOrEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String name = '';

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
//validasi email
  String? validateUsernameOrEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username atau Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (value.contains('@')) {
      if (!emailRegex.hasMatch(value)) {
        return 'Format email tidak valid';
      }
    } else {
      //validasi username
      if (value.contains(' ')) {
        return 'Username tidak boleh mengandung spasi';
      }
    }
    return null;
  }

  //validasi password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 6) {
      return 'Minimal 6 karakter';
    }
    return null;
  }

  //login
  Future<bool> submitLogin() async {
    errorMessage = null;
    isLoading = true;
    try {
      String signInEmail = usernameOrEmailController.text.trim();

      //validasi nama pengguna atau alamat email.
      if (!signInEmail.contains('@')) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: signInEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          signInEmail = querySnapshot.docs.first.data()['email'];
        } else {
          errorMessage = 'Username tidak ditemukan.';
          isLoading = false;
          return false;
        }
      }

      await _auth.signInWithEmailAndPassword(
        email: signInEmail,
        password: passwordController.text.trim(),
      );
      name = usernameOrEmailController.text.split('@')[0];
      isLoading = false;
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMessage = 'Pengguna tidak ditemukan.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Kata sandi salah.';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
      isLoading = false;
      return false;
    } catch (e) {
      errorMessage = 'Terjadi kesalahan tak terduga: $e';
      isLoading = false;
      return false;
    }
  }

  //Bersihkan resources
  @override
  void dispose() {
    usernameOrEmailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
