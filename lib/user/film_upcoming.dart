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
  final String baseUrl = 'http://192.168.1.18:3000';

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
      backgroundColor: Colors.grey[100],
      appBar: const UserAppBar(title: ''),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
            )
          : upcomingFilms == null
              ? const Center(
                  child: Text(
                    'Failed to load upcoming films',
                    style: TextStyle(color: Color(0xFF1A237E)),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A237E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.access_time, color: Color(0xFF1A237E), size: 24),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Upcoming',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF1A237E),
                            ),
                          ),
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
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailFilmPage(
                                          filmId: film['film_id'].toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              '$baseUrl/images/${film['poster']}',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey[200],
                                                child: Icon(Icons.movie, size: 40, color: Colors.grey[400]),
                                              ),
                                            ),
                                            Positioned(
                                              top: 10,
                                              left: 10,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFFFFE082),
                                                      Color(0xFFFFC107),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  'PRESALE',
                                                  style: TextStyle(
                                                    color: Color(0xFF795548),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                film['title'] ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1A237E),
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                film['genre'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: UserNavBar(
        currentIndex: 1,
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
