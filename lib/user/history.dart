import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../config/url_api.dart';
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
  final String baseUrl = UrlApi.baseUrl; // Ganti sesuai IP server Anda

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
    Color textColor;

    switch (status) {
      case 'paid':
        label = 'Selesai';
        color = Colors.green[700]!;
        textColor = Colors.white;
        break;
      case 'pending':
        label = 'Menunggu Pembayaran';
        color = Colors.orange[700]!;
        textColor = Colors.white;
        break;
      default:
        label = 'Gagal';
        color = Colors.red[700]!;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
        title: const Text('Riwayat Pesanan'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: const Color(0xFF1A237E),
                                          ),
                                        ),
                                      ),
                                      _buildStatusBadge(booking['payment_status']),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    booking['theater_name'],
                                    style: TextStyle(
                                      color: const Color(0xFF0D47A1),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${booking['quantity']} tiket',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(booking['total_amount'] as num),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFF1A237E),
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
