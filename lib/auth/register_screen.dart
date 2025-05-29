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

  // Color palette
  final Color primaryColor = const Color(0xFF1A237E);
  final Color secondaryColor = const Color(0xFF0D47A1);
  final Color inputBg = Colors.grey[100]!;
  final Color white = Colors.white;
  final double borderRadiusValue = 18.0;

  Future<void> _register() async {
    setState(() => _loading = true);
    final response = await http.post(
      Uri.parse('http://192.168.1.18:3000/API/register'),
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
      filled: true,
      fillColor: inputBg,
      hintStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
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
                    height: 50,
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
                        color: primaryColor.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Daftar',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buat akun untuk pemesanan tiket nonton kamu',
                        style: TextStyle(fontSize: 15, color: primaryColor.withOpacity(0.8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Nama Lengkap',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: buildInputDecoration('Masukkan nama lengkap kamu'),
                        style: TextStyle(color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Alamat Email',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: buildInputDecoration('example@domain.com'),
                        style: TextStyle(color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          filled: true,
                          fillColor: inputBg,
                          hintStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadiusValue),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadiusValue),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: primaryColor.withOpacity(0.7),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        style: TextStyle(color: primaryColor),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadiusValue),
                            ),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text.rich(
                            TextSpan(
                              text: 'Sudah punya akun? ',
                              style: TextStyle(color: primaryColor.withOpacity(0.7)),
                              children: [
                                TextSpan(
                                  text: 'Masuk',
                                  style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
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
