import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

class TrinaColumnGroup {
  Widget title;

  final List<String>? fields;

  final List<TrinaColumnGroup>? children;

  final EdgeInsets? titlePadding;

  /// Text alignment in Cell. (Left, Right, Center)
  final TrinaColumnTextAlign titleTextAlign;

  /// Customize the column with TextSpan or WidgetSpan instead of the column's title string.
  ///
  /// ```
  /// titleSpan: const TextSpan(
  ///   children: [
  ///     WidgetSpan(
  ///       child: Text(
  ///         '* ',
  ///         style: TextStyle(color: Colors.red),
  ///       ),
  ///     ),
  ///     TextSpan(text: 'column title'),
  ///   ],
  /// ),
  /// ```
  final InlineSpan? titleSpan;

  /// It shows only one column.
  /// he height is set to the maximum depth of the group.
  /// The group title is not shown.
  final bool? expandedColumn;

  final Color? backgroundColor;

  final int level;

  TrinaColumnGroup({
    required this.title,
    this.fields,
    this.children,
    this.titlePadding,
    this.titleSpan,
    this.titleTextAlign = TrinaColumnTextAlign.center,
    this.expandedColumn = false,
    this.backgroundColor,
    this.level = 0,
    Key? key,
  })  : assert(fields == null
            ? (children != null && children.isNotEmpty)
            : fields.isNotEmpty && children == null),
        assert(expandedColumn == true
            ? fields?.length == 1 && children == null
            : true),
        _key = key ?? UniqueKey() {
    hasFields = fields != null;

    hasChildren = !hasFields;

    if (hasChildren) {
      for (final child in children!) {
        child.parent = this;
      }
    }
  }

  void setTitle(Widget newTitle) {
    title = newTitle;
  }

  Key get key => _key;

  final Key _key;

  late final bool hasFields;

  late final bool hasChildren;

  TrinaColumnGroup? parent;

  Iterable<TrinaColumnGroup> get parents sync* {
    var cursor = parent;

    while (cursor != null) {
      yield cursor;

      cursor = cursor.parent;
    }
  }

  // title 위젯에서 텍스트 추출하는 헬퍼 메서드
  String _extractTitleText() {
    if (title is Text) {
      return (title as Text).data ?? '';
    } else if (title is InkWell && (title as InkWell).child is Text) {
      return ((title as InkWell).child as Text).data ?? '';
    }
    return '';
  }

  // JSON으로 변환 - 계층 구조 포함
  Map<String, dynamic> toJson() {
    try {
      return {
        'title': _extractTitleText(),
        'fields': fields?.toList(),
        'level': level,
        'expandedColumn': expandedColumn,
        'backgroundColor': backgroundColor?.value,
        'children': children?.map((child) => child.toJson()).toList(),
        'hasFields': hasFields,
        'hasChildren': hasChildren,
      };
    } catch (e) {
      print('Error in toJson: $e');
      return {
        'title': '',
        'fields': [],
        'level': 0,
        'expandedColumn': false,
        'children': [],
        'hasFields': true,
        'hasChildren': false,
      };
    }
  }

  // JSON에서 객체 생성 - 계층 구조 포함
  static TrinaColumnGroup fromJson(Map<String, dynamic> json) {
    try {
      // 자식 그룹이 있는 경우 재귀적으로 생성
      List<TrinaColumnGroup>? childrenGroups;
      if (json['children'] != null) {
        childrenGroups = (json['children'] as List)
            .map((childJson) =>
                TrinaColumnGroup.fromJson(childJson as Map<String, dynamic>))
            .toList();
      }

      final group = TrinaColumnGroup(
        title: InkWell(
          onTap: () => print('${json['title']} -->'),
          child: Text(json['title'] as String? ?? ''),
        ),
        fields: json['hasFields'] == true
            ? (json['fields'] as List?)?.cast<String>()
            : null,
        children: childrenGroups,
        level: json['level'] as int? ?? 0,
        expandedColumn: json['expandedColumn'] as bool? ?? false,
        backgroundColor: json['backgroundColor'] != null
            ? Color(json['backgroundColor'] as int)
            : null,
      );

      // 부모-자식 관계 설정
      if (childrenGroups != null) {
        for (var child in childrenGroups) {
          child.parent = group;
        }
      }

      return group;
    } catch (e) {
      print('Error in fromJson: $e');
      // 오류 발생 시 기본 그룹 반환
      return TrinaColumnGroup(
        title: const Text(''),
        fields: [],
        level: 0,
      );
    }
  }

  // 계층 구조를 문자열로 표현 (디버깅용)
  String toStructureString({String indent = ''}) {
    var result = '$indent- ${_extractTitleText()} (Level: $level)\n';
    if (hasFields) {
      result += '$indent  Fields: ${fields?.join(", ")}\n';
    }
    if (hasChildren && children != null) {
      for (var child in children!) {
        result += child.toStructureString(indent: '$indent  ');
      }
    }
    return result;
  }
}

class TrinaColumnGroupPair {
  TrinaColumnGroup group;
  List<TrinaColumn> columns;

  TrinaColumnGroupPair({
    required this.group,
    required this.columns,
  }) :
        // a unique reproducible key
        _key = ValueKey(group.key.toString() +
            columns.fold("",
                (previousValue, element) => "$previousValue-${element.field}"));

  Key get key => _key;

  final Key _key;

  double get width {
    double sumWidth = 0;

    for (final column in columns) {
      sumWidth += column.width;
    }

    return sumWidth;
  }

  double get startPosition => columns.first.startPosition;
}
