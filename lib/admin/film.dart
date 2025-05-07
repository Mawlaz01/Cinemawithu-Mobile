import 'package:flutter/material.dart';

// Film model
class Film {
  int id;
  String title;
  String poster;
  String genre;
  String description;
  int durationMin;
  DateTime releaseDate;
  String status; // 'upcoming', 'now_showing', 'ended'

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
}

class AdminFilmPage extends StatefulWidget {
  const AdminFilmPage({Key? key}) : super(key: key);

  @override
  State<AdminFilmPage> createState() => _AdminFilmPageState();
}

class _AdminFilmPageState extends State<AdminFilmPage> {
  List<Film> films = [];
  int _nextId = 1;

  void _showFilmDialog({Film? film}) {
    final isEditing = film != null;
    final titleController = TextEditingController(text: film?.title ?? '');
    final posterController = TextEditingController(text: film?.poster ?? '');
    final genreController = TextEditingController(text: film?.genre ?? '');
    final descriptionController = TextEditingController(text: film?.description ?? '');
    final durationController = TextEditingController(text: film?.durationMin.toString() ?? '');
    DateTime? selectedDate = film?.releaseDate;
    String status = film?.status ?? 'upcoming';

    showDialog(
      context: context,
      builder: (context) {
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
                  controller: posterController,
                  decoration: InputDecoration(labelText: 'Poster URL'),
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
                          setState(() {
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
                      setState(() {
                        status = value;
                      });
                    }
                  },
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
              onPressed: () {
                if (titleController.text.isEmpty ||
                    posterController.text.isEmpty ||
                    genreController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    durationController.text.isEmpty ||
                    selectedDate == null) {
                  return;
                }
                setState(() {
                  if (isEditing) {
                    film!.title = titleController.text;
                    film.poster = posterController.text;
                    film.genre = genreController.text;
                    film.description = descriptionController.text;
                    film.durationMin = int.tryParse(durationController.text) ?? 0;
                    film.releaseDate = selectedDate!;
                    film.status = status;
                  } else {
                    films.add(Film(
                      id: _nextId++,
                      title: titleController.text,
                      poster: posterController.text,
                      genre: genreController.text,
                      description: descriptionController.text,
                      durationMin: int.tryParse(durationController.text) ?? 0,
                      releaseDate: selectedDate!,
                      status: status,
                    ));
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
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
      appBar: AppBar(
        title: Text('Admin Film Management'),
      ),
      body: ListView.builder(
        itemCount: films.length,
        itemBuilder: (context, index) {
          final film = films[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: film.poster.isNotEmpty
                  ? Image.network(film.poster, width: 50, height: 80, fit: BoxFit.cover)
                  : Container(width: 50, height: 80, color: Colors.grey),
              title: Text(film.title),
              subtitle: Text('${film.genre} | ${film.durationMin} min | ${film.status}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showFilmDialog(film: film),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteFilm(film.id),
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
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/admin/seat');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/admin/showtime');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/admin/theater');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Film'),
          BottomNavigationBarItem(icon: Icon(Icons.event_seat), label: 'Seat'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Showtime'),
          BottomNavigationBarItem(icon: Icon(Icons.theaters), label: 'Theater'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
