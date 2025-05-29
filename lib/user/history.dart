import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'history_detail.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  bool isLoading = true;
  List<dynamic>? bookingHistory;
  String? errorMessage;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.1.18:3000'; // Ganti sesuai IP server Anda

  @override
  void initState() {
    super.initState();
    fetchBookingHistory();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchBookingHistory() async {
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan, silakan login kembali';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/API/dashboard/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('History Response Status: ${response.statusCode}');
      print('History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded History Data: ${data['data']}');
        setState(() {
          bookingHistory = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat riwayat booking';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in fetchBookingHistory: $e');
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  String formatRupiah(num amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp. ${formatter.format(amount)}';
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;
    Color textColor = Colors.white;

    switch (status) {
      case 'paid':
        label = 'Selesai';
        color = Colors.green;
        break;
      case 'pending':
        label = 'Menunggu Pembayaran';
        color = Colors.orange;
        textColor = Colors.black87;
        break;
      default:
        label = 'Gagal';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan', style: TextStyle(color: Colors.black)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo_cinema.png',
              height: 32,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : bookingHistory == null || bookingHistory!.isEmpty
                  ? const Center(child: Text('Tidak ada riwayat booking'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookingHistory!.length,
                      itemBuilder: (context, index) {
                        final booking = bookingHistory![index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            print('Booking data: $booking');
                            final bookingId = booking['booking_id']?.toString();
                            print('Booking ID for navigation: $bookingId');
                            
                            if (bookingId != null && bookingId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HistoryDetail(
                                    bookingId: bookingId,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Data booking tidak ditemukan'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0.5,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          booking['film_title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      _buildStatusBadge(booking['payment_status']),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    booking['theater_name'],
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${booking['quantity']} tiket',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(booking['total_amount'] as num),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
