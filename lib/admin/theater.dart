import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/url_api.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_nav_bar.dart';
import '../theme.dart';

class Theater {
  int id;
  String name;
  int totalSeats;

  Theater({
    required this.id,
    required this.name,
    required this.totalSeats,
  });

  factory Theater.fromJson(Map<String, dynamic> json) {
    return Theater(
      id: json['theater_id'],
      name: json['name'],
      totalSeats: json['total_seats'],
    );
  }
}

class AdminTheaterPage extends StatefulWidget {
  const AdminTheaterPage({Key? key}) : super(key: key);

  @override
  State<AdminTheaterPage> createState() => _AdminTheaterPageState();
}

class _AdminTheaterPageState extends State<AdminTheaterPage> {
  List<Theater> theaters = [];
  final String baseUrl = '${UrlApi.baseUrl}/API';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchTheaters();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchTheaters() async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.get(
      Uri.parse('$baseUrl/theater'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      setState(() {
        theaters = data.map((json) => Theater.fromJson(json)).toList();
      });
    }
  }

  Future<void> addTheater(String name, int totalSeats) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.post(
      Uri.parse('$baseUrl/theater/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'total_seats': totalSeats,
      }),
    );
    if (response.statusCode == 201) {
      fetchTheaters();
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> updateTheater(Theater theater) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.patch(
      Uri.parse('$baseUrl/theater/update/${theater.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': theater.name,
        'total_seats': theater.totalSeats,
      }),
    );
    if (response.statusCode == 200) {
      fetchTheaters();
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> deleteTheater(int id) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/theater/delete/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      fetchTheaters();
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _showTheaterDialog({Theater? theater}) {
    final isEditing = theater != null;
    final nameController = TextEditingController(text: theater?.name ?? '');
    final seatsController = TextEditingController(text: theater?.totalSeats.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Theater' : 'Add Theater',
            style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Theater Name',
                    labelStyle: TextStyle(color: Color(0xFF1A237E)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1A237E)),
                    ),
                  ),
                ),
                TextField(
                  controller: seatsController,
                  decoration: InputDecoration(
                    labelText: 'Total Seats',
                    labelStyle: TextStyle(color: Color(0xFF1A237E)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1A237E)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[800])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || seatsController.text.isEmpty) {
                  return;
                }
                final name = nameController.text;
                final totalSeats = int.tryParse(seatsController.text) ?? 0;
                if (isEditing) {
                  await updateTheater(Theater(id: theater!.id, name: name, totalSeats: totalSeats));
                } else {
                  await addTheater(name, totalSeats);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isEditing ? 'Save' : 'Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: 'Theater'),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: theaters.length,
                itemBuilder: (context, index) {
                  final theater = theaters[index];
                  final badgeColor = Color(0xFF1A237E);
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.theaters, size: 40, color: Color(0xFF1A237E)),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theater.name,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Total Seats: ${theater.totalSeats}',
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Color(0xFF0D47A1)),
                                onPressed: () => _showTheaterDialog(theater: theater),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400]),
                                onPressed: () => deleteTheater(theater.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTheaterDialog(),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF1A237E),
        tooltip: 'Add Theater',
      ),
      bottomNavigationBar: AdminNavBar(currentIndex: 1, onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/admin/film');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/admin/seat');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/admin/showtime');
        }
      }),
    );
  }
}
