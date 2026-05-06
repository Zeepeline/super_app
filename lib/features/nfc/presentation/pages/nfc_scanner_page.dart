import 'package:flutter/material.dart';
import '../../../../core/services/infrastructure/nfc_service.dart';
import 'dart:ui';

class NfcScannerPage extends StatefulWidget {
  const NfcScannerPage({super.key});

  @override
  State<NfcScannerPage> createState() => _NfcScannerPageState();
}

class _NfcScannerPageState extends State<NfcScannerPage> {
  final NfcService _nfcService = NfcService();
  bool _isScanning = false;
  String _status = "Siap memindai kartu akses Anda";
  String? _scannedUid;
  Map<String, dynamic>? _rawTagData;

  void _startScan() {
    setState(() {
      _isScanning = true;
      _status = "Tempelkan kartu ke bagian belakang HP...";
      _scannedUid = null;
    });

    _nfcService.startSession(
      onDiscovered: (uid, data) {
        setState(() {
          _isScanning = false;
          _scannedUid = uid;
          _rawTagData = data;
          _status = "Kartu Terdeteksi!";
        });
      },
      onError: (error) {
        setState(() {
          _isScanning = false;
          _status = error;
        });
      },
    );
  }

  @override
  void dispose() {
    _nfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NFC ACCESS SCANNER', 
          style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.bold)
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi / Ikon NFC
            _buildNfcIcon(),
            
            const SizedBox(height: 48),
            
            // Status Text
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _scannedUid != null ? Colors.cyanAccent : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Result Card
            if (_scannedUid != null) _buildResultCard(),
            
            const Spacer(),
            
            // Action Button
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcIcon() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isScanning
            ? Colors.cyanAccent.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: _isScanning ? Colors.cyanAccent : Colors.white24,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.nfc,
          size: 80,
          color: _isScanning ? Colors.cyanAccent : Colors.white54,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CARD UID", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                _scannedUid!,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              const Text("TECH INFO", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                "Standard: ${_rawTagData?.keys.join(', ').toUpperCase() ?? 'Unknown'}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isScanning ? null : _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          disabledBackgroundColor: Colors.white10,
        ),
        child: Text(
          _isScanning ? "SCANNING..." : "START SCANNING",
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
