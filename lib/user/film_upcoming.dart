import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/user_app_bar.dart';
import '../widgets/user_nav_bar.dart';
import 'detail_film.dart';

class FilmUpcomingPage extends StatefulWidget {
  const FilmUpcomingPage({Key? key}) : super(key: key);

  @override
  State<FilmUpcomingPage> createState() => _FilmUpcomingPageState();
}

class _FilmUpcomingPageState extends State<FilmUpcomingPage> {
  List<dynamic>? upcomingFilms;
  bool isLoading = true;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.1.21:3000';

  @override
  void initState() {
    super.initState();
    fetchUpcomingFilms();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchUpcomingFilms() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/API/dashboard/upcoming'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          upcomingFilms = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Handle error
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserAppBar(title: ''),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : upcomingFilms == null
              ? const Center(child: Text('Failed to load upcoming films'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_right_alt, color: Color(0xFF1A4CA3)),
                          SizedBox(width: 8),
                          Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: upcomingFilms!.length,
                        itemBuilder: (context, index) {
                          final film = upcomingFilms![index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            shadowColor: Colors.black12,
                            margin: EdgeInsets.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailFilmPage(filmId: film['film_id'].toString()),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Image.network(
                                            '$baseUrl/images/${film['poster']}',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[300],
                                              child: Icon(Icons.movie, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFFFC107)]),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                            ),
                                            child: Text('PRESALE', style: TextStyle(color: Color(0xFF795548), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Column(
                                      children: [
                                        Text(
                                          film['title'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1A237E),
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          film['genre'] ?? '',
                                          style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: UserNavBar(
        currentIndex: 1, // Upcoming is the second tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/showing');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
