import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class HistoryDetail extends StatefulWidget {
  final String bookingId;
  const HistoryDetail({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<HistoryDetail> createState() => _HistoryDetailState();
}

class _HistoryDetailState extends State<HistoryDetail> {
  bool isLoading = true;
  Map<String, dynamic>? detail;
  String? errorMessage;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.1.21:3000';

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
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
                                          detail!['booking_status'] ?? '-',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
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
                              SelectableText(detail!['gateway_txn_id'] ?? '-', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Waktu pemesanan: ', style: TextStyle(fontSize: 15)),
                              Text(formatWaktuPemesanan(detail!['booked_at']), style: const TextStyle(fontSize: 15)),
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
                              Text(detail!['payment_method'] ?? '-', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${detail!['quantity'] ?? 0} x Tiket', style: const TextStyle(fontSize: 15)),
                              Text(formatRupiah(detail!['price_per_ticket'] ?? 0), style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(formatRupiah(detail!['total_amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}
