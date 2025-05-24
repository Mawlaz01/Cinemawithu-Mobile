import 'package:flutter/material.dart';


class UserNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const UserNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        selectedFontSize: 14,
        unselectedFontSize: 13,
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill),
            label: 'Playing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Upcoming',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
    );
  }
} 