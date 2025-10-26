import 'package:get_it/get_it.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_service.dart';
import '../../repo/app_streams.dart';
import '../../repo/home_repo.dart';

final sl = GetIt.instance;

void initServiceLocator() {
  // AppStreams 등록 (LazySingleton으로 등록)
  sl.registerLazySingleton<AppStreams>(() => AppStreams());

  //ApiClient
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ApiService>(
      () => ApiService(apiClient: sl<ApiClient>()));
}

void initViewerServiceLocator() {
  // 뷰어 모드에서는 AppStreams 등록하지 않음
  // 최소한의 API 서비스만 등록

  //ApiClient
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ApiService>(
      () => ApiService(apiClient: sl<ApiClient>()));
  
  // 뷰어 모드에서 HomeRepo는 LazySingleton으로 등록 (단일 인스턴스)
  sl.registerLazySingleton<HomeRepo>(() => HomeRepo());
}
