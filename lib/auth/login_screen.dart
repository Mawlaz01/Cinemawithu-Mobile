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
  bool _obscurePassword = true;

  // Color palette
  final Color darkBlue = const Color(0xFF0B0C2A);
  final Color primaryBlue = const Color(0xFF007AFF);
  final Color lightBlue = const Color(0xFF4CA1FF);
  final Color inputBg = const Color(0xFFB0C4DE);
  final Color white = Colors.white;
  final Color backgroundPlate = const Color(0xFFB0C4DE); // 4th color
  final double borderRadiusValue = 18.0;

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
      Uri.parse('http://192.168.1.21:3000/API/login'),
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
        print('Redirecting to /showing');
        Navigator.pushReplacementNamed(context, '/showing');
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
      filled: true,
      fillColor: inputBg,
      hintStyle: TextStyle(color: darkBlue.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        borderSide: BorderSide(color: lightBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPlate,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 2),
                Center(
                  child: Image.asset(
                    'assets/images/logo_cinema.png',
                    height:50,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: darkBlue.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masuk',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0B0C2A)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk dulu yuk sebelum bisa lanjut!',
                        style: TextStyle(fontSize: 15, color: darkBlue),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Alamat email',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B0C2A)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: buildInputDecoration('Masukkan alamat email'),
                        style: TextStyle(color: darkBlue),
                      ),
                      if (_emailError.isNotEmpty)
                        Text(
                          _emailError,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B0C2A)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: buildInputDecoration('Masukkan password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: darkBlue.withOpacity(0.7),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        style: TextStyle(color: darkBlue),
                      ),
                      if (_passwordError.isNotEmpty)
                        Text(
                          _passwordError,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadiusValue),
                            ),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: Text.rich(
                            TextSpan(
                              text: 'Belum punya akun? ',
                              style: TextStyle(color: darkBlue.withOpacity(0.7)),
                              children: [
                                TextSpan(
                                  text: 'Daftar',
                                  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
