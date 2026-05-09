import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/services/ai/rag_index_service.dart';
import 'package:super_app/core/services/ai/user_memory_service.dart';
import 'package:super_app/core/services/infrastructure/secure_storage_service.dart';
import 'package:super_app/core/services/media/audio_handler.dart' as custom;
import 'package:super_app/core/services/notifications/smart_notification_service.dart';
import 'package:super_app/core/utils/hive_box_constants.dart';
import 'package:workmanager/workmanager.dart';

import 'core/services/infrastructure/python_worker_service.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_assistant/data/models/chat_message_model.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/home/data/models/playlist_model.dart';
import 'features/home/data/models/track_model.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/bloc/home_event.dart';
import 'features/home/presentation/pages/obsidian_home_page.dart';
import 'features/music_player/presentation/cubit/player_cubit.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/youtube/presentation/controllers/youtube_controller.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      // Setup minimal dependencies for AI
      final secureStorage = SecureStorageService();
      final gemini = GeminiService(secureStorage);
      final notifService = SmartNotificationService(gemini);
      await notifService.init();

      if (taskName == "smart_task_checker") {
        Hive.registerAdapter(TaskModelAdapter());
        final taskBox = await Hive.openBox<TaskModel>(
          HiveBoxConstants.tasksBox,
        );
        final now = DateTime.now();
        final upcomingTasks = taskBox.values.where((t) {
          if (t.isCompleted) return false;
          
          // Gabungkan dueDate dan time string (HH:mm)
          try {
            final timeParts = t.time.split(':');
            final actualDueDateTime = DateTime(
              t.dueDate.year,
              t.dueDate.month,
              t.dueDate.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
            
            final diff = actualDueDateTime.difference(now).inMinutes;
            return diff >= 0 && diff <= 15;
          } catch (e) {
            return false;
          }
        }).toList();

        for (final task in upcomingTasks) {
          await notifService.showSmartNotification(
            id: task.id.hashCode,
            actionType: 'task_reminder',
            itemName: task.title,
            additionalContext: "Waktunya: ${task.dueDate} jam ${task.time}.",
          );
        }
      } else if (taskName == "daily_discovery") {
        // Logika Rekomendasi Lagu/Buku Harian
        Hive.registerAdapter(TrackModelAdapter());
        final trackBox = await Hive.openBox<TrackModel>(
          HiveBoxConstants.tracksBox,
        );

        String discoveryType = 'music';
        String itemName = 'Lagu Favorit';
        String context = 'User suka dengerin musik ini.';

        if (trackBox.isNotEmpty) {
          final randomTrack = (trackBox.values.toList()..shuffle()).first;
          itemName = "${randomTrack.title} oleh ${randomTrack.artist}";
          discoveryType = 'daily_recommendation_music';
        }

        await notifService.showSmartNotification(
          id: 999,
          actionType: discoveryType,
          itemName: itemName,
          additionalContext:
              "Bikin user kangen dengerin lagu ini lagi hari ini.",
        );
      }

      return Future.value(true);
    } catch (e) {
      log("Background Task Error: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  if (Platform.isAndroid) {
    // 1. Task Pengingat Kegiatan (Setiap 15 Menit)
    await Workmanager().registerPeriodicTask(
      "smart_task_checker",
      "smart_task_checker",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // 2. Task Rekomendasi Harian (Setiap 24 Jam)
    await Workmanager().registerPeriodicTask(
      "daily_discovery",
      "daily_discovery",
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(
        minutes: 5,
      ), // Muncul 5 menit setelah install/run
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  // Request notification permission for Android 13+
  await Permission.notification.request();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TrackModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  Hive.registerAdapter(ChatMessageModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());

  // Open Boxes
  await Hive.openBox(HiveBoxConstants.booksMetadataBox);
  await Hive.openBox<TaskModel>(HiveBoxConstants.tasksBox);

  // Initialize AudioService and AudioHandler
  final audioHandler = await AudioService.init(
    builder: () => custom.AudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.soundwave.music.channel.audio',
      androidNotificationChannelName: 'SoundWave Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  await di.init(audioHandler);

  // Initialize Smart Notification Service
  await sl<SmartNotificationService>().init();

  // Initialize RAG Search Engine
  try {
    await di.sl<RagIndexerService>().initialize();
    await di.sl<UserMemoryService>().initialize();
  } catch (e) {
    log("Failed to initialize AI Services: $e");
  }

  // Initialize Python Worker early
  try {
    sl<PythonWorkerService>().initWorker();
  } catch (e) {
    log("Failed to start Python Worker: $e");
  }

  // Get SharedPreferences from GetIt
  final prefs = sl<SharedPreferences>();

  final showOnboarding = prefs.getBool('show_onboarding') ?? true;
  runApp(SoundWaveApp(showOnboarding: showOnboarding));
}

class SoundWaveApp extends StatefulWidget {
  final bool showOnboarding;

  const SoundWaveApp({super.key, required this.showOnboarding});

  @override
  State<SoundWaveApp> createState() => _SoundWaveAppState();
}

class _SoundWaveAppState extends State<SoundWaveApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    // Initialize YouTubeController for GetX
    Get.put(YouTubeController());

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(create: (context) => sl<PlayerCubit>()),
        BlocProvider(
          create: (context) => sl<HomeBloc>()..add(LoadHomeDataEvent()),
        ),
        BlocProvider(create: (context) => sl<DashboardBloc>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SoundWave',
        theme: AppTheme.darkTheme,
        home: _showSplash
            ? SplashPage(
                onFinish: () {
                  setState(() {
                    _showSplash = false;
                  });
                },
              )
            : AuthWrapper(showOnboarding: widget.showOnboarding),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final bool showOnboarding;
  final RxBool _showOnboardingObs;

  AuthWrapper({super.key, required this.showOnboarding})
    : _showOnboardingObs = showOnboarding.obs;

  void _finishOnboarding() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('show_onboarding', false);
    _showOnboardingObs.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_showOnboardingObs.value) {
        return OnboardingPage(onFinish: _finishOnboarding);
      }

      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return const ObsidianHomePage();
          } else {
            return const ObsidianHomePage();
          }
        },
      );
    });
  }
}

// MainWrapper moved to lib/features/main_wrapper.dart
