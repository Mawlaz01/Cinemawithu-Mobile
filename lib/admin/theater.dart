import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final String baseUrl = 'http://localhost:3000/API';
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
          title: Text(isEditing ? 'Edit Theater' : 'Add Theater'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Theater Name'),
                ),
                TextField(
                  controller: seatsController,
                  decoration: InputDecoration(labelText: 'Total Seats'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
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
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: ''),
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
                  final badgeColor = Colors.deepPurple;
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.theaters, size: 40, color: Colors.deepPurple),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theater.name,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                                icon: Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _showTheaterDialog(theater: theater),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
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
        child: Icon(Icons.add),
        tooltip: 'Add Theater',
      ),
      bottomNavigationBar: const AdminNavBar(currentIndex: 1),
    );
  }
}
