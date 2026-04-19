import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/audio_handler.dart' as custom;

import 'core/theme/app_theme.dart';
import 'core/widgets/live_activity_island.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/home/data/models/playlist_model.dart';
import 'features/home/data/models/track_model.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/bloc/home_event.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/widgets/mini_player.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/music_player/presentation/cubit/player_cubit.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/search/presentation/pages/search_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification permission for Android 13+ to ensure Media Notification shows up
  await Permission.notification.request();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TrackModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());

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

  // Get SharedPreferences from GetIt (now guaranteed to be ready)
  final prefs = sl<SharedPreferences>();
  final showOnboarding = prefs.getBool('show_onboarding') ?? true;
  runApp(SoundWaveApp(showOnboarding: showOnboarding));
}

class SoundWaveApp extends StatelessWidget {
  final bool showOnboarding;

  const SoundWaveApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(create: (context) => sl<PlayerCubit>()),
        BlocProvider(
          create: (context) => sl<HomeBloc>()..add(LoadHomeDataEvent()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SoundWave',
        theme: AppTheme.darkTheme,
        home: AuthWrapper(showOnboarding: showOnboarding),
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
            return const MainWrapper();
          } else {
            return const MainWrapper();
          }
        },
      );
    });
  }
}

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  static final RxInt _currentIndex = 0.obs;

  static final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const LibraryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => IndexedStack(index: _currentIndex.value, children: _pages)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [const MiniPlayer(), _buildBottomNavigationBar()],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: LiveActivityIsland()),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundColor.withOpacity(0.4),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Obx(
            () => BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex.value,
              onTap: (index) => _currentIndex.value = index,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home, color: AppTheme.kPrimaryColor),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search, color: AppTheme.kPrimaryColor),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(
                    Icons.library_music,
                    color: AppTheme.kPrimaryColor,
                  ),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(
                    Icons.settings,
                    color: AppTheme.kPrimaryColor,
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
