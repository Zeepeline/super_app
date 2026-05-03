import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/rag_index_service.dart';

import 'core/network/network_info.dart';
import 'core/services/ai_tools_service.dart';
import 'core/services/audio_handler.dart' as custom_audio;
import 'core/services/download_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/lyrics_service.dart';
import 'core/services/media_import_service.dart';
import 'core/services/rag_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/youtube_download_service.dart';
import 'core/services/youtube_explode_service.dart';
import 'features/ai_assistant/presentation/cubit/ai_chat_cubit.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
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

final sl = GetIt.instance;

Future<void> init(audio_service.AudioHandler audioHandler) async {
  // 1. Cast the handler to our custom implementation to access specific methods/streams
  final customHandler = audioHandler as custom_audio.AudioHandler;

  // ===== CORE SERVICES =====
  sl.registerSingleton<audio_service.AudioHandler>(customHandler);
  sl.registerSingleton<custom_audio.AudioHandler>(customHandler);
  sl.registerSingleton<LyricsService>(LyricsService(Dio()));
  sl.registerSingleton<DownloadService>(DownloadService());
  sl.registerSingleton<MediaImportService>(MediaImportService());
  sl.registerSingleton<YoutubeDownloadService>(YoutubeDownloadService(sl()));
  sl.registerSingleton<YouTubeExplodeService>(YouTubeExplodeService());
  sl.registerSingleton<SecureStorageService>(SecureStorageService());
  sl.registerSingleton<GeminiService>(GeminiService(sl()));
  sl.registerLazySingleton<VoiceService>(() => VoiceService());
  sl.registerLazySingleton<RagIndexerService>(() => RagIndexerService());
  sl.registerLazySingleton<AiToolsService>(() => AiToolsService(sl(), sl()));
  sl.registerLazySingleton<RagService>(() => RagService(sl(), sl()));

  // ===== EXTERNAL =====
  sl.registerSingleton<Connectivity>(Connectivity());
  sl.registerSingleton<HiveInterface>(Hive);

  // SharedPreferences - initialize synchronously
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ===== DATA SOURCES =====
  sl.registerSingleton<AuthRemoteDataSource>(MockAuthRemoteDataSourceImpl());
  sl.registerSingleton<MusicLocalDataSource>(MusicLocalDataSourceImpl());
  sl.registerSingleton<HomeRemoteDataSource>(MockHomeRemoteDataSourceImpl());
  sl.registerSingleton<SearchRemoteDataSource>(
    MockSearchRemoteDataSourceImpl(),
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

  // ===== USE CASES =====
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetPopularTracks(sl()));
  sl.registerLazySingleton(() => GetFavoriteTracks(sl()));
  sl.registerLazySingleton(() => GetFeaturedPlaylists(sl()));
  sl.registerLazySingleton(() => DeleteTrackUseCase(sl()));
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

  // Music Player - register as singleton (needs repository already registered)
  sl.registerSingleton<PlayerCubit>(
    PlayerCubit(repository: sl(), lyricsService: sl()),
  );
}
