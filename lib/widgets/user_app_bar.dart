import 'package:flutter/material.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const UserAppBar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Image.asset(
          'assets/images/logo_cinema.png',
          height: 36,
        ),
      ),
      actions: actions,
      iconTheme: const IconThemeData(color: Color(0xFF1A4CA3)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 