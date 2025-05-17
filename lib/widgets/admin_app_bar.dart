import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String baseUrl = 'http://localhost:3000/API';
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
      elevation: 1,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey[300],
          height: 1.0,
        ),
      ),
      title: FutureBuilder<String?>(
        future: _getAdminName(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              'Welcome, ${snapshot.data}',
              style: TextStyle(fontSize: 16),
            );
          }
          return SizedBox.shrink();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () => _logout(context),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 