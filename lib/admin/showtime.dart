import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/url_api.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_nav_bar.dart';
import '../theme.dart';

class Showtime {
  int showtimeId;
  int filmId;
  int theaterId;
  DateTime date;
  TimeOfDay time;
  double price;

  Showtime({
    required this.showtimeId,
    required this.filmId,
    required this.theaterId,
    required this.date,
    required this.time,
    required this.price,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    // Ensure the date is parsed as a local date
    final date = DateTime.parse(json['date']).toLocal();
    final timeParts = json['time'].split(':');
    
    return Showtime(
      showtimeId: json['showtime_id'],
      filmId: json['film_id'],
      theaterId: json['theater_id'],
      date: date,
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      price: double.parse(json['price'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'film_id': filmId,
      'theater_id': theaterId,
      'date': date.toIso8601String().split('T')[0],
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'price': price,
    };
  }
}

class Film {
  int filmId;
  String title;
  String status;
  int durationMin;

  Film({
    required this.filmId,
    required this.title,
    required this.status,
    required this.durationMin,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      filmId: json['film_id'],
      title: json['title'],
      status: json['status'] ?? '',
      durationMin: json['duration_min'] ?? 0,
    );
  }
}

class Theater {
  int theaterId;
  String name;
  int totalSeats;

  Theater({
    required this.theaterId,
    required this.name,
    required this.totalSeats,
  });

  factory Theater.fromJson(Map<String, dynamic> json) {
    return Theater(
      theaterId: json['theater_id'],
      name: json['name'],
      totalSeats: json['total_seats'],
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
  List<Showtime> filteredShowtimes = [];
  List<Film> films = [];
  List<Theater> theaters = [];
  final String baseUrl = '${UrlApi.baseUrl}/API';
  final _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  Future<int> _getFilmDuration(int filmId) async {
    final film = films.firstWhere((f) => f.filmId == filmId);
    return film.durationMin;
  }

  bool _isShowtimePassed(Showtime showtime) {
    final now = DateTime.now(); // Current local time
    
    // Combine showtime date and time into a local DateTime
    final showtimeStartLocal = DateTime(
      showtime.date.year,
      showtime.date.month,
      showtime.date.day,
      showtime.time.hour,
      showtime.time.minute,
    );

    // Get film duration (assuming it's already fetched)
    final filmDuration = films.firstWhere((f) => f.filmId == showtime.filmId, orElse: () => Film(filmId: 0, title: '', status: '', durationMin: 0)).durationMin;

    // Calculate showtime end time in local time
    final showtimeEndLocal = showtimeStartLocal.add(Duration(minutes: filmDuration));

    // Calculate current time and showtime end time in WIB (UTC+7)
    final wibOffset = Duration(hours: 7);
    final nowWib = now.add(wibOffset);
    final showtimeEndWib = showtimeEndLocal.add(wibOffset);
    
    // A showtime is passed if the current WIB time is after the showtime end time in WIB
    return nowWib.isAfter(showtimeEndWib);
  }

  Future<bool> _hasScheduleConflict(Showtime newShowtime, {int? excludeShowtimeId}) async {
    final filmDuration = await _getFilmDuration(newShowtime.filmId);
    final newShowtimeStart = DateTime(
      newShowtime.date.year,
      newShowtime.date.month,
      newShowtime.date.day,
      newShowtime.time.hour,
      newShowtime.time.minute,
    );
    final newShowtimeEnd = newShowtimeStart.add(Duration(minutes: filmDuration));

    // Validasi waktu mulai tidak boleh di masa lalu
    if (newShowtimeStart.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Waktu mulai tidak boleh di masa lalu!'),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }

    // Validasi durasi film minimal 30 menit
    if (filmDuration < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durasi film minimal 30 menit!'),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }

    // Validasi waktu mulai tidak boleh lebih dari 30 hari ke depan
    if (newShowtimeStart.isAfter(DateTime.now().add(Duration(days: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal tidak boleh lebih dari 30 hari ke depan!'),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }

    // Validasi waktu mulai harus antara jam 08:00 - 22:00
    if (newShowtime.time.hour < 8 || newShowtime.time.hour >= 22) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal harus antara jam 08:00 - 22:00!'),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }

    // Validasi waktu selesai tidak boleh melewati jam 23:00
    final endTime = newShowtimeEnd.hour + (newShowtimeEnd.minute / 60);
    if (endTime > 23) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Film harus selesai sebelum jam 23:00!'),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }

    for (var existingShowtime in showtimes) {
      if (excludeShowtimeId != null && existingShowtime.showtimeId == excludeShowtimeId) continue;
      if (existingShowtime.theaterId != newShowtime.theaterId) continue;

      final existingFilmDuration = await _getFilmDuration(existingShowtime.filmId);
      final existingStart = DateTime(
        existingShowtime.date.year,
        existingShowtime.date.month,
        existingShowtime.date.day,
        existingShowtime.time.hour,
        existingShowtime.time.minute,
      );
      final existingEnd = existingStart.add(Duration(minutes: existingFilmDuration + 15)); // Add 15 minutes buffer

      // Check for conflicts
      if ((newShowtimeStart.isBefore(existingEnd) && newShowtimeEnd.isAfter(existingStart))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jadwal bentrok dengan film lain di theater yang sama!'),
            backgroundColor: Colors.red,
          ),
        );
        return true;
      }
    }
    return false;
  }

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

  void _filterShowtimes(String query) {
    setState(() {
      filteredShowtimes = showtimes.where((showtime) {
        final filmTitle = _filmTitle(showtime.filmId).toLowerCase();
        final theaterName = _theaterName(showtime.theaterId).toLowerCase();
        return filmTitle.contains(query.toLowerCase()) ||
               theaterName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final allShowtimes = data.map((json) => Showtime.fromJson(json)).toList();
        setState(() {
          // Filter out past showtimes using WIB time
          showtimes = allShowtimes.where((showtime) => !_isShowtimePassed(showtime)).toList();
          filteredShowtimes = showtimes;
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
        Uri.parse('$baseUrl/showtime/update/${showtime.showtimeId}'),
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
    final filteredFilms = films.where((film) => film.status == 'now_showing').toList();
    int selectedFilmId = showtime?.filmId ?? (filteredFilms.isNotEmpty ? filteredFilms.first.filmId : 0);
    int selectedTheaterId = showtime?.theaterId ?? (theaters.isNotEmpty ? theaters.first.theaterId : 0);
    DateTime selectedDate = showtime?.date ?? DateTime.now();
    TimeOfDay? selectedTime = showtime?.time;
    final priceController = TextEditingController(text: showtime?.price.toString() ?? '');

    // Format date for display
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    // Validasi harga minimal
    void validatePrice(String value) {
      if (value.isEmpty) return;
      final price = double.tryParse(value);
      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harga harus berupa angka!'),
            backgroundColor: Colors.red,
          ),
        );
        priceController.text = '0';
      }
    }

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
                                value: film.filmId,
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
                                value: theater.theaterId,
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
                        Text(formatDate(selectedDate)),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 30)),
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
                              initialTime: selectedTime ?? TimeOfDay(hour: 8, minute: 0),
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    alwaysUse24HourFormat: true,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              // Validasi waktu mulai harus antara jam 08:00 - 22:00
                              if (pickedTime.hour < 8 || pickedTime.hour >= 22) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Jadwal harus antara jam 08:00 - 22:00!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
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
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: validatePrice,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Semua field harus diisi!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newShowtime = Showtime(
                      showtimeId: showtime?.showtimeId ?? 0,
                      filmId: selectedFilmId,
                      theaterId: selectedTheaterId,
                      date: selectedDate,
                      time: selectedTime!,
                      price: double.tryParse(priceController.text) ?? 0.0,
                    );

                    // Check for schedule conflicts
                    final hasConflict = await _hasScheduleConflict(
                      newShowtime,
                      excludeShowtimeId: isEditing ? showtime?.showtimeId : null,
                    );

                    if (hasConflict) {
                      return;
                    }

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
    return films.firstWhere(
      (film) => film.filmId == filmId,
      orElse: () => Film(filmId: 0, title: 'Unknown', status: '', durationMin: 0)
    ).title;
  }

  String _theaterName(int theaterId) {
    return theaters.firstWhere(
      (theater) => theater.theaterId == theaterId,
      orElse: () => Theater(theaterId: 0, name: 'Unknown', totalSeats: 0)
    ).name;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search films or theaters...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1A237E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF1A237E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF1A237E)),
                  ),
                ),
                onChanged: _filterShowtimes,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredShowtimes.length,
                itemBuilder: (context, index) {
                  final showtime = filteredShowtimes[index];
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
                                onPressed: () => deleteShowtime(showtime.showtimeId),
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
