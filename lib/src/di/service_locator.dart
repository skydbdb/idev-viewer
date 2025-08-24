import 'package:get_it/get_it.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import '../core/api/api_client.dart';
import '../core/api/api_service.dart';
import '../repo/app_streams.dart';

final sl = GetIt.instance;

void initServiceLocator() {
  sl.registerLazySingleton<HomeRepo>(() => HomeRepo());
  sl.registerLazySingleton<AppStreams>(() => AppStreams());

  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ApiService>(
      () => ApiService(apiClient: sl<ApiClient>()));
}
