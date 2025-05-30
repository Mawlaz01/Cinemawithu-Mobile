import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../config/url_api.dart';
import 'payments.dart';

class DetailBooking extends StatefulWidget {
  final String filmId;
  final String showtimeId;
  final String bookingId;
  final String paymentToken;

  const DetailBooking({
    Key? key,
    required this.filmId,
    required this.showtimeId,
    required this.bookingId,
    required this.paymentToken,
  }) : super(key: key);

  @override
  State<DetailBooking> createState() => _DetailBookingState();
}

class _DetailBookingState extends State<DetailBooking> {
  bool isLoading = true;
  Map<String, dynamic>? bookingData;
  String? errorMessage;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = UrlApi.baseUrl;

  // Timer
  Duration _duration = const Duration(minutes: 10);
  Timer? _timer;
  bool isExpired = false;

  final Color primaryColor = const Color(0xFF1A237E);
  final Color secondaryColor = const Color(0xFF0D47A1);
  final Color backgroundColor = Colors.grey[100]!;
  final Color surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    fetchBookingDetails();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds > 0) {
        setState(() {
          _duration = _duration - const Duration(seconds: 1);
        });
      } else {
        setState(() {
          isExpired = true;
        });
        timer.cancel();
      }
    });
  }

  String get timerText {
    if (isExpired) return '00:00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> fetchBookingDetails() async {
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
        Uri.parse('$baseUrl/API/booking/${widget.filmId}/${widget.showtimeId}/${widget.bookingId}/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          bookingData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat detail booking';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: const [SizedBox(width: 8)],
          ),
        ),
      ),
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: TextStyle(color: primaryColor)))
              : bookingData == null
                  ? const Center(child: Text('Tidak ada data booking'))
                  : Column(
                      children: [
                        // Timer Bar
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Segera bayar dalam',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    timerText,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text('Detail tiket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                  const SizedBox(height: 8),
                                  Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 1.5,
                                    color: surfaceColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              '$baseUrl/images/${bookingData!['film']['poster']}',
                                              width: 60,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 60,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.movie, size: 32, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bookingData!['film']['title'],
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                                                ),
                                                Text(
                                                  bookingData!['showtime']['theater'],
                                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${bookingData!['showtime']['date']} - ${bookingData!['showtime']['time']}',
                                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Card: Pilihan Kursi (sekarang juga menampilkan harga per tiket di kanan)
                                  Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 1.5,
                                    color: surfaceColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.event_seat, color: Colors.grey, size: 22),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('Pilihan Kursi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                    Text('Harga per tiket: Rp ${((bookingData!['booking']['total_amount'] / bookingData!['booking']['quantity']) as num).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  bookingData!['booking']['seats'].join(", "),
                                                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Ringkasan Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                  const SizedBox(height: 8),
                                  Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 1.5,
                                    color: surfaceColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${bookingData!['booking']['quantity']} x Tiket', style: TextStyle(color: primaryColor)),
                                              Text('Rp ${(bookingData!['booking']['total_amount'] as num).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', style: TextStyle(color: primaryColor)),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Total yang harus dibayar', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Rp ${(bookingData!['booking']['total_amount'] as num).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                                            ],
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
                        // Button at the bottom
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  final paymentUrl = 'https://app.sandbox.midtrans.com/snap/v4/redirection/${widget.paymentToken}';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentsPage(paymentUrl: paymentUrl),
                                    ),
                                  );
                                },
                                child: const Text('Pilih Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
