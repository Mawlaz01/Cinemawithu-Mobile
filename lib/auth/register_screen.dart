import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  final Color primaryColor = Colors.black87;
  final Color buttonTextColor = Colors.white;
  final double borderRadiusValue = 12.0;

  Future<void> _register() async {
    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil')),
      );
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  InputDecoration buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusValue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Image.asset('assets/images/logo_cinema.png', height: 70),
                    const SizedBox(height: 20),
                    const Text(
                      'Daftar',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buat akun untuk pemesanan tiket nonton kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              // Nama Lengkap
              const Text("Nama Lengkap", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: buildInputDecoration('Masukkan nama lengkap kamu'),
              ),
              const SizedBox(height: 16),
              // Alamat Email
              const Text("Alamat Email", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: buildInputDecoration('example@domain.com'),
              ),
              const SizedBox(height: 16),
              // Kata Sandi
              const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusValue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Daftar',
                          style: TextStyle(color: buttonTextColor),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Navigasi ke Halaman Login
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // kembali ke halaman login
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Sudah punya akun? ',
                      children: [
                        TextSpan(
                          text: 'Masuk',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
