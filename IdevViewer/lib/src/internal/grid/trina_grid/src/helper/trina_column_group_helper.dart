import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

/// Helper class for handling [TrinaColumnGroup].
class TrinaColumnGroupHelper {
  /// Returns whether [field] exists in [columnGroup].
  static bool exists({
    required String field,
    required TrinaColumnGroup columnGroup,
  }) {
    if (columnGroup.hasFields) {
      return columnGroup.fields!.contains(field);
    }

    for (int i = 0; i < columnGroup.children!.length; i += 1) {
      if (exists(
        field: field,
        columnGroup: columnGroup.children![i],
      )) {
        return true;
      }
    }

    return false;
  }

  /// Returns whether [field] exists in [columnGroupList].
  static bool existsFromList({
    required String field,
    required List<TrinaColumnGroup> columnGroupList,
  }) {
    for (int i = 0; i < columnGroupList.length; i += 1) {
      if (exists(field: field, columnGroup: columnGroupList[i])) {
        return true;
      }
    }
    return false;
  }

  /// Find the parent class of [field] in [columnGroupList] and return it.
  /// Returns `null` if not found.
  static TrinaColumnGroup? getParentGroupIfExistsFromList({
    required String field,
    required List<TrinaColumnGroup> columnGroupList,
  }) {
    for (final columnGroup in columnGroupList) {
      if (columnGroup.hasFields && columnGroup.fields!.contains(field)) {
        return columnGroup;
      } else if (columnGroup.hasChildren) {
        for (int i = 0; i < columnGroup.children!.length; i += 1) {
          final found = getParentGroupIfExistsFromList(
            field: field,
            columnGroupList: columnGroup.children!,
          );

          if (found != null) {
            return found;
          }
        }
      }
    }

    return null;
  }

  /// Finds [TrinaColumnGroup] with [field] in [columnGroupList] and returns it.
  /// Returns `null` if not found.
  static TrinaColumnGroup? getGroupIfExistsFromList({
    required String field,
    required List<TrinaColumnGroup> columnGroupList,
  }) {
    for (int i = 0; i < columnGroupList.length; i += 1) {
      if (exists(field: field, columnGroup: columnGroupList[i])) {
        return columnGroupList[i];
      }
    }
    return null;
  }

  /// Separate groups according to the order of [columns].
  ///
  /// There are columns A, B, C, D, E
  /// If A and B are the same group, they are included as the same group.
  ///
  /// If C and E are in the same group,
  /// but there is D included in another group in the middle,
  /// C and E are in the same group but separated.
  static List<TrinaColumnGroupPair> separateLinkedGroup({
    required List<TrinaColumnGroup> columnGroupList,
    required List<TrinaColumn> columns,
  }) {
    if (columnGroupList.isEmpty || columns.isEmpty) {
      return [];
    }

    List<TrinaColumnGroupPair> separatedColumns = [];

    TrinaColumnGroup? previousGroup;

    List<TrinaColumn> linkedColumns = <TrinaColumn>[];

    for (int i = 0; i < columns.length; i += 1) {
      final column = columns[i];

      final field = column.field;

      final foundGroup = getGroupIfExistsFromList(
            field: field,
            columnGroupList: columnGroupList,
          ) ??
          TrinaColumnGroup(
            key: ValueKey(field),
            title: Text(field),
            fields: [field],
            expandedColumn: true,
          );

      previousGroup ??= foundGroup;

      if (previousGroup.key != foundGroup.key) {
        separatedColumns.add(TrinaColumnGroupPair(
          group: previousGroup,
          columns: linkedColumns,
        ));

        linkedColumns = [];

        previousGroup = foundGroup;
      }

      linkedColumns.add(column);

      if (i == columns.length - 1) {
        separatedColumns.add(TrinaColumnGroupPair(
          group: foundGroup,
          columns: linkedColumns,
        ));
      }
    }

    return separatedColumns;
  }

  /// [columnGroupList] Returns the depth of how many levels the group has been set.
  static int maxDepth({
    required List<TrinaColumnGroup> columnGroupList,
    int level = 0,
  }) {
    int currentDepth = level + 1;

    for (int i = 0; i < columnGroupList.length; i += 1) {
      if (columnGroupList[i].hasChildren) {
        final int depth = maxDepth(
          columnGroupList: columnGroupList[i].children!,
          level: level + 1,
        );

        if (depth > currentDepth) {
          currentDepth = depth;
        }
      }
    }

    return currentDepth;
  }

  TrinaColumnGroup createColumnGroup(String field) {
    return TrinaColumnGroup(
      title: Text(field),
      fields: [field],
    );
  }
}
