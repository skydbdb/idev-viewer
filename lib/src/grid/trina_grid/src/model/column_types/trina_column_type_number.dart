import 'package:intl/intl.dart' as intl;
import '/src/grid/trina_grid/trina_grid.dart';

class TrinaColumnTypeNumber
    with TrinaColumnTypeWithNumberFormat
    implements TrinaColumnType, TrinaColumnTypeHasFormat<String> {
  @override
  final dynamic defaultValue;

  @override
  final bool negative;

  @override
  final String format;

  @override
  final bool applyFormatOnInit;

  @override
  final bool allowFirstDot;

  @override
  final String? locale;

  TrinaColumnTypeNumber({
    this.defaultValue,
    required this.negative,
    required this.format,
    required this.applyFormatOnInit,
    required this.allowFirstDot,
    required this.locale,
  })  : numberFormat = intl.NumberFormat(format, locale),
        decimalPoint = _getDecimalPoint(format);

  @override
  final intl.NumberFormat numberFormat;

  @override
  final int decimalPoint;

  static int _getDecimalPoint(String format) {
    final int dotIndex = format.indexOf('.');

    return dotIndex < 0 ? 0 : format.substring(dotIndex).length - 1;
  }
}
