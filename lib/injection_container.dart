import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/services/ai/rag_index_service.dart';
import 'package:super_app/core/services/ai/rag_service.dart';
import 'package:super_app/core/services/ai/user_memory_service.dart';
import 'package:super_app/core/services/ai/voice_service.dart';
import 'package:super_app/core/services/books/book_store_service.dart';
import 'package:super_app/core/services/download/download_service.dart';
import 'package:super_app/core/services/download/youtube_explode_service.dart';
import 'package:super_app/core/services/infrastructure/secure_storage_service.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';
import 'package:super_app/core/services/media/media_import_service.dart';

import 'core/network/network_info.dart';
import 'core/services/ai/ai_tools_service.dart';
import 'core/services/books/book_cover_service.dart';
import 'core/services/books/book_library_service.dart';
import 'core/services/download/youtube_download_service.dart';
import 'core/services/infrastructure/native_device_service.dart';
import 'core/services/infrastructure/python_worker_service.dart';
import 'core/services/media/audio_handler.dart' as custom_audio;
import 'features/ai_assistant/presentation/cubit/ai_chat_cubit.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/book_search/data/datasources/book_remote_datasource.dart';
import 'features/book_search/data/repositories/book_search_repository_impl.dart';
import 'features/book_search/domain/repositories/book_search_repository.dart';
import 'features/book_search/presentation/bloc/book_search_bloc.dart';
import 'features/home/data/datasources/home_local_data_source.dart';
import 'features/home/data/datasources/home_remote_datasource.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/domain/usecases/delete_track.dart';
import 'features/home/domain/usecases/get_favorite_tracks.dart';
import 'features/home/domain/usecases/get_featured_playlists.dart';
import 'features/home/domain/usecases/get_popular_tracks.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/library/presentation/bloc/library_bloc.dart';
import 'features/music_player/data/datasources/music_local_datasource.dart';
import 'features/music_player/data/repositories/music_repository_impl.dart';
import 'features/music_player/domain/repositories/music_repository.dart';
import 'features/music_player/domain/usecases/get_current_track.dart';
import 'features/music_player/domain/usecases/player_usecases.dart';
import 'features/music_player/presentation/cubit/player_cubit.dart';
import 'features/search/data/datasources/search_remote_datasource.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/domain/usecases/get_categories.dart';
import 'features/search/presentation/bloc/search_bloc.dart';
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/datasources/settings_local_datasource_impl.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_current_user.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/logout.dart';
import 'features/settings/domain/usecases/update_audio_quality.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/schedule/domain/repositories/schedule_repository.dart';
import 'features/schedule/domain/usecases/get_sessions.dart';
import 'features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'features/schedule/data/repositories/schedule_repository_impl.dart';
import 'features/schedule/presentation/bloc/schedule_bloc.dart';
import 'features/holidays/domain/repositories/holiday_repository.dart';
import 'features/holidays/domain/usecases/get_holidays.dart';
import 'features/holidays/data/datasources/holiday_remote_datasource.dart';
import 'features/holidays/data/datasources/holiday_local_datasource.dart';
import 'features/holidays/data/repositories/holiday_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/tasks/data/datasources/task_local_datasource.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/add_task.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'core/utils/hive_box_constants.dart';

final sl = GetIt.instance;

Future<void> init(audio_service.AudioHandler audioHandler) async {
  // 1. Cast the handler to our custom implementation to access specific methods/streams
  final customHandler = audioHandler as custom_audio.AudioHandler;

  // ===== EXTERNAL =====
  // SharedPreferences - initialize synchronously first because other services depend on it
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerSingleton<Connectivity>(Connectivity());
  sl.registerSingleton<HiveInterface>(Hive);
  sl.registerSingleton<Dio>(Dio());

  // ===== CORE SERVICES =====
  sl.registerSingleton<audio_service.AudioHandler>(customHandler);
  sl.registerSingleton<custom_audio.AudioHandler>(customHandler);
  sl.registerSingleton<LyricsService>(LyricsService(sl()));
  sl.registerSingleton<PythonWorkerService>(PythonWorkerService(sl()));
  sl.registerSingleton<BookCoverService>(BookCoverService());
  sl.registerSingleton<BookLibraryService>(BookLibraryService(sl()));
  sl.registerSingleton<DownloadService>(DownloadService());
  sl.registerSingleton<MediaImportService>(MediaImportService());
  sl.registerSingleton<YoutubeDownloadService>(
    YoutubeDownloadService(sl(), sl()),
  );
  sl.registerSingleton<YouTubeExplodeService>(YouTubeExplodeService());
  sl.registerSingleton<SecureStorageService>(SecureStorageService());
  sl.registerSingleton<GeminiService>(GeminiService(sl()));
  sl.registerLazySingleton<VoiceService>(() => VoiceService());
  sl.registerLazySingleton<UserMemoryService>(() => UserMemoryService());
  sl.registerLazySingleton<NativeDeviceService>(() => NativeDeviceService());
  sl.registerLazySingleton<RagIndexerService>(() => RagIndexerService());
  sl.registerLazySingleton<AiToolsService>(
    () => AiToolsService(sl(), sl(), sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<RagService>(() => RagService(sl(), sl()));

  // Register Book Search before BookStoreService
  sl.registerSingleton<BookSearchRepository>(
    BookSearchRepositoryImpl(BookRemoteDataSourceImpl(sl())),
  );
  sl.registerSingleton<BookStoreService>(BookStoreService(sl(), sl(), sl()));

  // ===== EXTERNAL =====
  // sl.registerSingleton<Connectivity>(Connectivity()); (moved up)
  // sl.registerSingleton<HiveInterface>(Hive); (moved up)

  // SharedPreferences - initialize synchronously (moved up)

  // ===== DATA SOURCES =====
  sl.registerSingleton<AuthRemoteDataSource>(MockAuthRemoteDataSourceImpl());
  sl.registerSingleton<MusicLocalDataSource>(MusicLocalDataSourceImpl());
  sl.registerSingleton<HomeRemoteDataSource>(MockHomeRemoteDataSourceImpl());
  sl.registerSingleton<SearchRemoteDataSource>(
    MockSearchRemoteDataSourceImpl(),
  );
  sl.registerSingleton<DashboardRemoteDataSource>(
    DashboardRemoteDataSourceImpl(),
  );
  sl.registerSingleton<ScheduleRemoteDataSource>(
    ScheduleRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<HolidayRemoteDataSource>(
    () => HolidayRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<HolidayLocalDataSource>(
    () => HolidayLocalDataSourceImpl(hive: sl()),
  );
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(
      taskBox: Hive.box<TaskModel>(HiveBoxConstants.tasksBox),
    ),
  );

  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl<Connectivity>()));

  // Settings and Home data sources need external deps
  sl.registerSingleton<SettingsLocalDataSource>(
    SettingsLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );
  sl.registerSingleton<HomeLocalDataSource>(
    HomeLocalDataSourceImpl(hive: sl<HiveInterface>()),
  );

  // ===== REPOSITORIES =====
  sl.registerSingleton<MusicRepository>(
    MusicRepositoryImpl(
      localDataSource: sl<MusicLocalDataSource>(),
      homeLocalDataSource: sl<HomeLocalDataSource>(),
      audioHandler: customHandler,
      youtubeDownloadService: sl<YoutubeDownloadService>(),
    ),
  );
  sl.registerSingleton<HomeRepository>(
    HomeRepositoryImpl(
      remoteDataSource: sl<HomeRemoteDataSource>(),
      localDataSource: sl<HomeLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(localDataSource: sl<SettingsLocalDataSource>()),
  );
  sl.registerSingleton<SearchRepository>(
    SearchRepositoryImpl(remoteDataSource: sl<SearchRemoteDataSource>()),
  );
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );
  sl.registerSingleton<DashboardRepository>(
    DashboardRepositoryImpl(remoteDataSource: sl<DashboardRemoteDataSource>()),
  );
  sl.registerSingleton<ScheduleRepository>(
    ScheduleRepositoryImpl(remoteDataSource: sl<ScheduleRemoteDataSource>()),
  );
  sl.registerLazySingleton<HolidayRepository>(
    () => HolidayRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(localDataSource: sl()),
  );

  // ===== USE CASES =====
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetPopularTracks(sl()));
  sl.registerLazySingleton(() => GetFavoriteTracks(sl()));
  sl.registerLazySingleton(() => GetFeaturedPlaylists(sl()));
  sl.registerLazySingleton(() => DeleteTrackUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardData(sl()));
  sl.registerLazySingleton(() => GetSessions(sl()));
  sl.registerLazySingleton(() => GetHolidays(sl()));
  sl.registerLazySingleton(() => AddTask(sl()));
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateAudioQuality(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentTrack(sl()));
  sl.registerLazySingleton(() => PlayTrack(sl()));
  sl.registerLazySingleton(() => PauseTrack(sl()));
  sl.registerLazySingleton(() => SeekTo(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));
  sl.registerLazySingleton(() => SkipToNext(sl()));
  sl.registerLazySingleton(() => SkipToPrevious(sl()));
  sl.registerLazySingleton(() => ToggleShuffle(sl()));
  sl.registerLazySingleton(() => ToggleRepeat(sl()));

  // ===== BLOCS / CUBITS =====
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));
  sl.registerFactory(() => SearchBloc(getCategories: sl()));
  sl.registerFactory(
    () => LibraryBloc(getFavoriteTracks: sl(), repository: sl()),
  );
  sl.registerFactory(
    () => HomeBloc(
      getPopularTracks: sl(),
      getFeaturedPlaylists: sl(),
      mediaImportService: sl(),
      localDataSource: sl(),
      deleteTrackUseCase: sl(),
      ragIndexerService: sl(),
      bookLibraryService: sl(),
    ),
  );
  sl.registerFactory(
    () => SettingsBloc(
      getSettings: sl(),
      getCurrentUser: sl(),
      updateAudioQuality: sl(),
      logout: sl(),
      importService: sl(),
      homeLocalDataSource: sl(),
      youtubeDownloadService: sl(),
      secureStorageService: sl(),
    ),
  );
  sl.registerFactory(() => AiChatCubit(sl(), sl()));
  sl.registerFactory(() => BookSearchBloc(sl()));
  sl.registerFactory(() => DashboardBloc(getDashboardData: sl()));
  sl.registerFactory(() => ScheduleBloc(getSessions: sl(), getHolidays: sl()));
  sl.registerFactory(() => TaskBloc(addTask: sl()));

  // Music Player - register as singleton (needs repository already registered)
  sl.registerSingleton<PlayerCubit>(
    PlayerCubit(repository: sl(), lyricsService: sl()),
  );
}
