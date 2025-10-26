import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

abstract class TrinaColumnMenuDelegate<T> {
  List<PopupMenuEntry<T>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  });

  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required T? selected,
  });
}

class TrinaColumnMenuDelegateDefault
    implements TrinaColumnMenuDelegate<dynamic> {
  const TrinaColumnMenuDelegateDefault();

  static const String defaultMenuUnfreeze = 'unfreeze';
  static const String defaultMenuFreezeToStart = 'freezeToStart';
  static const String defaultMenuFreezeToEnd = 'freezeToEnd';
  static const String defaultMenuHideColumn = 'hideColumn';
  static const String defaultMenuSetColumns = 'setColumns';
  static const String defaultMenuAutoFit = 'autoFit';
  static const String defaultMenuSetFilter = 'setFilter';
  static const String defaultMenuResetFilter = 'resetFilter';

  @override
  List<PopupMenuEntry<dynamic>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    return _getDefaultColumnMenuItems(
      stateManager: stateManager,
      column: column,
    );
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required dynamic selected,
  }) {
    switch (selected) {
      case defaultMenuUnfreeze:
        stateManager.toggleFrozenColumn(column, TrinaColumnFrozen.none);
        break;
      case defaultMenuFreezeToStart:
        stateManager.toggleFrozenColumn(column, TrinaColumnFrozen.start);
        break;
      case defaultMenuFreezeToEnd:
        stateManager.toggleFrozenColumn(column, TrinaColumnFrozen.end);
        break;
      case defaultMenuAutoFit:
        if (!mounted) return;
        stateManager.autoFitColumn(context, column);
        stateManager.notifyResizingListeners();
        break;
      case defaultMenuHideColumn:
        stateManager.hideColumn(column, true);
        break;
      case defaultMenuSetColumns:
        if (!mounted) return;
        stateManager.showSetColumnsPopup(context);
        break;
      case defaultMenuSetFilter:
        if (!mounted) return;
        stateManager.showFilterPopup(context, calledColumn: column);
        break;
      case defaultMenuResetFilter:
        stateManager.setFilter(null);
        break;
      default:
        break;
    }
  }
}

/// Open the context menu on the right side of the column.
Future<T?>? showColumnMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<PopupMenuEntry<T>> items,
  Color backgroundColor = Colors.white,
}) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  return showMenu<T>(
    context: context,
    color: backgroundColor,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + overlay.size.width,
      position.dy + overlay.size.height,
    ),
    items: items,
    useRootNavigator: true,
  );
}

List<PopupMenuEntry<dynamic>> _getDefaultColumnMenuItems({
  required TrinaGridStateManager stateManager,
  required TrinaColumn column,
}) {
  final Color textColor = stateManager.style.cellTextStyle.color!;

  final Color disableTextColor = textColor.withAlpha((0.5 * 255).toInt());

  final bool enoughFrozenColumnsWidth = stateManager.enoughFrozenColumnsWidth(
    stateManager.maxWidth! - column.width,
  );

  final localeText = stateManager.localeText;

  return [
    if (column.frozen.isFrozen == true)
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuUnfreeze,
        text: localeText.unfreezeColumn,
        textColor: textColor,
      ),
    if (column.frozen.isFrozen != true) ...[
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuFreezeToStart,
        enabled: enoughFrozenColumnsWidth,
        text: localeText.freezeColumnToStart,
        textColor: enoughFrozenColumnsWidth ? textColor : disableTextColor,
      ),
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuFreezeToEnd,
        enabled: enoughFrozenColumnsWidth,
        text: localeText.freezeColumnToEnd,
        textColor: enoughFrozenColumnsWidth ? textColor : disableTextColor,
      ),
    ],
    const PopupMenuDivider(),
    _buildMenuItem(
      value: TrinaColumnMenuDelegateDefault.defaultMenuAutoFit,
      text: localeText.autoFitColumn,
      textColor: textColor,
    ),
    if (column.enableHideColumnMenuItem == true)
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuHideColumn,
        text: localeText.hideColumn,
        textColor: textColor,
        enabled: stateManager.refColumns.length > 1,
      ),
    if (column.enableSetColumnsMenuItem == true)
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuSetColumns,
        text: localeText.setColumns,
        textColor: textColor,
      ),
    if (column.enableFilterMenuItem == true) ...[
      const PopupMenuDivider(),
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuSetFilter,
        text: localeText.setFilter,
        textColor: textColor,
      ),
      _buildMenuItem(
        value: TrinaColumnMenuDelegateDefault.defaultMenuResetFilter,
        text: localeText.resetFilter,
        textColor: textColor,
        enabled: stateManager.hasFilter,
      ),
    ],
  ];
}

PopupMenuItem<String> _buildMenuItem({
  required String text,
  required Color? textColor,
  bool enabled = true,
  String? value,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: 36,
    enabled: enabled,
    child: Text(
      text,
      style: TextStyle(
        color: enabled ? textColor : textColor!.withAlpha((0.5 * 255).toInt()),
        fontSize: 13,
      ),
    ),
  );
}
