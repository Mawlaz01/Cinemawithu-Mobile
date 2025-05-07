import 'package:flutter/material.dart';

// Dummy data for films and theaters
final dummyFilms = [
  {'id': 1, 'title': 'Film A'},
  {'id': 2, 'title': 'Film B'},
];
final dummyTheaters = [
  {'id': 1, 'name': 'Theater 1'},
  {'id': 2, 'name': 'Theater 2'},
];

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
}

class AdminShowtimePage extends StatefulWidget {
  const AdminShowtimePage({Key? key}) : super(key: key);

  @override
  State<AdminShowtimePage> createState() => _AdminShowtimePageState();
}

class _AdminShowtimePageState extends State<AdminShowtimePage> {
  List<Showtime> showtimes = [];
  int _nextId = 1;

  void _showShowtimeDialog({Showtime? showtime}) {
    final isEditing = showtime != null;
    int selectedFilmId = showtime?.filmId ?? (dummyFilms.first['id'] as int);
    int selectedTheaterId = showtime?.theaterId ?? (dummyTheaters.first['id'] as int);
    TimeOfDay? selectedTime = showtime != null ? TimeOfDay(hour: showtime.startTime.hour, minute: showtime.startTime.minute) : null;
    final priceController = TextEditingController(text: showtime?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Showtime' : 'Add Showtime'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: selectedFilmId,
                  items: dummyFilms
                      .map((film) => DropdownMenuItem(
                            value: film['id'] as int,
                            child: Text(film['title'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedFilmId = value;
                      });
                    }
                  },
                ),
                DropdownButton<int>(
                  value: selectedTheaterId,
                  items: dummyTheaters
                      .map((theater) => DropdownMenuItem(
                            value: theater['id'] as int,
                            child: Text(theater['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
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
                          setState(() {
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
              onPressed: () {
                if (selectedTime == null || priceController.text.isEmpty) {
                  return;
                }
                setState(() {
                  final now = DateTime.now();
                  final startDateTime = DateTime(now.year, now.month, now.day, selectedTime!.hour, selectedTime!.minute);
                  if (isEditing) {
                    showtime!.filmId = selectedFilmId;
                    showtime.theaterId = selectedTheaterId;
                    showtime.startTime = startDateTime;
                    showtime.price = double.tryParse(priceController.text) ?? 0.0;
                  } else {
                    showtimes.add(Showtime(
                      id: _nextId++,
                      filmId: selectedFilmId,
                      theaterId: selectedTheaterId,
                      startTime: startDateTime,
                      price: double.tryParse(priceController.text) ?? 0.0,
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

  void _deleteShowtime(int id) {
    setState(() {
      showtimes.removeWhere((showtime) => showtime.id == id);
    });
  }

  String _filmTitle(int filmId) {
    return dummyFilms.firstWhere((film) => film['id'] == filmId)['title'] as String;
  }

  String _theaterName(int theaterId) {
    return dummyTheaters.firstWhere((theater) => theater['id'] == theaterId)['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Showtime Management'),
      ),
      body: ListView.builder(
        itemCount: showtimes.length,
        itemBuilder: (context, index) {
          final showtime = showtimes[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${_filmTitle(showtime.filmId)} @ ${_theaterName(showtime.theaterId)}'),
              subtitle: Text('${showtime.startTime.hour.toString().padLeft(2, '0')}:${showtime.startTime.minute.toString().padLeft(2, '0')} | Rp${showtime.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showShowtimeDialog(showtime: showtime),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteShowtime(showtime.id),
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
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/admin/film');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/admin/seat');
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
