import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';

bool checkReadOnly(TrinaRow row, TrinaCell cell) {
  return row.cells['CUD']!.value != 'create';
}

Future<List<TrinaColumn>> columnConfig(
    List<Map<String, dynamic>> columnInfo) async {
  return columnInfo.map((e) {
    return TrinaColumn(
      title: e['value'],
      field: e['key'],
      width: e['width'] ?? 100,
      enableRowChecked: e['checked'] ?? false,
      readOnly: e['readOnly'] ?? true,
      checkReadOnly:
          (e['readOnly'] ?? true && e['key'] != 'CUD') ? checkReadOnly : null,
      type: e['type'] == null
          ? TrinaColumnType.text()
          : TrinaColumnType.select(e['type']['select'],
              // onItemSelected: (TrinaGridOnSelectedEvent event) {
              // },
              enableColumnFilter:
                  (e['type']['select'] as List).length > 20 ? true : false),
      // renderer: (rendererContext) {
      //   print('rendererContext: ${rendererContext.cell.value}');
      //   return Text(
      //     rendererContext.cell.value.toString().replaceAll('\\', '\n'),
      //     maxLines: 5,
      //   );
      // }
    );
  }).toList();
}
