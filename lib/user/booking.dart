import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'detail_booking.dart';

class BookingPage extends StatefulWidget {
  final String filmId;
  final String showtimeId;
  final int maxSeat;

  const BookingPage({
    Key? key,
    required this.filmId,
    required this.showtimeId,
    this.maxSeat = 4,
  }) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool isLoading = true;
  Map<String, dynamic>? bookingData;
  List<Map<String, dynamic>> selectedSeats = [];
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    fetchBookingData();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchBookingData() async {
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get seat data
      final seatResponse = await http.get(
        Uri.parse('$baseUrl/API/dashboard/detailfilm/${widget.filmId}/${widget.showtimeId}/seat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (seatResponse.statusCode == 200) {
        final seatData = json.decode(seatResponse.body);
        setState(() {
          bookingData = seatData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load seat data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void toggleSeatSelection(Map<String, dynamic> seat) {
    setState(() {
      if (seat['is_available']) {
        if (selectedSeats.any((s) => s['seat_id'] == seat['seat_id'])) {
          selectedSeats.removeWhere((s) => s['seat_id'] == seat['seat_id']);
        } else {
          if (selectedSeats.length >= widget.maxSeat) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Maksimal ${widget.maxSeat} kursi dapat dipilih.')),
            );
            return;
          }
          selectedSeats.add(seat);
        }
      }
    });
  }

  Future<void> _submitBooking() async {
    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan, silakan login kembali')),
        );
        return;
      }

      // Prepare booking data
      final bookingData = {
        'seat_ids': selectedSeats.map((seat) => seat['seat_id']).toList(),
        'quantity': selectedSeats.length,
      };

      // Make booking request
      final bookingResponse = await http.post(
        Uri.parse('$baseUrl/API/booking/${widget.showtimeId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bookingData),
      );

      if (bookingResponse.statusCode == 201) {
        final bookingResult = json.decode(bookingResponse.body);
        final bookingId = bookingResult['data']['booking_id'];

        // Create booking history
        final historyData = {
          'booking_id': bookingId,
        };

        final historyResponse = await http.post(
          Uri.parse('$baseUrl/API/booking/history/${widget.showtimeId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(historyData),
        );

        if (historyResponse.statusCode == 201) {
          // Call payment endpoint
          final paymentResponse = await http.post(
            Uri.parse('$baseUrl/API/payment/${widget.filmId}/${widget.showtimeId}/$bookingId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (paymentResponse.statusCode == 200) {
            final paymentResult = json.decode(paymentResponse.body);
            final paymentToken = paymentResult['token'];
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking berhasil dibuat & payment token didapatkan')),
            );
            // Lanjut ke halaman detail booking
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailBooking(
                    filmId: widget.filmId,
                    showtimeId: widget.showtimeId,
                    bookingId: bookingId.toString(),
                    paymentToken: paymentToken,
                  ),
                ),
              );
            }
          } else {
            throw Exception('Gagal mendapatkan token pembayaran');
          }
        } else {
          throw Exception('Failed to create booking history');
        }
      } else {
        final errorData = json.decode(bookingResponse.body);
        throw Exception(errorData['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (bookingData == null) {
      return const Scaffold(
        body: Center(
          child: Text('No data available'),
        ),
      );
    }

    // Group seats by row (first letter of seat_label) dan filter duplikat
    Map<String, List<Map<String, dynamic>>> seatsByRow = {};
    Set<String> seenSeatLabels = {};
    for (var seat in bookingData!['seats']) {
      String row = seat['seat_label'][0];
      String seatLabel = seat['seat_label'];
      if (!seenSeatLabels.contains(seatLabel)) {
        if (!seatsByRow.containsKey(row)) {
          seatsByRow[row] = [];
        }
        seatsByRow[row]!.add(seat);
        seenSeatLabels.add(seatLabel);
      }
    }

    // Sort rows alphabetically
    var sortedRows = seatsByRow.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Bangku'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Header Detail Film
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                bookingData!['film_poster'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '$baseUrl/images/${bookingData!['film_poster']}',
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.movie, size: 32, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.movie, size: 32, color: Colors.grey),
                    ),
                const SizedBox(width: 12),
                // Info Film
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingData!['film_title'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            bookingData!['showtime']['date'] ?? '-',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            bookingData!['showtime']['time'] ?? '-',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            bookingData!['showtime']['theater_name'] ?? '-',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event_seat, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Pilih ${widget.maxSeat} bangku',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Keterangan layar (persegi panjang lebar)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Center(
              child: Container(
                width: 350,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'LAYAR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ),
          // Grid Kursi (Column of Row)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 50, left: 8, right: 8, bottom: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var row in sortedRows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var seat in (seatsByRow[row]!..sort((a, b) {
                              int numA = int.parse(a['seat_label'].substring(1));
                              int numB = int.parse(b['seat_label'].substring(1));
                              return numA.compareTo(numB);
                            })))
                              Builder(
                                builder: (context) {
                                  bool isSelected = selectedSeats.any((s) => s['seat_id'] == seat['seat_id']);
                                  bool isAvailable = seat['is_available'] == true;
                                  Color color;
                                  if (!isAvailable) {
                                    color = Colors.red;
                                  } else if (isSelected) {
                                    color = Colors.green;
                                  } else {
                                    color = Colors.blue;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => toggleSeatSelection(seat),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            seat['seat_label'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Legend/tombol lanjut di bawah grid
          if (selectedSeats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _seatLegendBox(Colors.blue, 'Tersedia'),
                  const SizedBox(width: 12),
                  _seatLegendBox(Colors.green, 'Terpilih'),
                  const SizedBox(width: 12),
                  _seatLegendBox(Colors.red, 'Terisi'),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bangku terpilih', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    selectedSeats.map((s) => s['seat_label']).join(", "),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submitBooking,
                      child: const Text('Lanjut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _seatLegendBox(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
