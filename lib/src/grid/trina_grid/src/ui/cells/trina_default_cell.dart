import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';

import '../ui.dart';

typedef DragUpdatedCallback = Function(Offset offset);

class TrinaDefaultCell extends TrinaStatefulWidget {
  final TrinaCell cell;

  final TrinaColumn column;

  final int rowIdx;

  final TrinaRow row;

  final TrinaGridStateManager stateManager;

  const TrinaDefaultCell({
    required this.cell,
    required this.column,
    required this.rowIdx,
    required this.row,
    required this.stateManager,
    super.key,
  });

  @override
  State<TrinaDefaultCell> createState() => _TrinaDefaultCellState();

  static String groupCountText(TrinaRowGroupDelegate delegate, TrinaRow row) {
    final compactCount = delegate.enableCompactCount;
    final count = compactCount
        ? delegate.compactNumber(row.type.group.children.length)
        : row.type.group.children.length.toString();
    return '($count)';
  }

  static TextStyle groupCountTextStyle(TrinaGridStyleConfig style) {
    return style.cellTextStyle.copyWith(
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );
  }

  static bool canExpand(TrinaRowGroupDelegate? delegate, TrinaCell cell) {
    if (delegate == null) return false;
    if (!cell.row.type.isGroup || !delegate.enabled) {
      return false;
    }
    return delegate.isExpandableCell(cell);
  }

  static bool showGroupCount(TrinaRowGroupDelegate? delegate, TrinaCell cell) {
    if (delegate == null) return false;
    return delegate.enabled &&
        delegate.isExpandableCell(cell) &&
        cell.row.type.isGroup &&
        delegate.showCount;
  }
}

class _TrinaDefaultCellState extends TrinaStateWithChange<TrinaDefaultCell> {
  bool _hasFocus = false;

  bool _canRowDrag = false;

  bool _isCurrentCell = false;

  String _text = '';

  @override
  TrinaGridStateManager get stateManager => widget.stateManager;

  bool get _showSpacing {
    if (!stateManager.enabledRowGroups ||
        !stateManager.rowGroupDelegate!.showFirstExpandableIcon) {
      return false;
    }

    if (TrinaDefaultCell.canExpand(
        stateManager.rowGroupDelegate!, widget.cell)) {
      return true;
    }

    final parentCell = widget.row.parent?.cells[widget.column.field];

    return parentCell != null &&
        stateManager.rowGroupDelegate!.isExpandableCell(parentCell);
  }

  bool get _isEmptyGroup => widget.row.type.group.children.isEmpty;

  @override
  void initState() {
    super.initState();

    updateState(TrinaNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(TrinaNotifierEvent event) {
    final disable =
        widget.column.disableRowCheckboxWhen?.call(widget.row) ?? false;
    if (disable) return;

    _hasFocus = update<bool>(
      _hasFocus,
      stateManager.hasFocus,
    );

    _canRowDrag = update<bool>(
      _canRowDrag,
      widget.column.enableRowDrag && stateManager.canRowDrag,
    );

    _isCurrentCell = update<bool>(
      _isCurrentCell,
      stateManager.isCurrentCell(widget.cell),
    );

    _text = update<String>(
      _text,
      widget.column.formattedValueForDisplay(widget.cell.value),
    );
  }

  void _handleToggleExpandedRowGroup() {
    stateManager.toggleExpandedRowGroup(
      rowGroup: widget.row,
    );
  }

  @override
  Widget build(BuildContext context) {
    int depth = 0; //
    TrinaRow? row = widget.row;
    while (row?.parent != null) {
      depth++;
      row = row?.parent;
    }
    final cellWidget = _DefaultCellWidget(
      stateManager: stateManager,
      rowIdx: widget.rowIdx,
      row: widget.row,
      column: widget.column,
      cell: widget.cell,
    );

    final style = stateManager.configuration.style;

    Widget? spacingWidget;
    if (_showSpacing) {
      if (widget.row.depth > 0) {
        double gap = style.iconSize * 1.5;
        double spacing = widget.row.depth * gap;
        if (!widget.row.type.isGroup) spacing += gap;
        spacingWidget = SizedBox(width: spacing);
      }
    }

    Widget? expandIcon;
    if (TrinaDefaultCell.canExpand(
        stateManager.rowGroupDelegate, widget.cell)) {
      expandIcon = IconButton(
        padding: const EdgeInsets.only(bottom: 0.0),
        onPressed: _isEmptyGroup ? null : _handleToggleExpandedRowGroup,
        icon: _isEmptyGroup
            ? Icon(
                style.rowGroupEmptyIcon,
                size: style.iconSize / 2,
                color: style.iconColor,
              )
            : widget.row.type.group.expanded
                ? Icon(
                    style.rowGroupExpandedIcon,
                    size: style.iconSize,
                    color: style.iconColor,
                  )
                : Icon(
                    style.rowGroupCollapsedIcon,
                    size: style.iconSize,
                    color: style.iconColor,
                  ),
      );
    }

    return Row(children: [
      if (_canRowDrag)
        _RowDragIconWidget(
          column: widget.column,
          row: widget.row,
          rowIdx: widget.rowIdx,
          stateManager: stateManager,
          feedbackWidget: cellWidget,
          dragIcon: Icon(
            Icons.drag_indicator,
            size: style.iconSize,
            color: style.iconColor,
          ),
        ),
      if (widget.column.enableRowChecked &&
          depth >= widget.column.rowCheckBoxGroupDepth)
        CheckboxSelectionWidget(
          column: widget.column,
          row: widget.row,
          rowIdx: widget.rowIdx,
          stateManager: stateManager,
        ),
      if (spacingWidget != null) spacingWidget,
      if (expandIcon != null) expandIcon,
      Expanded(child: cellWidget),
      if (TrinaDefaultCell.showGroupCount(
          stateManager.rowGroupDelegate, widget.cell))
        Text(
          TrinaDefaultCell.groupCountText(
              stateManager.rowGroupDelegate!, widget.row),
          style: TrinaDefaultCell.groupCountTextStyle(stateManager.style),
        ),
    ]);
  }
}

class _RowDragIconWidget extends StatelessWidget {
  final TrinaColumn column;

  final TrinaRow row;

  final int rowIdx;

  final TrinaGridStateManager stateManager;

  final Widget dragIcon;

  final Widget feedbackWidget;

  const _RowDragIconWidget({
    required this.column,
    required this.row,
    required this.rowIdx,
    required this.stateManager,
    required this.dragIcon,
    required this.feedbackWidget,
  });

  List<TrinaRow> get _draggingRows {
    if (stateManager.currentSelectingRows.isEmpty) {
      return [row];
    }

    if (stateManager.isSelectedRow(row.key)) {
      return stateManager.currentSelectingRows;
    }

    // In case there are selected rows,
    // if the dragging row is not included in it,
    // the selection of rows is invalidated.
    stateManager.clearCurrentSelecting(notify: false);

    return [row];
  }

  void _handleOnPointerDown(PointerDownEvent event) {
    stateManager.setIsDraggingRow(true, notify: false);

    stateManager.setDragRows(_draggingRows);
  }

  void _handleOnPointerMove(PointerMoveEvent event) {
    // Do not drag while rows are selected.
    if (stateManager.isSelecting) {
      stateManager.setIsDraggingRow(false);

      return;
    }

    stateManager.eventManager!.addEvent(TrinaGridScrollUpdateEvent(
      offset: event.position,
    ));

    int? targetRowIdx = stateManager.getRowIdxByOffset(
      event.position.dy,
    );

    stateManager.setDragTargetRowIdx(targetRowIdx);
  }

  void _handleOnPointerUp(PointerUpEvent event) {
    stateManager.setIsDraggingRow(false);

    TrinaGridScrollUpdateEvent.stopScroll(
      stateManager,
      TrinaGridScrollUpdateDirection.all,
    );
  }

  @override
  Widget build(BuildContext context) {
    final translationX = stateManager.isRTL ? -0.92 : -0.08;

    return Listener(
      onPointerDown: _handleOnPointerDown,
      onPointerMove: _handleOnPointerMove,
      onPointerUp: _handleOnPointerUp,
      child: Draggable<TrinaRow>(
        data: row,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: FractionalTranslation(
          translation: Offset(translationX, -0.5),
          child: Material(
            child: TrinaShadowContainer(
              width: column.width,
              height: stateManager.rowHeight,
              backgroundColor:
                  stateManager.configuration.style.gridBackgroundColor,
              borderColor:
                  stateManager.configuration.style.activatedBorderColor,
              child: Row(
                children: [
                  dragIcon,
                  Expanded(
                    child: feedbackWidget,
                  ),
                ],
              ),
            ),
          ),
        ),
        child: dragIcon,
      ),
    );
  }
}

class CheckboxSelectionWidget extends TrinaStatefulWidget {
  final TrinaGridStateManager stateManager;

  final TrinaColumn column;

  final TrinaRow row;

  final int rowIdx;

  const CheckboxSelectionWidget({
    required this.stateManager,
    required this.column,
    required this.row,
    required this.rowIdx,
    super.key,
  });

  @override
  CheckboxSelectionWidgetState createState() => CheckboxSelectionWidgetState();
}

class CheckboxSelectionWidgetState
    extends TrinaStateWithChange<CheckboxSelectionWidget> {
  bool _tristate = false;

  bool? _checked;
  bool _pureValue = false;

  @override
  TrinaGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();
    updateState(TrinaNotifierEventForceUpdate.instance);
    _pureValue = widget.row.checked ?? false;
  }

  @override
  void updateState(TrinaNotifierEvent event) {
    final disable =
        widget.column.disableRowCheckboxWhen?.call(widget.row) ?? false;
    if (disable) {
      _checked = _pureValue;
      return;
    }

    _tristate = update<bool>(
      _tristate,
      stateManager.enabledRowGroups && widget.row.type.isGroup,
    );

    _checked = update<bool?>(
      _checked,
      _tristate ? widget.row.checked : widget.row.checked == true,
    );
  }

  void _handleOnChanged(bool? changed) {
    if (changed == _checked) {
      return;
    }

    if (_tristate) {
      changed ??= false;

      if (_checked == null) changed = true;
    } else {
      changed = changed == true;
    }

    stateManager.setRowChecked(widget.row, changed);

    if (stateManager.onRowChecked != null) {
      stateManager.onRowChecked!(
        TrinaGridOnRowCheckedOneEvent(
          row: widget.row,
          rowIdx: widget.rowIdx,
          isChecked: changed,
        ),
      );
    }

    setState(() {
      _checked = changed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disable =
        widget.column.disableRowCheckboxWhen?.call(widget.row) ?? false;

    return TrinaScaledCheckbox(
      value: _checked,
      handleOnChanged: disable ? null : _handleOnChanged,
      tristate: _tristate,
      scale: 0.86,
      unselectedColor: stateManager.configuration.style.cellUnselectedColor,
      activeColor: stateManager.configuration.style.cellActiveColor,
      checkColor: stateManager.configuration.style.cellCheckedColor,
    );
  }
}

class _DefaultCellWidget extends StatelessWidget {
  final TrinaGridStateManager stateManager;

  final int rowIdx;

  final TrinaRow row;

  final TrinaColumn column;

  final TrinaCell cell;

  const _DefaultCellWidget({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.column,
    required this.cell,
  });

  bool get _showText {
    if (!stateManager.enabledRowGroups) {
      return true;
    }

    return stateManager.rowGroupDelegate!.isExpandableCell(cell) ||
        stateManager.rowGroupDelegate!.isEditableCell(cell);
  }

  String get _text {
    if (!_showText) return '';

    dynamic cellValue = cell.value;

    if (stateManager.enabledRowGroups &&
        stateManager.rowGroupDelegate!.showFirstExpandableIcon &&
        stateManager.rowGroupDelegate!.type.isByColumn) {
      final delegate =
          stateManager.rowGroupDelegate as TrinaRowGroupByColumnDelegate;

      if (row.depth < delegate.columns.length) {
        cellValue = row.cells[delegate.columns[row.depth].field]!.value;
      }
    }

    return column.formattedValueForDisplay(cellValue);
  }

  @override
  Widget build(BuildContext context) {
    // Check for cell renderer first
    if (cell.hasRenderer) {
      return cell.renderer!(TrinaCellRendererContext(
        column: column,
        rowIdx: rowIdx,
        row: row,
        cell: cell,
        stateManager: stateManager,
      ));
    }

    // Fall back to column renderer
    if (column.hasRenderer) {
      return column.renderer!(TrinaColumnRendererContext(
        column: column,
        rowIdx: rowIdx,
        row: row,
        cell: cell,
        stateManager: stateManager,
      ));
    }

    return Text(
      _text,
      style: stateManager.configuration.style.cellTextStyle.copyWith(
        decoration: TextDecoration.none,
        fontWeight: FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: column.textAlign.value,
    );
  }
}
