import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register.dart';
import '/controllers/loginController.dart';
import 'home.dart'; // Re-add import for HomePage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  //login dan validasi
  Future<void> _submitLogin(LoginController loginController) async {
    if (!formKey.currentState!.validate()) return;

    bool success = await loginController.submitLogin();

    if (!mounted) return;

    if (success) {
      // Re-add explicit navigation for robustness
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      // Display error message from controller
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loginController.errorMessage ?? 'Terjadi kesalahan tidak dikenal.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        body: Consumer<LoginController>(
          builder: (context, controller, child) {
            return Container(
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
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'asset/image/logoSHjpeg-removebg-preview.png',
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: controller.usernameOrEmailController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'Username or Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validateUsernameOrEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validatePassword,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: controller.isLoading
                                ? null
                                : () => _submitLogin(controller),
                            child: controller.isLoading
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
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
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
          },
        ),
      ),
    );
  }
}
