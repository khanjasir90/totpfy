import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../core/storage/storage_service.dart';

/*
otpauth://totp/GitHub:khanjasir90?secret=JV3XEATNO2YSIIVN&issuer=GitHub
*/

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.storageService});

  final StorageService storageService;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool hasReadQrCode = false;

  void _updateHasReadQrCode() {
    setState(() {
      hasReadQrCode = true;
    });
  }

  /// Extracts username from otpauth URI using regex
  String extractUsername(String otpauthUri) {
    // Pattern to match username after totp/ and before ?
    final regex = RegExp(r'otpauth://totp/[^:]+:([^?]+)');
    final match = regex.firstMatch(otpauthUri);
    return match?.group(1) ?? '';
  }
  
  void _onQRViewCreated(QRViewController controller) {

    void navigateToDashboard() {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }

    controller.scannedDataStream.listen((scannedData) {
      if(scannedData.code != null && !hasReadQrCode) {
        final uri = Uri.parse(scannedData.code!);
        final secretKey = uri.queryParameters['secret'] ?? '';
        final issuer = uri.queryParameters['issuer'] ?? '';
        final username = extractUsername(scannedData.code!);
        
        widget.storageService.saveSecretKey(secretKey: '$secretKey:$username', issuer: issuer);
        navigateToDashboard();
        _updateHasReadQrCode();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }
}