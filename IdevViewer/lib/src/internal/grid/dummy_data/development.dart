import 'package:faker/faker.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_column.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_row.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_column_type.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_cell.dart';

class DummyData {
  static List<TrinaRow> rowsByColumns({
    required int length,
    required List<TrinaColumn> columns,
  }) {
    final faker = Faker();
    final List<TrinaRow> rows = [];

    for (int i = 0; i < length; i++) {
      final Map<String, TrinaCell> cells = {};
      for (var column in columns) {
        cells[column.field] =
            TrinaCell(value: _generateValue(faker, column.type));
      }
      rows.add(TrinaRow(cells: cells));
    }

    return rows;
  }

  static dynamic _generateValue(Faker faker, TrinaColumnType type) {
    switch (type.toString()) {
      case 'TrinaColumnType.text()':
        return faker.lorem.word();
      case 'TrinaColumnType.number()':
        return faker.randomGenerator.integer(1000);
      default:
        return null;
    }
  }
}
