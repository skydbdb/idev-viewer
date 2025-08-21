import 'package:idev_v1/src/board/helpers.dart';
import '/src/grid/trina_grid/trina_grid.dart';

extension ExColumn on TrinaColumn {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'field': field,
      'type': type.runtimeType.toString(),
      'readOnly': readOnly,
      'textAlign': textAlign.value.name, // TrinaColumnTextAlign.start,
      'titleTextAlign':
          titleTextAlign.value.name, // TrinaColumnTextAlign.start,
      'enableRowChecked': enableRowChecked,
      'enableFilterMenuItem': enableFilterMenuItem,
      'hide': hide,
    };
  }
}

extension ExRow on TrinaRow {
  Map<String, dynamic> toJsonApiPopup() {
    return <String, dynamic>{
      ...toJson(),
      'rowIdx': sortIdx,
      'checked': checked
    };
  }
}

extension ExGrid on TrinaGrid {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'columns': columns.map((e) => e.toJson()).toList(),
      'rows': rows.map((e) => e.toJson()),
      'mode': mode.name
    };
  }
}

extension ExColumnGroup on TrinaColumnGroup {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      if (fields != null) 'fields': fields,
      if (children != null) 'children': children?.map((e) => e.toJson())
    };
  }
}

TrinaColumnGroup jsonToTrinaColumnGroup(Map<String, dynamic> data) {
  return TrinaColumnGroup(
    title: data['title'],
    fields: asNullT<List<String>>(data['fields']),
    children: data['children'] == null
        ? null
        : (data['children'] as List)
            .map((e) => jsonToTrinaColumnGroup(e))
            .toList(),
  );
}
