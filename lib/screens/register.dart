import 'package:flutter/material.dart';
import '/controllers/registerController.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late RegisterController _registerController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _registerController = RegisterController();
  }

  @override
  void dispose() {
    _registerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await _registerController.submitRegister();
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrasi berhasil')),
    );

    Navigator.of(context).pop(); // Kembali ke halaman login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
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
                  const FlutterLogo(size: 80),
                  const SizedBox(height: 24),

                  // Nama
                  TextFormField(
                    controller: _registerController.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: _registerController.validateName,
                  ),

                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _registerController.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: _registerController.validateEmail,
                  ),

                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _registerController.passwordController,
                    obscureText: _registerController.obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_registerController.obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _registerController.obscurePassword = !_registerController.obscurePassword),
                      ),
                    ),
                    validator: _registerController.validatePassword,
                  ),

                  const SizedBox(height: 12),

                  // Konfirmasi Password
                  TextFormField(
                    controller: _registerController.confirmController,
                    obscureText: _registerController.obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi kata sandi',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_registerController.obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _registerController.obscureConfirm = !_registerController.obscureConfirm),
                      ),
                    ),
                    validator: _registerController.validateConfirmPassword,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    );
  }
}