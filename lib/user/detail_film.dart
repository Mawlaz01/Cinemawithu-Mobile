import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/url_api.dart';
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
  final String baseUrl = UrlApi.baseUrl;
  DateTime? selectedDate;

  // Custom colors and styles
  final Color primaryColor = const Color(0xFF1A237E); // Deep indigo
  final Color secondaryColor = const Color(0xFF0D47A1); // Darker blue
  final Color backgroundColor = Colors.grey[100]!; // Light grey background
  final Color surfaceColor = Colors.white; // White surface color

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
      // No need to add 7 hours since the time from API is already in WIB
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filmData!['film']['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${showtime['theater_name']} - ${_formatDate(showtime['formatted_date'])}, ${_formatTime(showtime['time'])}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Divider(height: 32, color: Colors.grey[300]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah tiket (max. 4 tiket)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Total Harga',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: primaryColor, width: 1.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.remove, color: Colors.red[400], size: 18),
                              padding: EdgeInsets.zero,
                              onPressed: ticketCount > 1
                                  ? () {
                                      setStateDialog(() {
                                        ticketCount--;
                                        totalPrice = price * ticketCount;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$ticketCount',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: primaryColor, width: 1.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: primaryColor, size: 18),
                              padding: EdgeInsets.zero,
                              onPressed: ticketCount < maxTicket
                                  ? () {
                                      setStateDialog(() {
                                        ticketCount++;
                                        totalPrice = price * ticketCount;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rp ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.15),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context);
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
                        child: Center(
                          child: Text(
                            'Pilih Bangku',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
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
      backgroundColor: backgroundColor,
      appBar: const UserAppBar(title: ''),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : filmData == null
              ? Center(
                  child: Text(
                    'Failed to load film details',
                    style: TextStyle(color: primaryColor),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Movie Poster and Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster
                            Container(
                              height: 220,
                              width: 150,
                              decoration: BoxDecoration(
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
                                child: Image.network(
                                  '$baseUrl/images/${filmData!['film']['poster']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.movie, size: 50, color: Colors.grey[400]),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            // Movie Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filmData!['film']['title'],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      filmData!['film']['genre'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        '${filmData!['film']['duration_min']} min',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        
                        // Description
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deskripsi Film',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                filmData!['film']['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        
                        // Date Selector
                        if (filmData!['film']['status'] == 'now_showing' && availableDates.isNotEmpty) ...[
                          Text(
                            'Pilih Tanggal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: availableDates.map((date) {
                                final isSelected = selectedDate?.year == date.year &&
                                                 selectedDate?.month == date.month &&
                                                 selectedDate?.day == date.day;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedDate = date;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [primaryColor, secondaryColor],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              )
                                            : null,
                                        color: isSelected ? null : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _formatDate('${date.day}/${date.month}/${date.year}'),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[800],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 32),
                        ],
                        
                        // Showtimes Section
                        if (filmData!['film']['status'] == 'now_showing' && selectedShowtimes.isNotEmpty) ...[
                          Text(
                            'Jadwal Tayang',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 16),
                          ...selectedShowtimes.map((showtime) {
                            String hargaStr = showtime['price'].toString();
                            hargaStr = hargaStr.replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.'
                            );
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${showtime['theater_name']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: primaryColor,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _formatTime(showtime['time']),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rp $hargaStr',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [primaryColor, secondaryColor],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () => _showOrderDialog(showtime),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                child: Center(
                                                  child: Text(
                                                    'Pesan Tiket',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
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