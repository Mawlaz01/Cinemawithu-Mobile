import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:url_launcher/url_launcher.dart';
import 'film_showing.dart';
import 'dart:io' as io;

class PaymentsPage extends StatefulWidget {
  final String paymentUrl;
  const PaymentsPage({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  // For Android/iOS
  late final WebViewController _controller;
  // For Windows
  final webviewController = WebviewController();
  bool isWebviewWindowsInitialized = false;

  bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  bool get isIOS => !kIsWeb && io.Platform.isIOS;
  bool get isWindows => !kIsWeb && io.Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (isAndroid || isIOS) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (url.contains('status_code=200') || url.contains('transaction_status=settlement')) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => FilmShowingPage()),
                  (route) => false,
                );
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.paymentUrl));
    } else if (isWindows) {
      webviewController.initialize().then((_) {
        webviewController.loadUrl(widget.paymentUrl);
        setState(() {
          isWebviewWindowsInitialized = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(widget.paymentUrl))) {
                await launchUrl(Uri.parse(widget.paymentUrl), mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak bisa membuka link pembayaran')),
                );
              }
            },
            child: const Text('Buka Pembayaran di Tab Baru'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: isAndroid || isIOS
          ? WebViewWidget(controller: _controller)
          : isWindows
              ? isWebviewWindowsInitialized
                  ? Webview(webviewController)
                  : const Center(child: CircularProgressIndicator())
              : const Center(child: Text('WebView tidak didukung di platform ini')),
    );
  }
}
