import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '/src/grid/trina_grid/src/manager/event/trina_grid_row_hover_event.dart';

import 'ui.dart';

class TrinaBaseRow extends StatelessWidget {
  final int rowIdx;

  final TrinaRow row;

  final List<TrinaColumn> columns;

  final TrinaGridStateManager stateManager;

  final bool visibilityLayout;

  const TrinaBaseRow({
    required this.rowIdx,
    required this.row,
    required this.columns,
    required this.stateManager,
    this.visibilityLayout = false,
    super.key,
  });

  bool _checkSameDragRows(DragTargetDetails<TrinaRow> draggingRow) {
    final List<TrinaRow> selectedRows =
        stateManager.currentSelectingRows.isNotEmpty
            ? stateManager.currentSelectingRows
            : [draggingRow.data];

    final end = rowIdx + selectedRows.length;

    for (int i = rowIdx; i < end; i += 1) {
      if (stateManager.refRows[i].key != selectedRows[i - rowIdx].key) {
        return false;
      }
    }

    return true;
  }

  bool _handleOnWillAccept(DragTargetDetails<TrinaRow> draggingRow) {
    return !_checkSameDragRows(draggingRow);
  }

  void _handleOnAccept(DragTargetDetails<TrinaRow> draggingRow) async {
    final draggingRows = stateManager.currentSelectingRows.isNotEmpty
        ? stateManager.currentSelectingRows
        : [draggingRow.data];

    stateManager.eventManager!.addEvent(
      TrinaGridDragRowsEvent(rows: draggingRows, targetIdx: rowIdx),
    );
  }

  TrinaVisibilityLayoutId _makeCell(TrinaColumn column) {
    return TrinaVisibilityLayoutId(
      id: column.field,
      child: TrinaBaseCell(
        key: row.cells[column.field]!.key,
        cell: row.cells[column.field]!,
        column: column,
        rowIdx: rowIdx,
        row: row,
        stateManager: stateManager,
      ),
    );
  }

  Widget _dragTargetBuilder(dragContext, candidate, rejected) {
    return _RowContainerWidget(
      stateManager: stateManager,
      rowIdx: rowIdx,
      row: row,
      enableRowColorAnimation:
          stateManager.configuration.style.enableRowColorAnimation,
      key: ValueKey('rowContainer_${row.key}'),
      child: visibilityLayout
          ? TrinaVisibilityLayout(
              key: ValueKey('rowContainer_${row.key}_row'),
              delegate: _RowCellsLayoutDelegate(
                stateManager: stateManager,
                columns: columns,
                textDirection: stateManager.textDirection,
              ),
              scrollController: stateManager.scroll.bodyRowsHorizontal!,
              initialViewportDimension: MediaQuery.of(dragContext).size.width,
              children: columns.map(_makeCell).toList(growable: false),
            )
          : CustomMultiChildLayout(
              key: ValueKey('rowContainer_${row.key}_row'),
              delegate: _RowCellsLayoutDelegate(
                stateManager: stateManager,
                columns: columns,
                textDirection: stateManager.textDirection,
              ),
              children: columns.map(_makeCell).toList(growable: false),
            ),
    );
  }

  void _handleOnEnter() {
    // set hovered row index
    stateManager.eventManager!.addEvent(
      TrinaGridRowHoverEvent(rowIdx: rowIdx, isHovered: true),
    );
  }

  void _handleOnExit() {
    // reset hovered row index
    stateManager.eventManager!.addEvent(
      TrinaGridRowHoverEvent(rowIdx: rowIdx, isHovered: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _handleOnEnter(),
      onExit: (event) => _handleOnExit(),
      child: DragTarget<TrinaRow>(
        onWillAcceptWithDetails: _handleOnWillAccept,
        onAcceptWithDetails: _handleOnAccept,
        builder: _dragTargetBuilder,
      ),
    );
  }
}

class _RowCellsLayoutDelegate extends MultiChildLayoutDelegate {
  final TrinaGridStateManager stateManager;

  final List<TrinaColumn> columns;

  final TextDirection textDirection;

  _RowCellsLayoutDelegate({
    required this.stateManager,
    required this.columns,
    required this.textDirection,
  }) : super(relayout: stateManager.resizingChangeNotifier);

  @override
  Size getSize(BoxConstraints constraints) {
    final double width = columns.fold(
      0,
      (previousValue, element) => previousValue + element.width,
    );

    return Size(width, stateManager.rowHeight);
  }

  @override
  void performLayout(Size size) {
    final isLTR = textDirection == TextDirection.ltr;
    final items = isLTR ? columns : columns.reversed;
    double dx = 0;

    for (var element in items) {
      var width = element.width;

      if (hasChild(element.field)) {
        layoutChild(
          element.field,
          BoxConstraints.tightFor(width: width, height: stateManager.rowHeight),
        );

        positionChild(element.field, Offset(dx, 0));
      }

      dx += width;
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class _RowContainerWidget extends TrinaStatefulWidget {
  final TrinaGridStateManager stateManager;

  final int rowIdx;

  final TrinaRow row;

  final bool enableRowColorAnimation;

  final Widget child;

  const _RowContainerWidget({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.enableRowColorAnimation,
    required this.child,
    super.key,
  });

  @override
  State<_RowContainerWidget> createState() => _RowContainerWidgetState();
}

class _RowContainerWidgetState extends TrinaStateWithChange<_RowContainerWidget>
    with
        AutomaticKeepAliveClientMixin,
        TrinaStateWithKeepAlive<_RowContainerWidget> {
  @override
  TrinaGridStateManager get stateManager => widget.stateManager;

  BoxDecoration _decoration = const BoxDecoration();

  Color get _oddRowColor => stateManager.configuration.style.oddRowColor == null
      ? stateManager.configuration.style.rowColor
      : stateManager.configuration.style.oddRowColor!;

  Color get _evenRowColor =>
      stateManager.configuration.style.evenRowColor == null
          ? stateManager.configuration.style.rowColor
          : stateManager.configuration.style.evenRowColor!;

  Color get _rowColor {
    if (widget.row.frozen != TrinaRowFrozen.none) {
      return stateManager.configuration.style.frozenRowColor;
    }
    return _getDefaultRowColor();
  }

  @override
  void initState() {
    super.initState();

    updateState(TrinaNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(TrinaNotifierEvent event) {
    _decoration = update<BoxDecoration>(_decoration, _getBoxDecoration());

    setKeepAlive(
      stateManager.isSelecting && stateManager.currentRowIdx == widget.rowIdx,
    );
  }

  Color _getDefaultRowColor() {
    if (stateManager.rowColorCallback == null) {
      return widget.rowIdx % 2 == 0 ? _oddRowColor : _evenRowColor;
    }

    return stateManager.rowColorCallback!(
      TrinaRowColorContext(
        rowIdx: widget.rowIdx,
        row: widget.row,
        stateManager: stateManager,
      ),
    );
  }

  BoxDecoration _getBoxDecoration() {
    final isCurrentRow = stateManager.currentRowIdx == widget.rowIdx;
    final isCheckedRow = widget.row.checked == true;
    final isHoveredRow = stateManager.isRowIdxHovered(widget.rowIdx);
    final isSelectedRow = stateManager.currentSelectingRows.contains(
      widget.row,
    );
    final isTopDragTarget = stateManager.isRowIdxTopDragTarget(widget.rowIdx);
    final isBottomDragTarget = stateManager.isRowIdxBottomDragTarget(
      widget.rowIdx,
    );

    Color rowColor = _rowColor;

    if ((isCurrentRow && stateManager.hasFocus) || isSelectedRow) {
      rowColor = stateManager.configuration.style.activatedColor;
    } else if (isCheckedRow) {
      rowColor = stateManager.configuration.style.rowCheckedColor;
    } else if (isHoveredRow &&
        stateManager.configuration.style.enableRowHoverColor) {
      rowColor = stateManager.configuration.style.rowHoveredColor;
    }

    final frozenBorder = widget.row.frozen != TrinaRowFrozen.none
        ? Border(
            top: BorderSide(
              width: TrinaGridSettings.rowBorderWidth,
              color: stateManager.configuration.style.frozenRowBorderColor,
            ),
            bottom: BorderSide(
              width: TrinaGridSettings.rowBorderWidth,
              color: stateManager.configuration.style.frozenRowBorderColor,
            ),
          )
        : null;

    return BoxDecoration(
      color: rowColor,
      border: frozenBorder ??
          Border(
            top: isTopDragTarget
                ? BorderSide(
                    width: TrinaGridSettings.rowBorderWidth,
                    color:
                        stateManager.configuration.style.activatedBorderColor,
                  )
                : BorderSide.none,
            bottom: isBottomDragTarget
                ? BorderSide(
                    width: TrinaGridSettings.rowBorderWidth,
                    color:
                        stateManager.configuration.style.activatedBorderColor,
                  )
                : stateManager.configuration.style.enableCellBorderHorizontal
                    ? BorderSide(
                        width: TrinaGridSettings.rowBorderWidth,
                        color: stateManager.configuration.style.borderColor,
                      )
                    : BorderSide.none,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _AnimatedOrNormalContainer(
      enable: widget.enableRowColorAnimation,
      decoration: _decoration,
      child: widget.child,
    );
  }
}

class _AnimatedOrNormalContainer extends StatelessWidget {
  final bool enable;

  final Widget child;

  final BoxDecoration decoration;

  const _AnimatedOrNormalContainer({
    required this.enable,
    required this.child,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return enable
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: decoration,
            child: child,
          )
        : DecoratedBox(decoration: decoration, child: child);
  }
}
