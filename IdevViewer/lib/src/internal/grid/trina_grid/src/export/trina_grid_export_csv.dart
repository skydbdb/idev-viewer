import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

/// Implementation of [TrinaGridExport] for CSV format
class TrinaGridExportCsv implements TrinaGridExport {
  @override
  Future<String> export({
    required TrinaGridStateManager stateManager,
    List<String>? columns,
    bool includeHeaders = true,
    String separator = ',',
    bool ignoreFixedRows = false,
  }) async {
    // Get visible columns if no specific columns are requested
    final List<TrinaColumn> visibleColumns = columns != null
        ? stateManager.refColumns
            .where((column) => columns.contains(column.title))
            .toList()
        : stateManager.columns;

    if (visibleColumns.isEmpty) {
      throw Exception('No columns to export');
    }

    // Get rows
    // final List<TrinaRow> rows = stateManager.refRows;
    final List<TrinaRow> rows = stateManager.refRows.originalList;

    // Create CSV content
    final StringBuffer csvContent = StringBuffer();

    // Add header row if requested
    if (includeHeaders) {
      final List<String> headers = visibleColumns
          .map((column) => _escapeCsvField(column.title, separator))
          .toList();
      csvContent.writeln(headers.join(separator));
    }

    void addRowData(TrinaRow row) {
      final List<String> rowData = [];
      for (final column in visibleColumns) {
        final cell = row.cells[column.field];
        final value = cell?.value?.toString() ?? '';
        rowData.add(_escapeCsvField(value, separator));
      }
      csvContent.writeln(rowData.join(separator));
      // if ((row.type.isGroup ?? false) && !row.type.group.expanded) {
      //   for (final child in row.type.group.children) {
      //     addRowData(child);
      //   }
      // }
    }

    // Add data rows
    for (final row in rows) {
      if (ignoreFixedRows && row.frozen != TrinaRowFrozen.none) {
        continue;
      }
      addRowData(row);
    }

    return csvContent.toString();
  }

  /// Escapes a field for CSV format
  /// - If the field contains the separator, newlines, or double quotes, it is enclosed in double quotes
  /// - Double quotes within the field are escaped by doubling them
  String _escapeCsvField(String field, String separator) {
    if (field.contains(separator) ||
        field.contains('\n') ||
        field.contains('"')) {
      // Replace double quotes with two double quotes
      final escaped = field.replaceAll('"', '""');
      // Enclose in double quotes
      return '"$escaped"';
    }
    return field;
  }
}
