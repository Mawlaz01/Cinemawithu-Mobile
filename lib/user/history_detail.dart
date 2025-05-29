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
  final Color primaryColor = const Color(0xFF1A237E);
  final Color secondaryColor = const Color(0xFF0D47A1);
  final Color backgroundColor = Colors.grey[100]!;
  final Color surfaceColor = Colors.white;

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
        // Adjusting for GMT+7 if needed, assuming server time is GMT+0
        final dtWIB = dt.add(Duration(hours: 7));
        return DateFormat('yyyy-MM-dd - HH:mm:ss').format(dtWIB);
      } catch (e) {
        return bookedAt;
      }
    }

    Color getPaymentStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        case 'settlement':
          return Colors.green[700]!;
        case 'pending':
          return Colors.orange[700]!;
        case 'expire':
        case 'cancel':
          return Colors.red[700]!;
        default:
          return Colors.grey[700]!;
      }
    }

    Widget buildStatusBadge(String? status) {
      String label = '-';
      Color color = Colors.grey;
      // Jika waktu pembayaran habis, status otomatis expire
      String? effectiveStatus = status;
      if (_remaining == Duration.zero) {
        effectiveStatus = 'expire';
      }
      if (effectiveStatus != null) {
        switch (effectiveStatus.toLowerCase()) {
          case 'pending':
            label = 'Menunggu Pembayaran';
            color = Colors.amber[700]!;
            break;
          case 'settlement':
            label = 'Berhasil';
            color = Colors.green[700]!;
            break;
          case 'expire':
          case 'cancel':
            label = 'Gagal/Expired';
            color = Colors.red[700]!;
            break;
          default:
            label = effectiveStatus;
            color = Colors.grey;
        }
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    Widget buildCountdown() {
      if (_remaining == null) return SizedBox();
      if (_remaining == Duration.zero) {
        return Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[700]!,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Waktu pembayaran telah habis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final min = twoDigits(_remaining!.inMinutes.remainder(60));
      final sec = twoDigits(_remaining!.inSeconds.remainder(60));
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Batas Waktu Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('$min:$sec', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : detail == null
                  ? const Center(child: Text('Tidak ada data'))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: surfaceColor,
                              child: Padding(
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
                                            Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text('Status Pesanan: ', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                                buildStatusBadge(paymentInfo?['transaction_status'] ?? detail!['booking_status']),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text('Order ID: ', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                        SelectableText(paymentInfo?['order_id'] ?? detail!['gateway_txn_id'] ?? '-', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text('Waktu pemesanan: ', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                        Text(paymentInfo?['transaction_time'] ?? formatWaktuPemesanan(detail!['booked_at']), style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                      ],
                                    ),
                                    buildCountdown(),
                                    const SizedBox(height: 18),
                                    const Divider(),
                                    // DETAIL TIKET
                                    const SizedBox(height: 10),
                                    Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
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
                                                child: Icon(Icons.movie, size: 32, color: Colors.grey[600]),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(detail!['film_title'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: primaryColor)),
                                              Text(detail!['theater_name'] ?? '-', style: TextStyle(fontSize: 15, color: secondaryColor)),
                                              Text('${detail!['date'] ?? '-'} - ${detail!['time'] ?? '-'}', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                              const SizedBox(height: 6),
                                              Text('Kursi: ${detail!['seat_labels'] ?? '-'}', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                              Text('Jumlah Tiket: ${detail!['quantity'] ?? '-'}', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    const Divider(),
                                    // RINGKASAN HARGA
                                    const SizedBox(height: 10),
                                    Text('Ringkasan Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Metode Pembayaran', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                        Text(paymentInfo?['payment_type']?.toUpperCase() ?? detail!['payment_method'] ?? '-', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${detail!['quantity'] ?? 0} x Tiket', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                        Text(formatRupiah(getAmount(detail?['price_per_ticket'])), style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                        Text(formatRupiah(
                                          paymentInfo != null && paymentInfo!['gross_amount'] != null
                                            ? getAmount(paymentInfo!['gross_amount'])
                                            : getAmount(detail?['total_amount'])
                                        ), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Tombol Lanjutkan Pembayaran
                        if (((paymentInfo?['transaction_status'] ?? detail!['booking_status'])?.toLowerCase() == 'pending') && _remaining != Duration.zero)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: surfaceColor,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                // TODO: Implementasi aksi lanjutkan pembayaran
                              },
                              child: const Text('Lanjutkan Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
