import 'package:flutter/material.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // Controller untuk input email dan password
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Status loading ketika tombol login ditekan
  bool _isLoading = false;

  @override
  void dispose() {
    // Membersihkan controller agar tidak boros memori
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Fungsi login (simulasi)
  Future<void> _submitLogin() async {
    // Cek apakah form valid
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulasi proses login (misalnya request API)
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    // Menampilkan pesan berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil login sebagai ${emailController.text}'),
      ),
    );

    // Pindah ke halaman beranda
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const FlutterLogo(size: 96),
                  const SizedBox(height: 24),

                  // Input Email
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Input Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tombol Login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Masuk'),
                  ),

                  const SizedBox(height: 8),

                  // Tombol Daftar
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Halaman setelah login
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
      ),
      body: const Center(
        child: Text('Selamat datang! Anda sudah login.'),
      ),
    );
  }
}
