import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance of Firebase Auth

  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String name = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //validasi username
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username wajib diisi';
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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  //login
  Future<bool> submitLogin() async {
    errorMessage = null;
    isLoading = true;
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      name = emailController.text.split('@')[0];
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
