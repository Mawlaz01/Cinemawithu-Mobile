import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../widgets/admin_app_bar.dart';

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
  final String baseUrl = 'http://localhost:3000/API';
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
              title: Text(isEditing ? 'Edit Film' : 'Add Film'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: genreController,
                      decoration: InputDecoration(labelText: 'Genre'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(labelText: 'Duration (min)'),
                      keyboardType: TextInputType.number,
                    ),
                    Row(
                      children: [
                        Text(selectedDate == null ? 'Release Date' : selectedDate!.toLocal().toString().split(' ')[0]),
                        IconButton(
                          icon: Icon(Icons.calendar_today),
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
                          child: Text('Pilih Gambar'),
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
                  child: Text('Cancel'),
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
                  child: Text(isEditing ? 'Save' : 'Add'),
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
      appBar: AdminAppBar(title: ''),
      body: ListView.builder(
        itemCount: films.length,
        itemBuilder: (context, index) {
          final film = films[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: film.poster.isNotEmpty
                  ? Image.network(
                      'http://localhost:3000/images/${film.poster}',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(width: 50, height: 80, color: Colors.grey),
              title: Text(film.title),
              subtitle: Text('${film.genre} | ${film.durationMin} min | ${film.status}'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Detail Film'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (film.poster.isNotEmpty)
                              Center(
                                child: Image.network(
                                  'http://localhost:3000/images/${film.poster}',
                                  width: 120,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            SizedBox(height: 16),
                            Text('Judul: ${film.title}', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Genre: ${film.genre}'),
                            SizedBox(height: 8),
                            Text('Deskripsi: ${film.description}'),
                            SizedBox(height: 8),
                            Text('Durasi: ${film.durationMin} menit'),
                            SizedBox(height: 8),
                            Text('Rilis: ${film.releaseDate.toLocal().toString().split(' ')[0]}'),
                            SizedBox(height: 8),
                            Text('Status: ${film.status}'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Tutup'),
                        ),
                      ],
                    );
                  },
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showFilmDialog(film: film),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await deleteFilm(film.id);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilmDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Film',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // Sudah di halaman film
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/admin/theater');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/admin/seat');
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
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
