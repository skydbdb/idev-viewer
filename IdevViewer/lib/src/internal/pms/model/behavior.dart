import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:idev_viewer/src/internal/core/api/api_service.dart';
import 'package:idev_viewer/src/internal/pms/model/search_response.dart';
import 'package:idev_viewer/src/internal/pms/model/api_response.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
part 'behavior.freezed.dart';
part 'behavior.g.dart';

enum Type {
  @JsonKey(name: 'self')
  self,
  @JsonValue('auto-search')
  autoSearch,
  @JsonKey(name: 'search')
  search,
  @JsonKey(name: 'update')
  update,
}

extension on Type {
  bool get isSelfAction => this == Type.self;
  bool get isAutoSearchAction => this == Type.autoSearch;
  bool get isSearchAction => this == Type.search;
  bool get isUpdateAction => this == Type.update;
}

enum Method {
  @JsonKey(name: 'post')
  post,
  @JsonKey(name: 'put')
  put,
  @JsonKey(name: 'delete')
  delete,
  @JsonKey(name: 'get')
  get,
  @JsonKey(name: 'patch')
  patch,
}

@freezed
class Behavior with _$Behavior {
  const Behavior._();
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  @JsonKey(name: 'behavior')
  factory Behavior({
    required Type type,
    Method? method,
    String? uri,
    List<String>? requiredParameter,
    String? requiredTarget,
    List<int>? permission,
    Map<String, dynamic>? defaultParameter,
  }) = _Behavior;
  bool get isSearchAction => type.isSearchAction;
  bool get isSelfAction => type.isSelfAction;
  bool get isUpdateAction => type.isUpdateAction;
  bool get isAutoSearchAction => type.isAutoSearchAction;
  bool get isCommonSearch => requiredTarget != null;
  String? get ifId => defaultParameter?['if_id'];
  String? get apiIfId => defaultParameter?['api_if_id'];

  Future fetch({Map<String, dynamic>? parameter, Map<String, String>? header}) {
    final ApiService apiService = sl<ApiService>();
    try {
      return apiService
          .requestApi(
        method: method!,
        uri: uri!,
        data: {...?parameter, ...?defaultParameter},
        headers: header,
      )
          .then((ApiResponse apiResponse) {
        if (isSearchAction || isAutoSearchAction) {
          if (apiResponse.isError) return apiResponse;
          if (apiResponse.data == null) return SearchResponse(rows: []);
          if (apiResponse.data is Map<String, dynamic>) {
            var searchResponse = SearchResponse.fromJson(
                apiResponse.data as Map<String, dynamic>);
            return searchResponse;
          } else {
            print(
                "Warning: apiResponse.data is not a Map<String, dynamic> in Behavior.fetch for search action. Data: ${apiResponse.data}");
            return SearchResponse(rows: []);
          }
        }
        if (isSelfAction) {
          return apiResponse;
        }
        if (isUpdateAction) {
          return apiResponse;
        }
        return apiResponse.copyWith(
          result: apiResponse.result ?? -1,
          reason: apiResponse.reason ?? '관리자에게 문의 바랍니다.',
        );
      });
    } catch (e) {
      print("Exception in Behavior.fetch: $e");
      return Future.value(ApiResponse(result: -1, reason: e.toString()));
    }
  }

  factory Behavior.fromJson(Map<String, dynamic> json) =>
      _$BehaviorFromJson(json);
}
