import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/admin_app_bar.dart';
import '../theme.dart';

class Seat {
  int id;
  int theaterId;
  String seatLabel;

  Seat({
    required this.id,
    required this.theaterId,
    required this.seatLabel,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['seat_id'],
      theaterId: json['theater_id'],
      seatLabel: json['seat_label'],
    );
  }
}

class AdminSeatPage extends StatefulWidget {
  const AdminSeatPage({Key? key}) : super(key: key);

  @override
  State<AdminSeatPage> createState() => _AdminSeatPageState();
}

class _AdminSeatPageState extends State<AdminSeatPage> {
  List<Seat> seats = [];
  List<Map<String, dynamic>> theaters = [];
  final String baseUrl = 'http://localhost:3000/API';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchTheaters();
    fetchSeats();
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
      print('Theaters data: $data');
      setState(() {
        theaters = data.map((json) => {
          'id': json['theater_id'],
          'name': json['name'],
          'total_seats': json['total_seats'],
        }).toList();
      });
      print('Processed theaters: $theaters');
    } else {
      print('Error fetching theaters: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> fetchSeats() async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.get(
      Uri.parse('$baseUrl/seat'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      setState(() {
        seats = data.map((json) => Seat.fromJson(json)).toList();
      });
    }
  }

  Future<void> addSeat(int theaterId, String seatLabel) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.post(
      Uri.parse('$baseUrl/seat/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'theater_id': theaterId,
        'seat_label': seatLabel,
      }),
    );
    if (response.statusCode == 201) {
      fetchSeats();
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> updateSeat(Seat seat) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.patch(
      Uri.parse('$baseUrl/seat/update/${seat.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'theater_id': seat.theaterId,
        'seat_label': seat.seatLabel,
      }),
    );
    if (response.statusCode == 200) {
      fetchSeats();
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> deleteSeat(int id) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/seat/delete/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      fetchSeats();
    } else {
      final error = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  int _seatCountForTheater(int theaterId) {
    return seats.where((seat) => seat.theaterId == theaterId).length;
  }

  int _totalSeatsForTheater(int theaterId) {
    final theater = theaters.firstWhere((theater) => theater['id'] == theaterId, orElse: () => {'total_seats': 0});
    return theater['total_seats'] ?? 0;
  }

  void _showSeatDialog({Seat? seat}) {
    final isEditing = seat != null;
    int selectedTheaterId = seat?.theaterId ?? (theaters.isNotEmpty ? theaters.first['id'] as int : 0);
    final labelController = TextEditingController(text: seat?.seatLabel ?? '');
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final seatCount = _seatCountForTheater(selectedTheaterId);
            final totalSeats = _totalSeatsForTheater(selectedTheaterId);
            final isFull = !isEditing && seatCount >= totalSeats && totalSeats > 0;
            return AlertDialog(
              title: Text(isEditing ? 'Edit Seat' : 'Add Seat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: selectedTheaterId,
                      items: theaters
                          .map((theater) => DropdownMenuItem(
                                value: theater['id'] as int,
                                child: Text(theater['name'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedTheaterId = value;
                          });
                        }
                      },
                    ),
                    Text('Total Seats: ' + _totalSeatsForTheater(selectedTheaterId).toString()),
                    Text('Current Seats: ' + _seatCountForTheater(selectedTheaterId).toString()),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: 'Seat Label (e.g. A1, B2)',
                        errorText: errorText,
                      ),
                      enabled: !isFull || isEditing,
                    ),
                    if (isFull && !isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Kapasitas kursi sudah penuh untuk theater ini.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
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
                  onPressed: (isFull && !isEditing)
                      ? null
                      : () async {
                          final label = labelController.text.trim().toUpperCase();
                          if (label.isEmpty) {
                            setStateDialog(() {
                              errorText = 'Seat label cannot be empty';
                            });
                            return;
                          }
                          if (isEditing) {
                            await updateSeat(Seat(id: seat!.id, theaterId: selectedTheaterId, seatLabel: label));
                          } else {
                            await addSeat(selectedTheaterId, label);
                          }
                          Navigator.of(context).pop();
                        },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _theaterName(int theaterId) {
    final theater = theaters.firstWhere((theater) => theater['id'] == theaterId, orElse: () => {'name': 'Unknown'});
    return theater['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    print('Building with ${theaters.length} theaters');
    print('Seat counts: ${theaters.map((t) => '${t['name']}: ${_seatCountForTheater(t['id'])}/${t['total_seats']}').join(', ')}');
    return Scaffold(
      appBar: AdminAppBar(title: ''),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: seats.length,
                itemBuilder: (context, index) {
                  final seat = seats[index];
                  final theaterName = _theaterName(seat.theaterId);
                  final badgeColor = Colors.blueAccent;
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
                          Icon(Icons.event_seat, size: 40, color: Colors.deepPurple),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seat.seatLabel,
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
                                    theaterName,
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
                                onPressed: () => _showSeatDialog(seat: seat),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => deleteSeat(seat.id),
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
      floatingActionButton: (theaters.isNotEmpty && theaters.any((theater) => _seatCountForTheater(theater['id']) < (theater['total_seats'] ?? 0)))
          ? FloatingActionButton(
              onPressed: () => _showSeatDialog(),
              child: Icon(Icons.add),
              tooltip: 'Add Seat',
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/admin/film');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/admin/theater');
          } else if (index == 2) {
            // Sudah di halaman seat
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/admin/showtime');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Film'),
          BottomNavigationBarItem(icon: Icon(Icons.theaters), label: 'Theater'),
          BottomNavigationBarItem(icon: Icon(Icons.event_seat), label: 'Seat'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Showtime'),
        ],
      ),
    );
  }
}
