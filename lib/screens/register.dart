import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/controllers/registerController.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submit(RegisterController registerController) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool success = await registerController.submitRegister();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registrasi berhasil')));
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            registerController.errorMessage ??
                'Terjadi kesalahan tidak dikenal.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterController(),
      child: Consumer<RegisterController>(
        // Use Consumer directly here
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Daftar'),
              backgroundColor: Colors.green[800],
            ),
            body: Container(
              color: Colors.green[100],
              child: Center(
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
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'asset/image/logoSHjpeg-removebg-preview.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: controller.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validateName,
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: controller.usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validateUsername,
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validateEmail,
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: controller.passwordController,
                            obscureText: controller.obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    controller.obscurePassword =
                                        !controller.obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validatePassword,
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: controller.confirmController,
                            obscureText: controller.obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi kata sandi',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscureConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    controller.obscureConfirm =
                                        !controller.obscureConfirm;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: controller.validateConfirmPassword,
                          ),

                          const SizedBox(height: 16),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: controller.isLoading
                                ? null
                                : () => _submit(controller),
                            child: controller.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Daftar'),
                          ),

                          const SizedBox(height: 8),

                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Sudah punya akun? Masuk'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
