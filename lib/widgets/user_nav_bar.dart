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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: Color(0xFF1A237E),
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentIndex == 0 ? Color(0xFF1A237E).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_circle_fill),
              ),
              label: 'Playing',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentIndex == 1 ? Color(0xFF1A237E).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.access_time),
              ),
              label: 'Upcoming',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentIndex == 2 ? Color(0xFF1A237E).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
} 