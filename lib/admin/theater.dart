import 'package:flutter/material.dart';

class Theater {
  int id;
  String name;
  int totalSeats;

  Theater({
    required this.id,
    required this.name,
    required this.totalSeats,
  });
}

class AdminTheaterPage extends StatefulWidget {
  const AdminTheaterPage({Key? key}) : super(key: key);

  @override
  State<AdminTheaterPage> createState() => _AdminTheaterPageState();
}

class _AdminTheaterPageState extends State<AdminTheaterPage> {
  List<Theater> theaters = [];
  int _nextId = 1;

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
              onPressed: () {
                if (nameController.text.isEmpty || seatsController.text.isEmpty) {
                  return;
                }
                setState(() {
                  if (isEditing) {
                    theater!.name = nameController.text;
                    theater.totalSeats = int.tryParse(seatsController.text) ?? 0;
                  } else {
                    theaters.add(Theater(
                      id: _nextId++,
                      name: nameController.text,
                      totalSeats: int.tryParse(seatsController.text) ?? 0,
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

  void _deleteTheater(int id) {
    setState(() {
      theaters.removeWhere((theater) => theater.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Theater Management'),
      ),
      body: ListView.builder(
        itemCount: theaters.length,
        itemBuilder: (context, index) {
          final theater = theaters[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(theater.name),
              subtitle: Text('Total Seats: ${theater.totalSeats}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showTheaterDialog(theater: theater),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTheater(theater.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTheaterDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Theater',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/admin/film');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/admin/seat');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/admin/showtime');
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
