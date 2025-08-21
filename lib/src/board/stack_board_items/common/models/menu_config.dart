import 'dart:convert';

class MenuConfig {
  final String menuId;
  final String label;
  final String icon;
  final String? selectedIcon;
  final String? script;
  final String? templateId;
  final String? subTemplateId;
  final String? parentId;
  final List<String>? children;

  MenuConfig({
    required this.menuId,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.script,
    this.templateId,
    this.subTemplateId,
    this.parentId,
    this.children,
  });

  factory MenuConfig.fromJson(Map<String, dynamic> json) {
    List<String>? parseStringList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      return null;
    }

    return MenuConfig(
      menuId: json['menuId'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String? ?? '',
      selectedIcon: json['selectedIcon'] as String?,
      parentId: json['parentId'] as String?,
      children: parseStringList(json['children']),
      script: json['script'] as String?,
      templateId: json['templateId'] as String?,
      subTemplateId: json['subTemplateId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'label': label,
      'icon': icon,
      if (selectedIcon != null) 'selectedIcon': selectedIcon,
      if (script != null) 'script': script,
      if (templateId != null) 'templateId': templateId,
      if (subTemplateId != null) 'subTemplateId': subTemplateId,
      if (parentId != null) 'parentId': parentId,
      if (children != null) 'children': children,
    };
  }
}

// 유틸리티 함수 (MenuConfig 리스트와 JSON 문자열 간 변환)
List<MenuConfig> menuConfigsFromJsonString(String? jsonString) {
  if (jsonString == null || jsonString.isEmpty || jsonString == 'null') {
    return [];
  }
  try {
    final List<dynamic> decodedList = jsonDecode(jsonString);
    return decodedList
        .map((item) => MenuConfig.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print(
        'Error parsing MenuConfig list from JSON string: $jsonString, Error: $e');
    return [];
  }
}

String menuConfigsToJsonString(List<MenuConfig>? menuConfigs) {
  if (menuConfigs == null || menuConfigs.isEmpty) {
    return '[]';
  }
  try {
    return jsonEncode(menuConfigs.map((config) => config.toJson()).toList());
  } catch (e) {
    print('Error encoding MenuConfig list to JSON string: $e');
    return '[]';
  }
}
