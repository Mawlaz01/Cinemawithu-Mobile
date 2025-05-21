import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'admin/film.dart';
import 'admin/showtime.dart';
import 'admin/theater.dart';
import 'admin/seat.dart';
import 'user/filmshowing.dart';
import 'user/filmupcoming.dart';
import 'user/profile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/admin/film': (_) => AdminFilmPage(),
        '/admin/showtime': (_) => AdminShowtimePage(),
        '/admin/theater': (_) => AdminTheaterPage(),
        '/admin/seat': (_) => AdminSeatPage(),
        '/showing': (_) => const FilmShowingPage(),
        '/upcoming': (_) => const FilmUpcomingPage(),
        '/profile': (_) => const ProfilePage(),
      },
    );
  }
}