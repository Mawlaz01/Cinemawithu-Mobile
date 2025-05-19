import 'package:flutter/material.dart';
import '../theme.dart';

class AdminNavBar extends StatelessWidget {
  final int currentIndex;

  const AdminNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppColors.blue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/admin/film');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/admin/theater');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/admin/seat');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/admin/showtime');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Film'),
        BottomNavigationBarItem(icon: Icon(Icons.theaters), label: 'Theater'),
        BottomNavigationBarItem(icon: Icon(Icons.event_seat), label: 'Seat'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Showtime'),
      ],
    );
  }
} 