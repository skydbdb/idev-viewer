import 'package:get_it/get_it.dart';
import '../core/api/api_client.dart';
// import '../pms123/api/user_sync_api.dart';
// import '../pms123/api/widget_api_api.dart';
// import '../pms123/api_repo/user_sync_api_repo_impl.dart';
// import '../pms123/api_repo/widget_api_api_repo_impl.dart';
// import '../pms123/repo/user_sync_api_repo.dart';
// import '../pms123/repo/widget_api_api_repo.dart';
// import '../pms123/usecase/user_sync_uc.dart';
// import '../pms123/usecase/widget_api_uc.dart';
// import '../pms123/usecase/widget_param_uc.dart';
// import '../pms123/api_repo/widget_param_api_repo_impl.dart';
// import '../pms123/repo/widget_param_api_repo.dart';
// import '../pms123/api/api_api.dart';
// import '../pms123/api/api_param_api.dart';
// import '../pms123/api/api_role_api.dart';
// import '../pms123/api/param_api.dart';
// import '../pms123/api/widget_bas_api.dart';
// import '../pms123/api/widget_param_api.dart';
// import '../pms123/api/widget_role_api.dart';
// import '../pms123/api_repo/api_api_repo_impl.dart';
// import '../pms123/api_repo/api_param_api_repo_impl.dart';
// import '../pms123/api_repo/api_role_api_repo_impl.dart';
// import '../pms123/api_repo/param_api_repo_impl.dart';
// import '../pms123/api_repo/widget_api_repo_impl.dart';
// import '../pms123/api_repo/widget_role_api_repo_impl.dart';
// import '../pms123/repo/api_api_repo.dart';
// import '../pms123/repo/api_param_api_repo.dart';
// import '../pms123/repo/api_role_api_repo.dart';
// import '../pms123/repo/param_api_repo.dart';
// import '../pms123/repo/widget_api_repo.dart';
// import '../pms123/repo/widget_role_api_repo.dart';
// import '../pms123/usecase/api_param_uc.dart';
// import '../pms123/usecase/api_role_uc.dart';
// import '../pms123/usecase/api_uc.dart';
// import '../pms123/usecase/param_uc.dart';
// import '../pms123/usecase/widget_role_uc.dart';
// import '../pms123/usecase/widget_uc.dart';
// import '../pms123/api/group_api.dart';
// import '../pms123/api/group_role_api.dart';
// import '../pms123/api/group_user_api.dart';
// import '../pms123/api/menu_api.dart';
// import '../pms123/api/menu_role_api.dart';
// import '../pms123/api/param_role_api.dart';
// import '../pms123/api/role_api.dart';
// import '../pms123/api/user_api.dart';
// import '../pms123/api/user_role_api.dart';
// import '../pms123/api_repo/group_api_repo_impl.dart';
// import '../pms123/api_repo/group_role_api_repo_impl.dart';
// import '../pms123/api_repo/group_user_api_repo_impl.dart';
// import '../pms123/api_repo/menu_api_repo_impl.dart';
// import '../pms123/api_repo/menu_role_api_repo_impl.dart';
// import '../pms123/api_repo/param_role_api_repo_impl.dart';
// import '../pms123/api_repo/role_api_repo_impl.dart';
// import '../pms123/api_repo/user_api_repo_impl.dart';
// import '../pms123/api_repo/user_role_api_repo_impl.dart';
// import '../pms123/repo/group_api_repo.dart';
// import '../pms123/repo/group_role_api_repo.dart';
// import '../pms123/repo/group_user_api_repo.dart';
// import '../pms123/repo/menu_api_repo.dart';
// import '../pms123/repo/menu_role_api_repo.dart';
// import '../pms123/repo/param_role_api_repo.dart';
// import '../pms123/repo/role_api_repo.dart';
// import '../pms123/repo/user_api_repo.dart';
// import '../pms123/repo/user_role_api_repo.dart';
// import '../pms123/usecase/group_uc.dart';
// import '../pms123/usecase/group_role_uc.dart';
// import '../pms123/usecase/group_user_uc.dart';
// import '../pms123/usecase/menu_uc.dart';
// import '../pms123/usecase/menu_role_uc.dart';
// import '../pms123/usecase/param_role_uc.dart';
// import '../pms123/usecase/role_uc.dart';
// import '../pms123/usecase/user_uc.dart';
// import '../pms123/usecase/user_role_uc.dart';
import '../core/api/api_service.dart';
import '../repo/app_streams.dart';

final sl = GetIt.instance;

void initServiceLocator() {
  // AppStreams 등록 (LazySingleton으로 등록)
  sl.registerLazySingleton<AppStreams>(() => AppStreams());

  //ApiClient
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ApiService>(
      () => ApiService(apiClient: sl<ApiClient>()));

  // //Api
  // sl.registerLazySingleton<UserSyncApi>(() => UserSyncApi());
  // sl.registerLazySingleton<UserApi>(() => UserApi());
  // sl.registerLazySingleton<GroupApi>(() => GroupApi());
  // sl.registerLazySingleton<RoleApi>(() => RoleApi());
  // sl.registerLazySingleton<GroupUserApi>(() => GroupUserApi());
  // sl.registerLazySingleton<UserRoleApi>(() => UserRoleApi());
  // sl.registerLazySingleton<GroupRoleApi>(() => GroupRoleApi());
  // sl.registerLazySingleton<MenuApi>(() => MenuApi());
  // sl.registerLazySingleton<MenuRoleApi>(() => MenuRoleApi());
  // sl.registerLazySingleton<ApiApi>(() => ApiApi());
  // sl.registerLazySingleton<ParamApi>(() => ParamApi());
  // sl.registerLazySingleton<ApiParamApi>(() => ApiParamApi());
  // sl.registerLazySingleton<ParamRoleApi>(() => ParamRoleApi());
  // sl.registerLazySingleton<ApiRoleApi>(() => ApiRoleApi());
  // sl.registerLazySingleton<WidgetBasApi>(() => WidgetBasApi());
  // sl.registerLazySingleton<WidgetParamApi>(() => WidgetParamApi());
  // sl.registerLazySingleton<WidgetApiApi>(() => WidgetApiApi());
  // sl.registerLazySingleton<WidgetRoleApi>(() => WidgetRoleApi());

  // //Repository
  // sl.registerLazySingleton<UserSyncApiRepo>(() => UserSyncApiRepoImpl());
  // sl.registerLazySingleton<UserApiRepo>(() => UserApiRepoImpl());
  // sl.registerLazySingleton<GroupApiRepo>(() => GroupApiRepoImpl());
  // sl.registerLazySingleton<RoleApiRepo>(() => RoleApiRepoImpl());
  // sl.registerLazySingleton<GroupUserApiRepo>(() => GroupUserApiRepoImpl());
  // sl.registerLazySingleton<UserRoleApiRepo>(() => UserRoleApiRepoImpl());
  // sl.registerLazySingleton<GroupRoleApiRepo>(() => GroupRoleApiRepoImpl());
  // sl.registerLazySingleton<MenuApiRepo>(() => MenuApiRepoImpl());
  // sl.registerLazySingleton<MenuRoleApiRepo>(() => MenuRoleApiRepoImpl());
  // sl.registerLazySingleton<ApiApiRepo>(() => ApiApiRepoImpl());
  // sl.registerLazySingleton<ParamApiRepo>(() => ParamApiRepoImpl());
  // sl.registerLazySingleton<ApiParamApiRepo>(() => ApiParamApiRepoImpl());
  // sl.registerLazySingleton<ParamRoleApiRepo>(() => ParamRoleApiRepoImpl());
  // sl.registerLazySingleton<ApiRoleApiRepo>(() => ApiRoleApiRepoImpl());
  // sl.registerLazySingleton<WidgetApiRepo>(() => WidgetApiRepoImpl());
  // sl.registerLazySingleton<WidgetParamApiRepo>(() => WidgetParamApiRepoImpl());
  // sl.registerLazySingleton<WidgetApiApiRepo>(() => WidgetApiApiRepoImpl());
  // sl.registerLazySingleton<WidgetRoleApiRepo>(() => WidgetRoleApiRepoImpl());

  // //UseCase
  // sl.registerLazySingleton<UserSyncUC>(() => UserSyncUC());
  // sl.registerLazySingleton<UserUC>(() => UserUC());
  // sl.registerLazySingleton<GroupUC>(() => GroupUC());
  // sl.registerLazySingleton<RoleUC>(() => RoleUC());
  // sl.registerLazySingleton<GroupUserUC>(() => GroupUserUC());
  // sl.registerLazySingleton<UserRoleUC>(() => UserRoleUC());
  // sl.registerLazySingleton<GroupRoleUC>(() => GroupRoleUC());
  // sl.registerLazySingleton<MenuUC>(() => MenuUC());
  // sl.registerLazySingleton<MenuRoleUC>(() => MenuRoleUC());
  // sl.registerLazySingleton<ApiUC>(() => ApiUC());
  // sl.registerLazySingleton<ParamUC>(() => ParamUC());
  // sl.registerLazySingleton<ApiParamUC>(() => ApiParamUC());
  // sl.registerLazySingleton<ParamRoleUC>(() => ParamRoleUC());
  // sl.registerLazySingleton<ApiRoleUC>(() => ApiRoleUC());
  // sl.registerLazySingleton<WidgetUC>(() => WidgetUC());
  // sl.registerLazySingleton<WidgetParamUC>(() => WidgetParamUC());
  // sl.registerLazySingleton<WidgetApiUC>(() => WidgetApiUC());
  // sl.registerLazySingleton<WidgetRoleUC>(() => WidgetRoleUC());
}
