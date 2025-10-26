import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:idev_viewer/src/internal/grid/trina_grid/src/helper/trina_general_helper.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_column_type_has_date_format.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/src/model/trina_column_type_has_popup_icon.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

class TrinaColumnTypeDateTime
    with TrinaColumnTypeDefaultMixin
    implements
        TrinaColumnType,
        TrinaColumnTypeHasFormat<String>,
        TrinaColumnTypeHasDateFormat,
        TrinaColumnTypeHasPopupIcon {
  @override
  final dynamic defaultValue;

  final DateTime? startDate;

  final DateTime? endDate;

  @override
  final String format;

  @override
  final String headerFormat;

  @override
  final bool applyFormatOnInit;

  @override
  final IconData? popupIcon;

  TrinaColumnTypeDateTime({
    this.defaultValue,
    this.startDate,
    this.endDate,
    required this.format,
    required this.headerFormat,
    required this.applyFormatOnInit,
    this.popupIcon,
  })  : dateFormat = intl.DateFormat(format),
        headerDateFormat = intl.DateFormat(headerFormat);

  @override
  final intl.DateFormat dateFormat;

  @override
  final intl.DateFormat headerDateFormat;

  @override
  bool isValid(dynamic value) {
    final parsedDateTime = DateTime.tryParse(value.toString());

    if (parsedDateTime == null) {
      return false;
    }

    if (startDate != null && parsedDateTime.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && parsedDateTime.isAfter(endDate!)) {
      return false;
    }

    return true;
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
    DateTime? dateTimeFormatValue;

    try {
      dateTimeFormatValue = dateFormat.parse(v.toString());
    } catch (e) {
      dateTimeFormatValue = null;
    }

    return dateTimeFormatValue;
  }

  @override
  String applyFormat(dynamic value) {
    final parseValue = DateTime.tryParse(value.toString());

    if (parseValue == null) {
      return '';
    }

    return dateFormat.format(DateTime.parse(value.toString()));
  }
}
