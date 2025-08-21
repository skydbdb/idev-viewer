import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';

abstract class PopupCell extends StatefulWidget {
  final TrinaGridStateManager stateManager;

  final TrinaCell cell;

  final TrinaColumn column;

  final TrinaRow row;

  const PopupCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    super.key,
  });
}

abstract class GridPopupProps {
  List<TrinaColumn> get popupColumns;

  List<TrinaRow> get popupRows;

  IconData? get icon;
}

mixin PopupCellState<T extends PopupCell> on State<T>
    implements GridPopupProps {
  bool isOpenedPopup = false;

  /// If a column field name is specified,
  /// the value of the field is returned even if another cell is selected.
  ///
  /// If the column field name is not specified,
  /// the value of the selected cell is returned.
  String? fieldOnSelected;

  double? popupHeight;

  int offsetOfScrollRowIdx = 0;

  /// Callback function that returns Header to be inserted at the top of the popup
  /// Implement a callback function that takes [TrinaGridStateManager] as a parameter.
  CreateHeaderCallBack? createHeader;

  /// Callback function that returns Footer to be inserted at the bottom of the popup
  /// Implement a callback function that takes [TrinaGridStateManager] as a parameter.
  CreateFooterCallBack? createFooter;

  late final TextEditingController textController;

  late final FocusNode textFocus;

  @override
  void initState() {
    super.initState();

    textController = TextEditingController()
      ..text = widget.column.formattedValueForDisplayInEditing(
        widget.cell.value,
      );

    textFocus = FocusNode(onKeyEvent: _handleKeyboardFocusOnKey);
  }

  @override
  void dispose() {
    textController.dispose();

    textFocus.dispose();

    super.dispose();
  }

  void openPopup() {
    if (widget.column.checkReadOnly(widget.row, widget.cell)) {
      return;
    }

    isOpenedPopup = true;

    TrinaGridPopup(
      context: context,
      mode: TrinaGridMode.select,
      onLoaded: onLoaded,
      onSelected: onSelected,
      columns: popupColumns,
      rows: popupRows,
      width: popupColumns.fold<double>(0, (previous, column) {
            return previous + column.width;
          }) +
          1,
      height: popupHeight,
      createHeader: createHeader,
      createFooter: createFooter,
      configuration: widget.stateManager.configuration.copyWith(
        tabKeyAction: TrinaGridTabKeyAction.normal,
        style: widget.stateManager.configuration.style.copyWith(
          oddRowColor: const TrinaOptional(null),
          evenRowColor: const TrinaOptional(null),
          gridBorderRadius:
              widget.stateManager.configuration.style.gridPopupBorderRadius,
          defaultColumnTitlePadding: TrinaGridSettings.columnTitlePadding,
          defaultCellPadding: TrinaGridSettings.cellPadding,
          rowHeight: widget.stateManager.configuration.style.rowHeight,
          enableRowColorAnimation: false,
        ),
      ),
    );
  }

  void onLoaded(TrinaGridOnLoadedEvent event) {
    for (var i = 0; i < popupRows.length; i += 1) {
      if (fieldOnSelected == null) {
        for (var entry in popupRows[i].cells.entries) {
          if (popupRows[i].cells[entry.key]!.value == widget.cell.value) {
            event.stateManager.setCurrentCell(
              event.stateManager.refRows[i].cells[entry.key],
              i,
            );
            break;
          }
        }
      } else {
        if (popupRows[i].cells[fieldOnSelected!]!.value == widget.cell.value) {
          event.stateManager.setCurrentCell(
            event.stateManager.refRows[i].cells[fieldOnSelected!],
            i,
          );
          break;
        }
      }
    }

    if (event.stateManager.currentRowIdx != null) {
      final rowIdxToMove =
          event.stateManager.currentRowIdx! + 1 + offsetOfScrollRowIdx;

      if (rowIdxToMove < event.stateManager.refRows.length) {
        event.stateManager.moveScrollByRow(TrinaMoveDirection.up, rowIdxToMove);
      } else {
        event.stateManager.moveScrollByRow(
          TrinaMoveDirection.up,
          event.stateManager.refRows.length,
        );
      }
    }
  }

  void onSelected(TrinaGridOnSelectedEvent event) {
    isOpenedPopup = false;

    dynamic selectedValue;

    if (event.row != null &&
        fieldOnSelected != null &&
        event.row!.cells.containsKey(fieldOnSelected)) {
      selectedValue = event.row!.cells[fieldOnSelected!]!.value;
    } else if (event.cell != null) {
      selectedValue = event.cell!.value;
    } else {
      widget.stateManager.setKeepFocus(true);
      textFocus.requestFocus();
      return;
    }

    handleSelected(selectedValue);
  }

  void handleSelected(dynamic value) {
    widget.stateManager.handleAfterSelectingRow(widget.cell, value);

    textController.text = widget.column.formattedValueForDisplayInEditing(
      widget.cell.value,
    );

    if (!widget.stateManager.configuration.enableMoveDownAfterSelecting) {
      textFocus.requestFocus();
    }
  }

  KeyEventResult _handleKeyboardFocusOnKey(FocusNode node, KeyEvent event) {
    var keyManager = TrinaKeyManagerEvent(focusNode: node, event: event);

    if (keyManager.isKeyUpEvent) {
      return KeyEventResult.handled;
    }

    if (keyManager.isF2 || keyManager.isCharacter) {
      if (isOpenedPopup != true) {
        openPopup();
        return KeyEventResult.handled;
      }
    }

    // 엔터키는 그리드 포커스 핸들러로 전파 한다.
    if (keyManager.isEnter) {
      return KeyEventResult.ignored;
    }

    // KeyManager 로 이벤트 처리를 위임 한다.
    widget.stateManager.keyManager!.subject.add(keyManager);

    // 모든 이벤트를 처리 하고 이벤트 전파를 중단한다.
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stateManager.keepFocus) {
      textFocus.requestFocus();
    }

    Widget w = TextField(
      focusNode: textFocus,
      controller: textController,
      readOnly: true,
      textInputAction: TextInputAction.none,
      onTap: openPopup,
      style: widget.stateManager.configuration.style.cellTextStyle,
      decoration: InputDecoration(
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        contentPadding: EdgeInsets.zero,
        suffixIcon: icon == null
            ? null
            : IconButton(
                icon: Icon(icon),
                color: widget.stateManager.configuration.style.iconColor,
                iconSize: widget.stateManager.configuration.style.iconSize,
                onPressed: openPopup,
              ),
      ),
      maxLines: 1,
      textAlignVertical: TextAlignVertical.center,
      textAlign: widget.column.textAlign.value,
    );

    if (widget.column.editCellRenderer != null) {
      w = widget.column.editCellRenderer!(
        w,
        widget.cell,
        textController,
        textFocus,
        handleSelected,
      );
    } else if (widget.stateManager.editCellRenderer != null) {
      w = widget.stateManager.editCellRenderer!(
        w,
        widget.cell,
        textController,
        textFocus,
        handleSelected,
      );
    }
    return w;
  }
}
