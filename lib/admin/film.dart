import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../config/url_api.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_nav_bar.dart';
import '../theme.dart';

// Film model
class Film {
  int id;
  String title;
  String poster;
  String genre;
  String description;
  int durationMin;
  DateTime releaseDate;
  String status;

  Film({
    required this.id,
    required this.title,
    required this.poster,
    required this.genre,
    required this.description,
    required this.durationMin,
    required this.releaseDate,
    required this.status,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['film_id'],
      title: json['title'],
      poster: json['poster'] ?? '',
      genre: json['genre'] ?? '',
      description: json['description'] ?? '',
      durationMin: json['duration_min'] ?? 0,
      releaseDate: DateTime.parse(json['release_date']),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'poster': poster,
      'genre': genre,
      'description': description,
      'duration_min': durationMin,
      'release_date': releaseDate.toIso8601String().split('T')[0],
      'status': status,
    };
  }
}

class AdminFilmPage extends StatefulWidget {
  const AdminFilmPage({Key? key}) : super(key: key);

  @override
  State<AdminFilmPage> createState() => _AdminFilmPageState();
}

class _AdminFilmPageState extends State<AdminFilmPage> {
  List<Film> films = [];
  int _nextId = 1;
  final String baseUrl = '${UrlApi.baseUrl}/API';
  final _storage = const FlutterSecureStorage();
  Uint8List? localPosterBytes;
  String? pickedFileName;

  @override
  void initState() {
    super.initState();
    fetchFilms();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchFilms() async {
    final token = await _getToken();
    if (token == null) return;
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
  }

  Future<void> addFilm(Film film) async {
    final token = await _getToken();
    if (token == null) return;
    var uri = Uri.parse('$baseUrl/film/create');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = film.title;
    request.fields['genre'] = film.genre;
    request.fields['description'] = film.description;
    request.fields['duration_min'] = film.durationMin.toString();
    request.fields['release_date'] = film.releaseDate.toIso8601String().split('T')[0];
    request.fields['status'] = film.status;
    if (localPosterBytes != null && pickedFileName != null) {
      request.files.add(http.MultipartFile.fromBytes('poster', localPosterBytes!, filename: pickedFileName));
    }
    var response = await request.send();
    if (response.statusCode == 201) {
      fetchFilms();
    }
  }

  Future<void> updateFilm(Film film) async {
    final token = await _getToken();
    if (token == null) return;
    var uri = Uri.parse('$baseUrl/film/update/${film.id}');
    var request = http.MultipartRequest('PATCH', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = film.title;
    request.fields['genre'] = film.genre;
    request.fields['description'] = film.description;
    request.fields['duration_min'] = film.durationMin.toString();
    request.fields['release_date'] = film.releaseDate.toIso8601String().split('T')[0];
    request.fields['status'] = film.status;
    if (localPosterBytes != null && pickedFileName != null) {
      request.files.add(http.MultipartFile.fromBytes('poster', localPosterBytes!, filename: pickedFileName));
    }
    var response = await request.send();
    if (response.statusCode == 200) {
      fetchFilms();
      localPosterBytes = null;
      pickedFileName = null;
    }
  }

  Future<void> deleteFilm(int id) async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/film/delete/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      fetchFilms();
    }
  }

  void _showFilmDialog({Film? film}) {
    final isEditing = film != null;
    final titleController = TextEditingController(text: film?.title ?? '');
    final genreController = TextEditingController(text: film?.genre ?? '');
    final descriptionController = TextEditingController(text: film?.description ?? '');
    final durationController = TextEditingController(text: film?.durationMin.toString() ?? '');
    DateTime? selectedDate = film?.releaseDate;
    String status = film?.status ?? 'upcoming';

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit Film' : 'Add Film',
                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Color(0xFF1A237E)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1A237E)),
                        ),
                      ),
                    ),
                    TextField(
                      controller: genreController,
                      decoration: InputDecoration(
                        labelText: 'Genre',
                        labelStyle: TextStyle(color: Color(0xFF1A237E)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1A237E)),
                        ),
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Color(0xFF1A237E)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1A237E)),
                        ),
                      ),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (min)',
                        labelStyle: TextStyle(color: Color(0xFF1A237E)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1A237E)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    Row(
                      children: [
                        Text(selectedDate == null ? 'Release Date' : selectedDate!.toLocal().toString().split(' ')[0]),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: status,
                      items: [
                        DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                        DropdownMenuItem(value: 'now_showing', child: Text('Now Showing')),
                        DropdownMenuItem(value: 'ended', child: Text('Ended')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            status = value;
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null) {
                              setStateDialog(() {
                                pickedFileName = result.files.first.name;
                                localPosterBytes = result.files.first.bytes;
                              });
                              print('File picked: $pickedFileName');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1A237E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Pilih Gambar', style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 8),
                        if (pickedFileName != null)
                          Expanded(
                            child: Text(
                              'File: $pickedFileName',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
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
                    if (titleController.text.isEmpty ||
                        genreController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        durationController.text.isEmpty ||
                        selectedDate == null) {
                      return;
                    }
                    final newFilm = Film(
                      id: film?.id ?? 0,
                      title: titleController.text,
                      poster: film?.poster ?? '',
                      genre: genreController.text,
                      description: descriptionController.text,
                      durationMin: int.tryParse(durationController.text) ?? 0,
                      releaseDate: selectedDate!,
                      status: status,
                    );
                    if (isEditing) {
                      await updateFilm(newFilm);
                    } else {
                      await addFilm(newFilm);
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

  void _deleteFilm(int id) {
    setState(() {
      films.removeWhere((film) => film.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: 'Film'),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: films.length,
                itemBuilder: (context, index) {
                  final film = films[index];
                  Color statusColor;
                  String statusLabel;
                  switch (film.status) {
                    case 'now_showing':
                      statusColor = Color(0xFF43A047);
                      statusLabel = 'Now Showing';
                      break;
                    case 'ended':
                      statusColor = Color(0xFFD32F2F);
                      statusLabel = 'Ended';
                      break;
                    default:
                      statusColor = Color(0xFFFFC107);
                      statusLabel = 'Upcoming';
                  }
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Center(
                              child: Text(
                                film.title,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1A237E)),
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (film.poster.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        '${UrlApi.baseUrl}/images/${film.poster}',
                                        width: 160,
                                        height: 220,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.category, size: 18, color: Color(0xFF1A237E)),
                                      SizedBox(width: 6),
                                      Text(film.genre, style: TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.timer, size: 18, color: Colors.grey[700]),
                                      SizedBox(width: 6),
                                      Text('${film.durationMin} min', style: TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                                      SizedBox(width: 6),
                                      Text(film.releaseDate.toLocal().toString().split(' ')[0], style: TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Divider(),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E))),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    film.description,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Tutup', style: TextStyle(color: Colors.grey[700])),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: film.poster.isNotEmpty
                                  ? Image.network(
                                      '${UrlApi.baseUrl}/images/${film.poster}',
                                      width: 80,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 80,
                                      height: 110,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.movie, size: 40, color: Colors.grey[600]),
                                    ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          film.title,
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    film.genre,
                                    style: TextStyle(fontSize: 15, color: Color(0xFF0D47A1)),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text('${film.durationMin} min', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                      SizedBox(width: 16),
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(film.releaseDate.toLocal().toString().split(' ')[0], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Color(0xFF0D47A1)),
                                  onPressed: () => _showFilmDialog(film: film),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[400]),
                                  onPressed: () async {
                                    await deleteFilm(film.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
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
        onPressed: () => _showFilmDialog(),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF1A237E),
        tooltip: 'Add Film',
      ),
      bottomNavigationBar: AdminNavBar(currentIndex: 0, onTap: (index) {
        if (index == 1) {
          Navigator.pushReplacementNamed(context, '/admin/theater');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/admin/seat');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/admin/showtime');
        }
      }),
    );
  }
}
