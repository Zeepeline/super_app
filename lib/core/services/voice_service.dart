import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSttInitialized = false;
  bool _isTtsInitialized = false;

  bool _isIntentionalStop = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Function(String)? _currentOnResult;
  Function()? _currentOnSilence;
  bool _hasReceivedResult = false;

  Timer? _speechDebounceTimer;
  String _lastRecognizedWords = "";
  bool _isProcessingResult = false;

  // Diagnostic timer untuk cek apakah STT benar-benar jalan
  Timer? _diagnosticTimer;

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("id-ID");

      // Attempt to find a more natural voice
      final voices = await _tts.getVoices;
      if (voices != null) {
        List<Map> idVoices = [];
        for (var voice in voices) {
          if (voice["locale"] == "id-ID" || voice["locale"] == "id_ID") {
            idVoices.add(voice);
          }
        }

        if (idVoices.isNotEmpty) {
          // Prefer network or premium voices for more natural sound
          var bestVoice = idVoices.firstWhere(
            (v) =>
                v["name"].toString().toLowerCase().contains("network") ||
                v["name"].toString().toLowerCase().contains("premium"),
            orElse: () => idVoices.first,
          );
          await _tts.setVoice({
            "name": bestVoice["name"],
            "locale": bestVoice["locale"],
          });
        }
      }

      await _tts.setPitch(1.1); // Slightly higher pitch for a friendly tone
      await _tts.setSpeechRate(0.45); // Slower rate for clear Indonesian
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint("VoiceService: TTS Init failed: $e");
    }
  }

  Future<bool> initializeStt() async {
    if (_isSttInitialized) return true;

    try {
      final micStatus = await Permission.microphone.request();
      final speechStatus = await Permission.speech.request();
      debugPrint("VoiceService: Mic permission: $micStatus");
      debugPrint("VoiceService: Speech permission: $speechStatus");

      if (micStatus != PermissionStatus.granted) {
        debugPrint("VoiceService: Mic denied.");
        return false;
      }

      _isSttInitialized = await _stt.initialize(
        debugLogging: true,
        onError: (error) {
          debugPrint(
            "VoiceService: STT Error: ${error.errorMsg} (permanent: ${error.permanent})",
          );

          if (error.errorMsg == 'error_retry' && !_isIntentionalStop) {
            _retryListening();
          } else if (error.errorMsg == 'error_no_match' &&
              !_isIntentionalStop) {
            debugPrint("VoiceService: Tidak ada suara terdeteksi, retry...");
            _retryListening();
          }
        },
        onStatus: (status) {
          debugPrint("VoiceService: STT Status: $status");
          if ((status == 'notListening' || status == 'done') &&
              _isIntentionalStop) {
            _currentOnSilence?.call();
          }
        },
      );

      if (_isSttInitialized) {
        // Log semua locale yang tersedia
        var locales = await _stt.locales();
        debugPrint("VoiceService: Tersedia ${locales.length} locale:");
        for (var l in locales.take(5)) {
          debugPrint("  - ${l.localeId}: ${l.name}");
        }
        var systemLocale = await _stt.systemLocale();
        debugPrint("VoiceService: System locale: ${systemLocale?.localeId}");
      }

      debugPrint("VoiceService: STT Init: $_isSttInitialized");
      return _isSttInitialized;
    } catch (e) {
      debugPrint("VoiceService: STT Init crash: $e");
      return false;
    }
  }

  // --- TTS ---

  Future<void> speak(String text, {Function? onComplete}) async {
    if (!_isTtsInitialized) await _initTts();
    if (onComplete != null) {
      _tts.setCompletionHandler(() => onComplete());
    }
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // --- STT ---

  void _handleSttResult(SpeechRecognitionResult result) {
    if (_isProcessingResult) return;

    debugPrint(
      "VoiceService: >>> HASIL: '${result.recognizedWords}' (final: ${result.finalResult}, confidence: ${result.confidence})",
    );

    _lastRecognizedWords = result.recognizedWords;
    _speechDebounceTimer?.cancel();

    if (result.finalResult) {
      _diagnosticTimer?.cancel();
      if (_lastRecognizedWords.isNotEmpty) {
        _hasReceivedResult = true;
        _isProcessingResult = true;
        _currentOnResult?.call(_lastRecognizedWords);
        _lastRecognizedWords = "";
      }
      _stt.stop();
    } else {
      _speechDebounceTimer = Timer(const Duration(milliseconds: 2000), () {
        if (_lastRecognizedWords.isNotEmpty && !_isProcessingResult) {
          _diagnosticTimer?.cancel();
          _hasReceivedResult = true;
          _isProcessingResult = true;
          _currentOnResult?.call(_lastRecognizedWords);
          _lastRecognizedWords = "";
          _stt.stop();
        }
      });
    }
  }

  Future<void> _retryListening() async {
    if (_retryCount >= _maxRetries) {
      debugPrint("VoiceService: Max retry tercapai. Menyerah.");
      _diagnosticTimer?.cancel();
      _currentOnSilence?.call();
      return;
    }

    _retryCount++;
    debugPrint("VoiceService: Auto-retry #$_retryCount...");

    await _stt.stop();
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_isIntentionalStop) return;

    try {
      // MINIMAL config: tanpa locale, tanpa listenMode
      await _stt.listen(
        onResult: _handleSttResult,
        listenOptions: SpeechListenOptions(partialResults: true),
      );
      debugPrint(
        "VoiceService: Retry listen started OK, isListening=${_stt.isListening}",
      );
    } catch (e) {
      debugPrint("VoiceService: Retry listen gagal: $e");
      await Future.delayed(const Duration(seconds: 1));
      if (!_isIntentionalStop) _retryListening();
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onSilence,
  }) async {
    _isIntentionalStop = false;
    _retryCount = 0;
    _hasReceivedResult = false;
    _isProcessingResult = false;
    _lastRecognizedWords = "";
    _speechDebounceTimer?.cancel();
    _diagnosticTimer?.cancel();
    _currentOnResult = onResult;
    _currentOnSilence = onSilence;

    final ready = await initializeStt();
    if (!ready) return;

    // Beri jeda agar audio resource siap
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint("VoiceService: === MULAI MENDENGARKAN ===");
    debugPrint(
      "VoiceService: hasPermission=${_stt.hasPermission}, isAvailable=${_stt.isAvailable}",
    );

    try {
      // SENGAJA tanpa localeId dan tanpa listenMode
      // agar menggunakan 100% default OS
      await _stt.listen(
        onResult: _handleSttResult,
        listenOptions: SpeechListenOptions(partialResults: true),
      );

      debugPrint("VoiceService: listen() OK, isListening=${_stt.isListening}");

      // Diagnostic: cek setiap 3 detik apakah ada hasil
      _diagnosticTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        debugPrint(
          "VoiceService: [DIAG] isListening=${_stt.isListening}, lastWords='$_lastRecognizedWords', hasResult=$_hasReceivedResult",
        );
        if (!_stt.isListening && !_isIntentionalStop) {
          debugPrint(
            "VoiceService: [DIAG] STT berhenti sendiri! Coba restart...",
          );
          timer.cancel();
          _retryListening();
        }
      });
    } catch (e) {
      debugPrint("VoiceService: listen() GAGAL: $e");
      _retryListening();
    }
  }

  Future<void> stopListening() async {
    _isIntentionalStop = true;
    _retryCount = _maxRetries;
    _speechDebounceTimer?.cancel();
    _diagnosticTimer?.cancel();
    _lastRecognizedWords = "";
    await _stt.stop();
    _currentOnSilence?.call();
  }

  bool get isListening => _stt.isListening;
  bool get isAvailable => _isSttInitialized;
}
