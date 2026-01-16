import 'package:flutter/material.dart';

class LoginController {
  //input email dan pw
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String name = '';

  bool isLoading = false;

  //validasi email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Format email tidak valid';
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
    await Future.delayed(const Duration(seconds: 1));
    name = emailController.text.split('@')[0];
    return true;
  }

  //Bersihkan resources
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
