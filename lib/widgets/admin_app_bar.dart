import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/url_api.dart';
import '../theme.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String baseUrl = '${UrlApi.baseUrl}/API';
  final _storage = const FlutterSecureStorage();

  AdminAppBar({Key? key, required this.title}) : super(key: key);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> _getAdminName() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return data['username'];
      }
      return null;
    } catch (e) {
      print('Error fetching admin name: $e');
      return null;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await _storage.delete(key: 'token');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4,
      backgroundColor: const Color(0xFF1A237E),
      title: FutureBuilder<String?>(
        future: _getAdminName(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'Welcome, ${snapshot.data}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            );
          }
          return SizedBox.shrink();
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Material(
            color: Colors.transparent,
            shape: CircleBorder(),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _logout(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Tooltip(
                  message: 'Keluar',
                  child: Icon(Icons.logout, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 