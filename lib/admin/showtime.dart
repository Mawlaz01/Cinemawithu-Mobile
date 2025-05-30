import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/url_api.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_nav_bar.dart';
import '../theme.dart';

class Showtime {
  int id;
  int filmId;
  int theaterId;
  DateTime date;
  TimeOfDay time;
  double price;

  Showtime({
    required this.id,
    required this.filmId,
    required this.theaterId,
    required this.date,
    required this.time,
    required this.price,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    final timeParts = json['time'].split(':');
    final indonesianDate = date.add(Duration(hours: 7));
    
    return Showtime(
      id: json['showtime_id'],
      filmId: json['film_id'],
      theaterId: json['theater_id'],
      date: indonesianDate,
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      price: double.parse(json['price'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final indonesianDate = date.subtract(Duration(hours: 7));
    return {
      'film_id': filmId,
      'theater_id': theaterId,
      'date': indonesianDate.toIso8601String().split('T')[0],
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'price': price,
    };
  }
}

class Film {
  int id;
  String title;
  String status;

  Film({required this.id, required this.title, required this.status});

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['film_id'],
      title: json['title'],
      status: json['status'] ?? '',
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
  final String baseUrl = '${UrlApi.baseUrl}/API';
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
    final filteredFilms = films.where((film) => film.status == 'now_showing' ).toList();
    int selectedFilmId = showtime?.filmId ?? (filteredFilms.isNotEmpty ? filteredFilms.first.id : 0);
    int selectedTheaterId = showtime?.theaterId ?? (theaters.isNotEmpty ? theaters.first.id : 0);
    DateTime selectedDate = showtime?.date ?? DateTime.now();
    TimeOfDay? selectedTime = showtime?.time;
    final priceController = TextEditingController(text: showtime?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit Showtime' : 'Add Showtime',
                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: selectedFilmId,
                      items: filteredFilms
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
                        Text(selectedDate.toString().split(' ')[0]),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setStateDialog(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(selectedTime == null ? 'Start Time' : selectedTime!.format(context)),
                        IconButton(
                          icon: Icon(Icons.access_time, color: Color(0xFF1A237E)),
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
                      decoration: InputDecoration(
                        labelText: 'Price',
                        labelStyle: TextStyle(color: Color(0xFF1A237E)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1A237E)),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    if (selectedTime == null || priceController.text.isEmpty) {
                      return;
                    }
                    final newShowtime = Showtime(
                      id: showtime?.id ?? 0,
                      filmId: selectedFilmId,
                      theaterId: selectedTheaterId,
                      date: selectedDate,
                      time: selectedTime!,
                      price: double.tryParse(priceController.text) ?? 0.0,
                    );
                    if (isEditing) {
                      await updateShowtime(newShowtime);
                    } else {
                      await addShowtime(newShowtime);
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
      },
    );
  }

  String _filmTitle(int filmId) {
    return films.firstWhere((film) => film.id == filmId, orElse: () => Film(id: 0, title: 'Unknown', status: '')).title;
  }

  String _theaterName(int theaterId) {
    return theaters.firstWhere((theater) => theater.id == theaterId, orElse: () => Theater(id: 0, name: 'Unknown')).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: 'Showtime'),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: showtimes.length,
                itemBuilder: (context, index) {
                  final showtime = showtimes[index];
                  final filmTitle = _filmTitle(showtime.filmId);
                  final theaterName = _theaterName(showtime.theaterId);
                  final theaterBadgeColor = Color(0xFF1A237E);
                  final priceBadgeColor = Color(0xFF0D47A1);
                  final date = '${showtime.date.day.toString().padLeft(2, '0')}/${showtime.date.month.toString().padLeft(2, '0')}/${showtime.date.year}';
                  final time = '${showtime.time.hour.toString().padLeft(2, '0')}:${showtime.time.minute.toString().padLeft(2, '0')}';
                  final price = 'Rp${showtime.price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
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
                          Icon(Icons.schedule, size: 40, color: Color(0xFF1A237E)),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filmTitle,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theaterBadgeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    theaterName,
                                    style: TextStyle(color: theaterBadgeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                                    SizedBox(width: 4),
                                    Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                    SizedBox(width: 10),
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                                    SizedBox(width: 4),
                                    Text(time, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: priceBadgeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    price,
                                    style: TextStyle(color: priceBadgeColor, fontWeight: FontWeight.bold, fontSize: 13),
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
                                onPressed: () => _showShowtimeDialog(showtime: showtime),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400]),
                                onPressed: () => deleteShowtime(showtime.id),
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
        onPressed: () => _showShowtimeDialog(),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF1A237E),
        tooltip: 'Add Showtime',
      ),
      bottomNavigationBar: AdminNavBar(currentIndex: 3, onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/admin/film');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/admin/theater');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/admin/seat');
        }
      }),
    );
  }
}
