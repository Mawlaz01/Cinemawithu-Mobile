import 'package:flutter/material.dart';

// Dummy data for theaters
final dummyTheaters = [
  {'id': 1, 'name': 'Theater 1'},
  {'id': 2, 'name': 'Theater 2'},
];

class Seat {
  int id;
  int theaterId;
  String seatLabel;

  Seat({
    required this.id,
    required this.theaterId,
    required this.seatLabel,
  });
}

class AdminSeatPage extends StatefulWidget {
  const AdminSeatPage({Key? key}) : super(key: key);

  @override
  State<AdminSeatPage> createState() => _AdminSeatPageState();
}

class _AdminSeatPageState extends State<AdminSeatPage> {
  List<Seat> seats = [];
  int _nextId = 1;

  void _showSeatDialog({Seat? seat}) {
    final isEditing = seat != null;
    int selectedTheaterId = seat?.theaterId ?? (dummyTheaters.first['id'] as int);
    final labelController = TextEditingController(text: seat?.seatLabel ?? '');
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Seat' : 'Add Seat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          setStateDialog(() {
                            selectedTheaterId = value;
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: 'Seat Label (e.g. A1, B2)',
                        errorText: errorText,
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
                  onPressed: () {
                    final label = labelController.text.trim().toUpperCase();
                    if (label.isEmpty) {
                      setStateDialog(() {
                        errorText = 'Seat label cannot be empty';
                      });
                      return;
                    }
                    final exists = seats.any((s) =>
                      s.theaterId == selectedTheaterId &&
                      s.seatLabel.toUpperCase() == label &&
                      (!isEditing || s.id != seat!.id)
                    );
                    if (exists) {
                      setStateDialog(() {
                        errorText = 'Seat label already exists in this theater';
                      });
                      return;
                    }
                    setState(() {
                      if (isEditing) {
                        seat!.theaterId = selectedTheaterId;
                        seat.seatLabel = label;
                      } else {
                        seats.add(Seat(
                          id: _nextId++,
                          theaterId: selectedTheaterId,
                          seatLabel: label,
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
      },
    );
  }

  void _deleteSeat(int id) {
    setState(() {
      seats.removeWhere((seat) => seat.id == id);
    });
  }

  String _theaterName(int theaterId) {
    return dummyTheaters.firstWhere((theater) => theater['id'] == theaterId)['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Seat Management'),
      ),
      body: ListView.builder(
        itemCount: seats.length,
        itemBuilder: (context, index) {
          final seat = seats[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${seat.seatLabel}'),
              subtitle: Text(_theaterName(seat.theaterId)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showSeatDialog(seat: seat),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteSeat(seat.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSeatDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Seat',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/admin/film');
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
