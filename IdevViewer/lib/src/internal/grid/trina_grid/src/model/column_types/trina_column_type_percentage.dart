import 'package:intl/intl.dart' as intl;
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

class TrinaColumnTypePercentage
    with TrinaColumnTypeWithNumberFormat
    implements TrinaColumnType, TrinaColumnTypeHasFormat<String> {
  @override
  final dynamic defaultValue;

  @override
  final bool negative;

  @override
  final bool applyFormatOnInit;

  @override
  final bool allowFirstDot;

  @override
  final String? locale;

  @override
  final String format;

  final int decimalDigits;

  final bool showSymbol;

  final PercentageSymbolPosition symbolPosition;

  TrinaColumnTypePercentage({
    this.defaultValue = 0,
    this.negative = true,
    this.decimalDigits = 2,
    this.showSymbol = true,
    this.symbolPosition = PercentageSymbolPosition.after,
    this.applyFormatOnInit = true,
    this.allowFirstDot = false,
    this.locale,
  })  : format = _createFormatPattern(
          decimalDigits: decimalDigits,
          symbolPosition: symbolPosition,
          showSymbol: showSymbol,
        ),
        numberFormat = _createNumberFormat(
          locale: locale,
          decimalDigits: decimalDigits,
          symbolPosition: symbolPosition,
          showSymbol: showSymbol,
        ),
        decimalPoint = decimalDigits;

  @override
  final intl.NumberFormat numberFormat;

  @override
  final int decimalPoint;

  static String _createFormatPattern({
    required int decimalDigits,
    required PercentageSymbolPosition symbolPosition,
    required bool showSymbol,
  }) {
    return symbolPosition == PercentageSymbolPosition.before
        ? '${showSymbol ? '%' : ''}#,##0.${'0' * decimalDigits}'
        : '#,##0.${'0' * decimalDigits}${showSymbol ? '%' : ''}';
  }

  static intl.NumberFormat _createNumberFormat({
    required String? locale,
    required int decimalDigits,
    required PercentageSymbolPosition symbolPosition,
    required bool showSymbol,
  }) {
    final pattern = _createFormatPattern(
      decimalDigits: decimalDigits,
      symbolPosition: symbolPosition,
      showSymbol: showSymbol,
    );

    return intl.NumberFormat(pattern, locale);
  }

  @override
  String applyFormat(dynamic value) {
    // If the value is already a formatted string that contains our symbol, return it as is
    if (showSymbol &&
        value is String &&
        ((symbolPosition == PercentageSymbolPosition.after &&
                value.endsWith('%')) ||
            (symbolPosition == PercentageSymbolPosition.before &&
                value.startsWith('%')))) {
      return value;
    }

    // Try to parse the value to a number
    num number = num.tryParse(
          value.toString().replaceAll(numberFormat.symbols.DECIMAL_SEP, '.'),
        ) ??
        0;

    if (negative == false && number < 0) {
      number = 0;
    }

    return numberFormat.format(number);
  }

  @override
  dynamic toNumber(String formatted) {
    // Remove the percentage symbol and other non-numeric characters
    String match = '0-9\\-${numberFormat.symbols.DECIMAL_SEP}';

    if (negative) {
      match += numberFormat.symbols.MINUS_SIGN;
    }

    formatted = formatted
        .replaceAll(RegExp('[^$match]'), '')
        .replaceFirst(numberFormat.symbols.DECIMAL_SEP, '.');

    final num formattedNumber = num.tryParse(formatted) ?? 0;

    final result =
        formattedNumber.abs() >= 1 ? formattedNumber / 100 : formattedNumber;

    return result.isFinite ? result : 0;
  }
}

/// Defines the position of the percentage symbol.
enum PercentageSymbolPosition {
  /// Symbol appears before the number (e.g. %50.00)
  before,

  /// Symbol appears after the number (e.g. 50.00%)
  after,
}
