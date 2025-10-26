import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_response.freezed.dart';
part 'search_response.g.dart';

@freezed
class SearchResponse with _$SearchResponse {
  const factory SearchResponse({
    @Default([]) List<dynamic> rows,
    Map<String, List<CodeItem>>? codes,
  }) = _SearchResponseImpl;

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);
}

@freezed
class CodeItem with _$CodeItem {
  const factory CodeItem({
    required String name,
    required String value,
  }) = _CodeItemImpl;

  factory CodeItem.fromJson(Map<String, dynamic> json) =>
      _$CodeItemFromJson(json);
}

// Helper functions for JSON parsing
List<T> toList<T>(dynamic json) {
  if (json is List) {
    return json.cast<T>();
  }
  return [];
}

Map<String, List<CodeItem>>? parser(Map<String, dynamic>? json) {
  if (json == null) return null;

  return json.map((key, value) {
    if (value is List) {
      final List<CodeItem> codeItems = value
          .map((item) => CodeItem.fromJson(item as Map<String, dynamic>))
          .toList();
      return MapEntry(key, codeItems);
    }
    return MapEntry(key, <CodeItem>[]);
  });
}
