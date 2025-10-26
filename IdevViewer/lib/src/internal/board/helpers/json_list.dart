import 'dart:convert';

dynamic jsonList(dynamic json) {
  if (json == null || json.isEmpty) return [];
  try {
    return jsonDecode(json);
  } catch (err) {
    print('jsonList error: $err');
    return [];
  }
}

String jsonListToString(List<dynamic>? json) {
  if (json == null || json.isEmpty) return '';
  try {
    return jsonEncode(json);
  } catch (_) {
    return '';
  }
}
