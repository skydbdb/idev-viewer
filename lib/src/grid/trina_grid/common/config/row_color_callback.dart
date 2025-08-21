import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';

Color rowColorCallback(TrinaRowColorContext rowColorContext) {
  if (rowColorContext.row.cells.keys.contains('CUD')) {
    if (rowColorContext.row.cells['CUD']!.value.toString().contains('update') ||
        rowColorContext.row.cells['CUD']!.value == 'update') {
      return Colors.lightGreenAccent;
    } else if (rowColorContext.row.cells['CUD']!.value
            .toString()
            .contains('delete') ||
        rowColorContext.row.cells['CUD']!.value == 'delete') {
      return Colors.redAccent;
    } else if (rowColorContext.row.cells['CUD']!.value
            .toString()
            .contains('create') ||
        rowColorContext.row.cells['CUD']!.value == 'create') {
      return Colors.yellowAccent;
    }
  }

  return rowColorContext.rowIdx % 2 == 0 ? Colors.white : Colors.black12;
}
