import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_response.freezed.dart';
part 'search_response.g.dart';

typedef Code = ({String? value, String? name});

toList(dynamic value) {
  if (value is Map) return [value];
  if (value == null) return [];
  return value;
}

parser(Map<String, dynamic>? value) {
  if (value == null) return;
  return Map.fromEntries(
    value.entries.expand(
          (code) => code.key.split('@').map(
            (e) => MapEntry(
          e,
          (code.value as List<dynamic>)
              .map((e) => (
              name: e['name'] as String?,
              value: e['value'] as String?
          ))
              .toList(),
        ),
      ),
    ),
  );
}

@freezed
class SearchResponse with _$SearchResponse {
  @JsonSerializable(explicitToJson: true)
  factory SearchResponse({
    @JsonKey(name: 'result', defaultValue: [], fromJson: toList)
    required List rows,
    @JsonKey(name: 'code', fromJson: parser) Map<String, List<Code>>? codes,
  }) = _SearchResponse;

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);
}
