import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HistoryDetail extends StatefulWidget {
  final String bookingId;
  const HistoryDetail({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<HistoryDetail> createState() => _HistoryDetailState();
}

class _HistoryDetailState extends State<HistoryDetail> {
  bool isLoading = true;
  Map<String, dynamic>? detail;
  Map<String, dynamic>? paymentInfo;
  String? errorMessage;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.1.18:3000';
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> checkPaymentStatus() async {
    try {
      if (detail == null || detail!['gateway_txn_id'] == null) return;

      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/API/payment/status/${detail!['gateway_txn_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          paymentInfo = data;
        });
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  void startCountdown(DateTime bookedAt) {
    final batasWaktu = bookedAt.add(const Duration(minutes: 10));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = batasWaktu.difference(now);
      if (diff.isNegative) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
        });
      } else {
        setState(() {
          _remaining = diff;
        });
      }
    });
  }

  Future<void> fetchDetail() async {
    try {
      print('Fetching detail for booking ID: ${widget.bookingId}');
      if (widget.bookingId.isEmpty) {
        setState(() {
          errorMessage = 'ID booking tidak valid';
          isLoading = false;
        });
        return;
      }

      final token = await _getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan, silakan login kembali';
          isLoading = false;
        });
        return;
      }

      final url = '$baseUrl/API/dashboard/history/${widget.bookingId}';
      print('Requesting URL: $url');

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['data'] != null && data['data'].isNotEmpty) {
            setState(() {
              detail = data['data'][0];
              isLoading = false;
            });
            // Mulai countdown timer jika ada booked_at
            if (detail!['booked_at'] != null) {
              final bookedAt = DateTime.tryParse(detail!['booked_at']);
              if (bookedAt != null) {
                startCountdown(bookedAt);
              }
            }
            // Check payment status after getting detail
            checkPaymentStatus();
          } else {
            setState(() {
              errorMessage = 'Data tidak ditemukan';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'Gagal memuat detail booking (${response.statusCode})';
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching detail: $e');
        setState(() {
          errorMessage = 'Gagal memuat data: ${e.toString()}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in fetchDetail: $e');
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

  num getAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    String formatWaktuPemesanan(String? bookedAt) {
      if (bookedAt == null || bookedAt.isEmpty) return '-';
      try {
        final dt = DateTime.parse(bookedAt);
        return DateFormat('yyyy-MM-dd - HH:mm:ss').format(dt);
      } catch (e) {
        return bookedAt;
      }
    }

    Color getPaymentStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        case 'settlement':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'expire':
        case 'cancel':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    Widget buildCountdown() {
      if (_remaining == null) return SizedBox();
      if (_remaining == Duration.zero) {
        return Text('Waktu pembayaran telah habis', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
      }
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final min = twoDigits(_remaining!.inMinutes.remainder(60));
      final sec = twoDigits(_remaining!.inSeconds.remainder(60));
      return Text('Batas pembayaran: $min:$sec', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Riwayat', style: TextStyle(color: Colors.black)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              checkPaymentStatus();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : detail == null
                  ? const Center(child: Text('Tidak ada data'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // STATUS & ORDER INFO
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Status Pesanan: ', style: TextStyle(fontSize: 15)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          paymentInfo?['transaction_status']?.toUpperCase() ?? detail!['booking_status'] ?? '-',
                                          style: TextStyle(
                                            color: getPaymentStatusColor(paymentInfo?['transaction_status']),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Order ID: ', style: TextStyle(fontSize: 15)),
                              SelectableText(paymentInfo?['order_id'] ?? detail!['gateway_txn_id'] ?? '-', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Waktu pemesanan: ', style: TextStyle(fontSize: 15)),
                              Text(paymentInfo?['transaction_time'] ?? formatWaktuPemesanan(detail!['booked_at']), style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          // DETAIL TIKET
                          const SizedBox(height: 10),
                          const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (detail!['poster'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '$baseUrl/images/${detail!['poster']}',
                                    width: 70,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 70,
                                      height: 90,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.movie, size: 32, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(detail!['film_title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    Text(detail!['theater_name'] ?? '-', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                                    Text('${detail!['date'] ?? '-'} - ${detail!['time'] ?? '-'}', style: const TextStyle(fontSize: 15)),
                                    const SizedBox(height: 6),
                                    Text('Kursi: ${detail!['seat_labels'] ?? '-'}', style: const TextStyle(fontSize: 15)),
                                    Text('Jumlah Tiket: ${detail!['quantity'] ?? '-'}', style: const TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          // RINGKASAN HARGA
                          const SizedBox(height: 10),
                          const Text('Ringkasan Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Metode Pembayaran', style: TextStyle(fontSize: 15)),
                              Text(paymentInfo?['payment_type']?.toUpperCase() ?? detail!['payment_method'] ?? '-', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${detail!['quantity'] ?? 0} x Tiket', style: const TextStyle(fontSize: 15)),
                              Text(formatRupiah(getAmount(detail?['price_per_ticket'])), style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(formatRupiah(
                                paymentInfo != null && paymentInfo!['gross_amount'] != null
                                  ? getAmount(paymentInfo!['gross_amount'])
                                  : getAmount(detail?['total_amount'])
                              ), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          buildCountdown(),
                        ],
                      ),
                    ),
    );
  }
}
