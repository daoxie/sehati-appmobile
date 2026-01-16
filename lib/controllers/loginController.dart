import 'package:flutter/material.dart';

class LoginController {
  //input email dan pw
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String name = '';

  bool isLoading = false;

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
