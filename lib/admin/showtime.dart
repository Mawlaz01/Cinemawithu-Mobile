import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/admin_app_bar.dart';

class Showtime {
  int id;
  int filmId;
  int theaterId;
  DateTime startTime;
  double price;

  Showtime({
    required this.id,
    required this.filmId,
    required this.theaterId,
    required this.startTime,
    required this.price,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    return Showtime(
      id: json['showtime_id'],
      filmId: json['film_id'],
      theaterId: json['theater_id'],
      startTime: DateTime.parse(json['start_time']),
      price: double.parse(json['price'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'film_id': filmId,
      'theater_id': theaterId,
      'start_time': startTime.toIso8601String(),
      'price': price,
    };
  }
}

class Film {
  int id;
  String title;

  Film({required this.id, required this.title});

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['film_id'],
      title: json['title'],
    );
  }
}

class Theater {
  int id;
  String name;

  Theater({required this.id, required this.name});

  factory Theater.fromJson(Map<String, dynamic> json) {
    return Theater(
      id: json['theater_id'],
      name: json['name'],
    );
  }
}

class AdminShowtimePage extends StatefulWidget {
  const AdminShowtimePage({Key? key}) : super(key: key);

  @override
  State<AdminShowtimePage> createState() => _AdminShowtimePageState();
}

class _AdminShowtimePageState extends State<AdminShowtimePage> {
  List<Showtime> showtimes = [];
  List<Film> films = [];
  List<Theater> theaters = [];
  final String baseUrl = 'http://localhost:3000/API';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchShowtimes();
    fetchFilms();
    fetchTheaters();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchShowtimes() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/showtime'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          showtimes = data.map((json) => Showtime.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error fetching showtimes: $e');
    }
  }

  Future<void> fetchFilms() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/film'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          films = data.map((json) => Film.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error fetching films: $e');
    }
  }

  Future<void> fetchTheaters() async {
    final token = await _getToken();
    if (token == null) return;
    try {
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
    } catch (e) {
      print('Error fetching theaters: $e');
    }
  }

  Future<void> addShowtime(Showtime showtime) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/showtime/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(showtime.toJson()),
      );
      if (response.statusCode == 201) {
        fetchShowtimes();
      } else {
        final error = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print('Error adding showtime: $e');
    }
  }

  Future<void> updateShowtime(Showtime showtime) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/showtime/update/${showtime.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(showtime.toJson()),
      );
      if (response.statusCode == 200) {
        fetchShowtimes();
      } else {
        final error = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print('Error updating showtime: $e');
    }
  }

  Future<void> deleteShowtime(int id) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/showtime/delete/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchShowtimes();
      } else {
        final error = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print('Error deleting showtime: $e');
    }
  }

  void _showShowtimeDialog({Showtime? showtime}) {
    final isEditing = showtime != null;
    int selectedFilmId = showtime?.filmId ?? (films.isNotEmpty ? films.first.id : 0);
    int selectedTheaterId = showtime?.theaterId ?? (theaters.isNotEmpty ? theaters.first.id : 0);
    TimeOfDay? selectedTime = showtime != null ? TimeOfDay(hour: showtime.startTime.hour, minute: showtime.startTime.minute) : null;
    final priceController = TextEditingController(text: showtime?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Showtime' : 'Add Showtime'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: selectedFilmId,
                      items: films
                          .map((film) => DropdownMenuItem(
                                value: film.id,
                                child: Text(film.title),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedFilmId = value;
                          });
                        }
                      },
                    ),
                    DropdownButton<int>(
                      value: selectedTheaterId,
                      items: theaters
                          .map((theater) => DropdownMenuItem(
                                value: theater.id,
                                child: Text(theater.name),
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
                    Row(
                      children: [
                        Text(selectedTime == null ? 'Start Time' : selectedTime!.format(context)),
                        IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setStateDialog(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    if (selectedTime == null || priceController.text.isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    final startDateTime = DateTime(now.year, now.month, now.day, selectedTime!.hour, selectedTime!.minute);
                    final newShowtime = Showtime(
                      id: showtime?.id ?? 0,
                      filmId: selectedFilmId,
                      theaterId: selectedTheaterId,
                      startTime: startDateTime,
                      price: double.tryParse(priceController.text) ?? 0.0,
                    );
                    if (isEditing) {
                      await updateShowtime(newShowtime);
                    } else {
                      await addShowtime(newShowtime);
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

  String _filmTitle(int filmId) {
    return films.firstWhere((film) => film.id == filmId, orElse: () => Film(id: 0, title: 'Unknown')).title;
  }

  String _theaterName(int theaterId) {
    return theaters.firstWhere((theater) => theater.id == theaterId, orElse: () => Theater(id: 0, name: 'Unknown')).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: ''),
      body: ListView.builder(
        itemCount: showtimes.length,
        itemBuilder: (context, index) {
          final showtime = showtimes[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${_filmTitle(showtime.filmId)} @ ${_theaterName(showtime.theaterId)}'),
              subtitle: Text('${showtime.startTime.hour.toString().padLeft(2, '0')}:${showtime.startTime.minute.toString().padLeft(2, '0')} | Rp${showtime.price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showShowtimeDialog(showtime: showtime),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteShowtime(showtime.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShowtimeDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Showtime',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/admin/film');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/admin/theater');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/admin/seat');
          } else if (index == 3) {
            // Sudah di halaman showtime
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Film'),
          BottomNavigationBarItem(icon: Icon(Icons.theaters), label: 'Theater'),
          BottomNavigationBarItem(icon: Icon(Icons.event_seat), label: 'Seat'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Showtime'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
