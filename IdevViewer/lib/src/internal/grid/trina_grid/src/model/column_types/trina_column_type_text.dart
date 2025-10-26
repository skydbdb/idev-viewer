import 'package:idev_viewer/src/internal/grid/trina_grid/src/helper/trina_general_helper.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_column_type.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

class TrinaColumnTypeText implements TrinaColumnType {
  @override
  final dynamic defaultValue;

  const TrinaColumnTypeText({this.defaultValue});

  @override
  bool isValid(dynamic value) {
    return value is String || value is num;
  }

  @override
  int compare(dynamic a, dynamic b) {
    return TrinaGeneralHelper.compareWithNull(
      a,
      b,
      () => a.toString().compareTo(b.toString()),
    );
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v.toString();
  }
}
