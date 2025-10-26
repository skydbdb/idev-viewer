import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

import 'decimal_input_formatter.dart';
import 'text_cell.dart';

class TrinaPercentageCell extends StatefulWidget implements TextCell {
  @override
  final TrinaGridStateManager stateManager;

  @override
  final TrinaCell cell;

  @override
  final TrinaColumn column;

  @override
  final TrinaRow row;

  const TrinaPercentageCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    super.key,
  });

  @override
  TrinaPercentageCellState createState() => TrinaPercentageCellState();
}

class TrinaPercentageCellState extends State<TrinaPercentageCell>
    with TextCellState<TrinaPercentageCell> {
  late final int decimalRange;

  late final bool activatedNegative;

  late final bool allowFirstDot;

  late final String decimalSeparator;

  @override
  late final TextInputType keyboardType;

  @override
  late final List<TextInputFormatter>? inputFormatters;

  @override
  void initState() {
    super.initState();

    final percentageColumn = widget.column.type as TrinaColumnTypePercentage;

    decimalRange = percentageColumn.decimalPoint;

    activatedNegative = percentageColumn.negative;

    allowFirstDot = percentageColumn.allowFirstDot;

    decimalSeparator = percentageColumn.numberFormat.symbols.DECIMAL_SEP;

    inputFormatters = [
      DecimalTextInputFormatter(
        decimalRange: decimalRange,
        activatedNegativeValues: activatedNegative,
        allowFirstDot: allowFirstDot,
        decimalSeparator: decimalSeparator,
      ),
    ];

    keyboardType = TextInputType.numberWithOptions(
      decimal: decimalRange > 0,
      signed: activatedNegative,
    );
  }
}
