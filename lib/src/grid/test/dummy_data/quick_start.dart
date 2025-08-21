import '/src/grid/trina_grid/trina_grid.dart';

class DummyData {
  List<TrinaColumn>? columns;
  List<TrinaRow>? rows;

  DummyData() {
    columns = [
      /// Text Column definition
      TrinaColumn(
        title: 'text column',
        field: 'text_field',
        type: TrinaColumnType.text(),
      ),

      /// Number Column definition
      TrinaColumn(
        title: 'number column',
        field: 'number_field',
        type: TrinaColumnType.number(),
      ),

      /// Select Column definition
      TrinaColumn(
        title: 'select column',
        field: 'select_field',
        type: TrinaColumnType.select(<String>['item1', 'item2', 'item3']),
      ),

      /// Datetime Column definition
      TrinaColumn(
        title: 'date column',
        field: 'date_field',
        type: TrinaColumnType.date(),
      ),

      /// Time Column definition
      TrinaColumn(
        title: 'time column',
        field: 'time_field',
        type: TrinaColumnType.time(),
      ),
    ];

    rows = [
      TrinaRow(
        cells: {
          'text_field': TrinaCell(value: 'Text cell value1'),
          'number_field': TrinaCell(value: 2020),
          'select_field': TrinaCell(value: 'item1'),
          'date_field': TrinaCell(value: '2020-08-06'),
          'time_field': TrinaCell(value: '12:30'),
        },
      ),
      TrinaRow(
        cells: {
          'text_field': TrinaCell(value: 'Text cell value2'),
          'number_field': TrinaCell(value: 2021),
          'select_field': TrinaCell(value: 'item2'),
          'date_field': TrinaCell(value: '2020-08-07'),
          'time_field': TrinaCell(value: '18:45'),
        },
      ),
      TrinaRow(
        cells: {
          'text_field': TrinaCell(value: 'Text cell value3'),
          'number_field': TrinaCell(value: 2022),
          'select_field': TrinaCell(value: 'item3'),
          'date_field': TrinaCell(value: '2020-08-08'),
          'time_field': TrinaCell(value: '23:59'),
        },
      ),
    ];
  }
}
