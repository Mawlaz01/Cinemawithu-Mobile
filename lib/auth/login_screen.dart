import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();
  bool _loading = false;

  final Color primaryColor = Colors.black87;
  final Color buttonTextColor = Colors.white;
  final double borderRadiusValue = 12.0;

  // Variabel untuk menampilkan pesan error
  String _emailError = '';
  String _passwordError = '';

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
    }
  }

  Future<void> _login() async {
    // Reset pesan error
    setState(() {
      _emailError = '';
      _passwordError = '';
    });

    // Validasi input email dan password
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong';
      });
      return;
    }

    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      if (data['role'] == 'admin') {
        print('Redirecting to /admin/film');
        Navigator.pushReplacementNamed(context, '/admin/film');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_cinema.png',
                      height: 70,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Masuk',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masuk dulu yuk sebelum bisa lanjut!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Alamat email',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: buildInputDecoration('Masukkan alamat email'),
              ),
              if (_emailError.isNotEmpty)
                Text(
                  _emailError,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 20),
              const Text(
                'Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: buildInputDecoration('Masukkan password'),
              ),
              if (_passwordError.isNotEmpty)
                Text(
                  _passwordError,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
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
                          'Masuk',
                          style: TextStyle(color: buttonTextColor),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'Daftar',
                          style: TextStyle(color: Colors.blue),
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
