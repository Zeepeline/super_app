import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../ai/gemini_service.dart';

class SmartNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GeminiService _geminiService;

  SmartNotificationService(this._geminiService);

  Future<void> init() async {
    tz.initializeTimeZones();
    debugPrint("SmartNotificationService: Initializing...");

    // 1. Request permission explicitly for Android & iOS
    try {
      if (Platform.isAndroid) {
        final bool? granted = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        debugPrint(
          "SmartNotificationService: Android permission granted: $granted",
        );
      } else if (Platform.isIOS) {
        // Menggunakan IOSFlutterLocalNotificationsPlugin sebagai fallback jika Darwin tidak dikenali
        // atau gunakan dynamic untuk memanggil method requestPermissions secara fleksibel
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosPlugin != null) {
          final bool? granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint(
            "SmartNotificationService: iOS permission granted: $granted",
          );
        }
      }
    } catch (e) {
      debugPrint("SmartNotificationService: Permission request error: $e");
    }

    // 2. Setup Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // 3. Initialize
    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint(
            "SmartNotificationService: Notification clicked: ${details.payload}",
          );
        },
      );

      // 4. Create Notification Channel for Android
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'smart_notif_channel',
              'Smart Notifications',
              description: 'Notifikasi cerdas dari asisten AI',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );

      debugPrint("SmartNotificationService: Initialization complete.");
    } catch (e) {
      debugPrint("SmartNotificationService: Initialization failed: $e");
    }
  }

  /// Menampilkan notifikasi cerdas berbasis AI
  Future<void> showSmartNotification({
    required int id,
    required String actionType, // misal: 'download_complete', 'task_reminder'
    required String itemName, // misal: judul buku, nama task
    String? additionalContext,
  }) async {
    // 1. Generate cerdas via Gemini
    final prompt =
        """
      You are a smart, friendly, and motivating personal assistant. 
      Generate a very short push notification (max 12 words) for the user.
      Event: $actionType
      Target Item: $itemName
      Context: ${additionalContext ?? 'No extra context'}
      
      Requirements:
      - Use Indonesian language.
      - Be creative and personal.
      - Don't just say "Task is due", make it sound like a companion.
      - Return ONLY the generated text.
    """;

    debugPrint(
      "SmartNotificationService: Generating notification for $actionType - $itemName",
    );

    String smartTitle = "Super App Insight";
    String smartBody = "Ada pengingat baru: $itemName";

    try {
      // 1. Generate cerdas via Gemini dengan timeout 5 detik
      final aiResponse = await _geminiService
          .getChatResponse(prompt)
          .timeout(const Duration(seconds: 5), onTimeout: () => "");

      if (aiResponse.isNotEmpty) {
        smartBody = aiResponse.trim();
        final words = smartBody.split(' ');
        if (words.length > 2) {
          smartTitle = "${words[0]} ${words[1]}...";
        }
      }
    } catch (e) {
      debugPrint("SmartNotificationService AI Error: $e");
    }

    try {
      // 2. Tampilkan notifikasi
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'smart_notif_channel',
            'Smart Notifications',
            channelDescription: 'Notifikasi cerdas dari asisten AI',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            showWhen: true,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      debugPrint("SmartNotificationService: Showing notification id: $id");
      await _notificationsPlugin.show(
        id,
        smartTitle,
        smartBody,
        platformDetails,
      );
      debugPrint(
        "SmartNotificationService: Notification displayed successfully",
      );
    } catch (e) {
      debugPrint("SmartNotificationService Show Error: $e");
    }
  }

  /// Menjadwalkan notifikasi untuk masa depan (misal untuk Task)
  Future<void> scheduleSmartNotification({
    required int id,
    required String itemName,
    required DateTime scheduledTime,
    String? additionalContext,
  }) async {
    // Catatan: Karena kita ingin teksnya "cerdas" SAAT muncul,
    // idealnya ini dipicu oleh WorkManager sesaat sebelum waktu kejadian.
    // Tapi untuk cara simpel, kita bisa simpan jadwalnya di sistem lokal OS.

    await _notificationsPlugin.zonedSchedule(
      id,
      "Pengingat Kegiatan",
      "Waktunya untuk $itemName!",
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminder_channel',
          'Task Reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
