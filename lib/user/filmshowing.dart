import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/user_app_bar.dart';
import '../widgets/user_nav_bar.dart';
import 'detailfilm.dart';

class FilmShowingPage extends StatefulWidget {
  const FilmShowingPage({Key? key}) : super(key: key);

  @override
  State<FilmShowingPage> createState() => _FilmShowingPageState();
}

class _FilmShowingPageState extends State<FilmShowingPage> {
  List<dynamic>? showingFilms;
  bool isLoading = true;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    fetchShowingFilms();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchShowingFilms() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/API/dashboard/showing'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          showingFilms = data['data'];
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
          : showingFilms == null
              ? const Center(child: Text('Failed to load showing films'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.local_movies, color: Color(0xFF1A4CA3)),
                          SizedBox(width: 8),
                          Text('Playing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                        itemCount: showingFilms!.length,
                        itemBuilder: (context, index) {
                          final film = showingFilms![index];
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
                                    child: ClipRRect(
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
                                        SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF2563EB),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size(0, 36),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                              elevation: 0,
                                            ),
                                            onPressed: () {/* aksi beli tiket */},
                                            child: Text('BUY TICKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, letterSpacing: 1)),
                                          ),
                                        ),
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
        currentIndex: 0, // Showing is the first tab
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/upcoming');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
