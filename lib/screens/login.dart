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
      
      body: Container(
        color: Colors.green[100],
        child: Center(
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
                    const Center(
                      child: Text(
                        'SeHati Apps',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 73, 174, 77),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const FlutterLogo(size: 96),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _loginController.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: _loginController.validateEmail,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _loginController.passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: _loginController.validatePassword,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading ? null : _submitLogin,
                      child: isLoading
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

                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
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
      ),
    );
  }
}