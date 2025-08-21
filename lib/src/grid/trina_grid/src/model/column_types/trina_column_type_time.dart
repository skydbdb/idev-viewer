import 'package:flutter/material.dart';
import '/src/grid/trina_grid/src/helper/trina_general_helper.dart';
import '/src/grid/trina_grid/src/model/trina_column_type.dart';
import '/src/grid/trina_grid/src/model/trina_column_type_has_popup_icon.dart';
import '/src/grid/trina_grid/trina_grid.dart';

class TrinaColumnTypeTime
    implements TrinaColumnType, TrinaColumnTypeHasPopupIcon {
  @override
  final dynamic defaultValue;

  @override
  final IconData? popupIcon;

  const TrinaColumnTypeTime({this.defaultValue, this.popupIcon});

  static final _timeFormat = RegExp(r'^([0-1]?\d|2[0-3]):[0-5]\d$');

  @override
  bool isValid(dynamic value) {
    return _timeFormat.hasMatch(value.toString());
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
    return v;
  }
}
