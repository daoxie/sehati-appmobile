import 'package:flutter/material.dart';

class RegisterController {
  //input
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;

  //validasi nama
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  //validasi email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value)) {
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

  //konfirmasi password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != passwordController.text) {
      return 'Konfirmasi tidak cocok';
    }
    return null;
  }

  //registrasi
  Future<bool> submitRegister() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  //Bersihkan resources
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
  }
}
