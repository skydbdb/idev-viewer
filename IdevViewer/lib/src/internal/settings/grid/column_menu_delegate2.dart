import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

class UserColumnMenu implements TrinaColumnMenuDelegate<UserColumnMenuItem> {
  @override
  List<PopupMenuEntry<UserColumnMenuItem>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    return [
      if (column.key != stateManager.columns.last.key)
        const PopupMenuItem<UserColumnMenuItem>(
          value: UserColumnMenuItem.moveNext,
          height: 36,
          enabled: true,
          child: Text('Move next', style: TextStyle(fontSize: 13)),
        ),
      if (column.key != stateManager.columns.first.key)
        const PopupMenuItem<UserColumnMenuItem>(
          value: UserColumnMenuItem.movePrevious,
          height: 36,
          enabled: true,
          child: Text('Move previous', style: TextStyle(fontSize: 13)),
        ),
    ];
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required UserColumnMenuItem? selected,
  }) {
    switch (selected) {
      case UserColumnMenuItem.moveNext:
        final targetColumn = stateManager.columns
            .skipWhile((value) => value.key != column.key)
            .skip(1)
            .first;

        stateManager.moveColumn(column: column, targetColumn: targetColumn);
        break;
      case UserColumnMenuItem.movePrevious:
        final targetColumn = stateManager.columns.reversed
            .skipWhile((value) => value.key != column.key)
            .skip(1)
            .first;

        stateManager.moveColumn(column: column, targetColumn: targetColumn);
        break;
      case null:
        break;
    }
  }
}

enum UserColumnMenuItem {
  moveNext,
  movePrevious,
}
