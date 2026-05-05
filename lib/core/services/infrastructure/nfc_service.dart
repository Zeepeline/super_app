import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

class NfcService {
  // Cek apakah NFC tersedia di perangkat ini
  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  // Mulai memindai kartu
  void startSession({
    required Function(String uid, Map<String, dynamic> data) onDiscovered,
    required Function(String error) onError,
  }) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      onError("NFC tidak tersedia di perangkat ini.");
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          String uid = _extractUid(tag.data);
          onDiscovered(uid, tag.data);
          NfcManager.instance.stopSession();
        } catch (e) {
          onError("Gagal membaca kartu: $e");
          NfcManager.instance.stopSession(errorMessage: e.toString());
        }
      },
    );
  }

  // Berhenti memindai
  void stopSession() {
    NfcManager.instance.stopSession();
  }

  // Helper untuk mengekstrak UID dari berbagai jenis kartu
  String _extractUid(Map<String, dynamic> data) {
    // Coba ambil dari berbagai standar kartu (Mifare, IsoDep, NfcA, dll)
    final nfca = data['nfca'];
    final mfare = data['mifareultralight'];
    final ndef = data['ndef'];
    final isodep = data['isodep'];

    Uint8List? identifier;

    if (nfca != null && nfca['identifier'] != null) {
      identifier = Uint8List.fromList(List<int>.from(nfca['identifier']));
    } else if (mfare != null && mfare['identifier'] != null) {
      identifier = Uint8List.fromList(List<int>.from(mfare['identifier']));
    } else if (isodep != null && isodep['identifier'] != null) {
      identifier = Uint8List.fromList(List<int>.from(isodep['identifier']));
    }

    if (identifier != null) {
      return identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    }
    
    return "UID tidak terbaca";
  }
}
