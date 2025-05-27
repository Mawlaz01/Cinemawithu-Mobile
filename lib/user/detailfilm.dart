import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/user_app_bar.dart';
import 'booking.dart';

class DetailFilmPage extends StatefulWidget {
  final String filmId;
  
  const DetailFilmPage({Key? key, required this.filmId}) : super(key: key);

  @override
  State<DetailFilmPage> createState() => _DetailFilmPageState();
}

class _DetailFilmPageState extends State<DetailFilmPage> {
  Map<String, dynamic>? filmData;
  bool isLoading = true;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchFilmDetail();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchFilmDetail() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/API/dashboard/detailfilm/${widget.filmId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          filmData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length != 3) return dateStr;
    
    final day = parts[0];
    final month = int.parse(parts[1]);
    final year = parts[2];
    
    final bulan = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
    ][month];
    
    return '$day $bulan';
  }

  String _formatTime(String timeStr) {
    // Assuming timeStr is in format "HH:mm:ss"
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      // Convert to Indonesian time (UTC+7)
      int hour = int.parse(parts[0]);
      hour = (hour + 7) % 24; // Add 7 hours and handle overflow
      return '${hour.toString().padLeft(2, '0')}.${parts[1]}';
    }
    return timeStr;
  }

  List<dynamic> _getShowtimesForDate(DateTime date) {
    if (filmData == null || filmData!['showtimes'] == null) return [];
    
    final showtimes = filmData!['showtimes'] as List;
    return showtimes.where((showtime) {
      final showtimeDate = DateTime.parse(showtime['date']);
      return showtimeDate.year == date.year && 
             showtimeDate.month == date.month && 
             showtimeDate.day == date.day;
    }).toList();
  }

  List<DateTime> _getAvailableDates() {
    if (filmData == null || filmData!['showtimes'] == null) return [];
    
    final showtimes = filmData!['showtimes'] as List;
    final dates = showtimes.map((showtime) {
      return DateTime.parse(showtime['date']);
    }).toSet().toList();
    
    dates.sort();
    return dates;
  }

  void _showOrderDialog(Map<String, dynamic> showtime) {
    int ticketCount = 1;
    int maxTicket = 4;
    int price = showtime['price'] is int ? showtime['price'] : int.tryParse(showtime['price'].toString()) ?? 0;
    int totalPrice = price;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filmData!['film']['title'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${showtime['theater_name']} - ${_formatDate(showtime['formatted_date'])}, ${_formatTime(showtime['time'])}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Jumlah tiket (max. 4 tiket)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      Text('Total Harga', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red, size: 30),
                            onPressed: ticketCount > 1
                                ? () {
                                    setStateDialog(() {
                                      ticketCount--;
                                      totalPrice = price * ticketCount;
                                    });
                                  }
                                : null,
                          ),
                          Text('$ticketCount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: Colors.blue, size: 30),
                            onPressed: ticketCount < maxTicket
                                ? () {
                                    setStateDialog(() {
                                      ticketCount++;
                                      totalPrice = price * ticketCount;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      Text('Rp ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(
                              filmId: widget.filmId,
                              showtimeId: showtime['showtime_id'].toString(),
                              maxSeat: ticketCount,
                            ),
                          ),
                        );
                      },
                      child: Text('Pilih Bangku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showtimes = filmData?['showtimes'] ?? [];
    final availableDates = _getAvailableDates();
    
    if (selectedDate == null && availableDates.isNotEmpty) {
      selectedDate = availableDates.first;
    }
    
    final selectedShowtimes = selectedDate != null ? _getShowtimesForDate(selectedDate!) : [];
    
    return Scaffold(
      appBar: const UserAppBar(title: 'Film Detail'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filmData == null
              ? const Center(child: Text('Failed to load film details'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Atas: Poster + Detail
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster
                            Container(
                              height: 180,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  '$baseUrl/images/${filmData!['film']['poster']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.movie, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Detail Film
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filmData!['film']['title'],
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    filmData!['film']['genre'],
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                                      SizedBox(width: 4),
                                      Text(
                                        '${filmData!['film']['duration_min']} min',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Deskripsi
                        Text(
                          'Deskripsi Film',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Text(
                          filmData!['film']['description'],
                          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        ),
                        SizedBox(height: 24),
                        
                        // Date Selector
                        if (filmData!['film']['status'] == 'now_showing' && availableDates.isNotEmpty) ...[
                          Text(
                            'Pilih Tanggal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: availableDates.map((date) {
                                final isSelected = selectedDate?.year == date.year &&
                                                 selectedDate?.month == date.month &&
                                                 selectedDate?.day == date.day;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedDate = date;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Color(0xFF2563EB) : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _formatDate('${date.day}/${date.month}/${date.year}'),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                        
                        // Showtimes Section
                        if (filmData!['film']['status'] == 'now_showing' && selectedShowtimes.isNotEmpty) ...[
                          ...selectedShowtimes.map((showtime) {
                            String hargaStr = showtime['price'].toString();
                            hargaStr = hargaStr.replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.'
                            );
                            return Card(
                              color: Colors.white,
                              elevation: 3,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${showtime['theater_name']}',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _formatTime(showtime['time']),
                                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Rp $hargaStr', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 15)),
                                        SizedBox(height: 4),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            _showOrderDialog(showtime);
                                          },
                                          child: Text('Pesan Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
} 