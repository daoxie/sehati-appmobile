import 'package:flutter/material.dart';
import 'register.dart';
import 'home.dart';
import '/controllers/loginController.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Key untuk validasi form
  final formKey = GlobalKey<FormState>();

  // Instansiasi controller
  late LoginController _loginController;

  // Status loading ketika tombol login ditekan
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginController = LoginController();
  }

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  // Fungsi login dan validasi
  Future<void> _submitLogin() 
  async {
    if (!formKey.currentState!.validate()) 
    return;

    setState(() => isLoading = true);

    // Panggil method login dari controller
    await _loginController.submitLogin();

    setState(() => isLoading = false);

    // Menampilkan pesan berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil login sebagai ${_loginController.emailController.text}'),
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
        backgroundColor: Colors.green, // Mengatur warna AppBar menjadi hijau
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const FlutterLogo(size: 96),
                  const SizedBox(height: 24),

                  // Input Email
                  TextFormField(
                    controller: _loginController.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: _loginController.validateEmail,
                  ),

                  const SizedBox(height: 12),

                  // Input Password
                  TextFormField(
                    controller: _loginController.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: _loginController.validatePassword,
                  ),

                  const SizedBox(height: 16),

                  // Tombol Login
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Mengatur warna tombol login menjadi hijau
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading ? null : _submitLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white, // Mengatur warna loading indicator menjadi putih
                            ),
                          )
                        : const Text('Masuk'),
                  ),

                  const SizedBox(height: 8),

                  // Tombol Registrasi
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green, // Mengatur warna teks tombol daftar menjadi hijau
                    ),
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