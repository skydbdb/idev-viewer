import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '/src/grid/trina_grid/trina_grid.dart';
import '/src/repo/home_repo.dart';

enum _CustomMenuItem {
  onGroup,
  offGroup,
  onSum,
  offSum,
  onAvg,
  offAvg,
  onMin,
  offMin,
  onMax,
  offMax,
  onCount,
  offCount
}

Map<String, String> aggregateTitle = {
  'onSum': '합계',
  'offSum': '합계',
  'onAvg': '평균',
  'offAvg': '평균',
  'onMin': '최소',
  'offMin': '최소',
  'onMax': '최대',
  'offMax': '최대',
  'onCount': '카운트',
  'offCount': '카운트',
};

// 전역 변수들을 관리하는 클래스
class ColumnStateManager {
  static final ColumnStateManager _instance = ColumnStateManager._internal();
  factory ColumnStateManager() => _instance;
  ColumnStateManager._internal();

  Map<String, bool> _colAggs = {};
  Set<String> _grpCols = {};

  // Stream 컨트롤러
  final StreamController<Map<String, bool>> _colAggsController =
      StreamController<Map<String, bool>>.broadcast();
  final StreamController<List<String>> _grpColsController =
      StreamController<List<String>>.broadcast();

  // Getter와 Setter
  Map<String, bool> get colAggs => Map.from(_colAggs);
  Set<String> get grpCols => Set.from(_grpCols);

  // JSON 직렬화를 위한 List getter
  List<String> get grpColsList => grpCols.toList();

  // Stream getter
  Stream<Map<String, bool>> get colAggsStream => _colAggsController.stream;
  Stream<List<String>> get grpColsStream => _grpColsController.stream;

  // colAggs 업데이트
  void updateColAggs(Map<String, bool> newColAggs) {
    _colAggs = Map.from(newColAggs);
    _colAggsController.add(_colAggs);
  }

  // colAggs 특정 키 업데이트
  void updateColAggsKey(String key, bool value) {
    _colAggs[key] = value;
    _colAggsController.add(_colAggs);
  }

  // grpCols 업데이트
  void updateGrpCols(Set<String> newGrpCols) {
    _grpCols = Set.from(newGrpCols);
    _grpColsController.add(_grpCols.toList());
  }

  // grpCols에 추가
  void addGrpCol(String field) {
    _grpCols.add(field);
    _grpColsController.add(_grpCols.toList());
  }

  // grpCols에서 제거
  void removeGrpCol(String field) {
    _grpCols.remove(field);
    _grpColsController.add(_grpCols.toList());
  }

  // 초기화
  void initialize(
      Map<String, bool> initialColAggs, Set<String> initialGrpCols) {
    _colAggs = Map.from(initialColAggs);
    _grpCols = Set.from(initialGrpCols);
  }

  // List로 초기화 (JSON에서 로드할 때)
  void initializeFromList(
      Map<String, bool> initialColAggs, List<String> initialGrpCols) {
    _colAggs = Map.from(initialColAggs);
    _grpCols = Set.from(initialGrpCols);
  }

  // 리소스 해제
  void dispose() {
    _colAggsController.close();
    _grpColsController.close();
  }
}

// 기존 전역 변수들을 ColumnStateManager로 대체
Map<String, bool> get colAggs => ColumnStateManager().colAggs;
Set<String> get grpCols => ColumnStateManager().grpCols;

class IdevColumnMenuDelegate implements TrinaColumnMenuDelegate<dynamic> {
  // Default delegate to handle standard menu items
  final TrinaColumnMenuDelegateDefault _defaultDelegate =
      const TrinaColumnMenuDelegateDefault();

  bool isGroupColumn(TrinaGridStateManager stateManager, TrinaColumn column) {
    return (stateManager.rowGroupDelegate as TrinaRowGroupByColumnDelegate)
        .columns
        .contains(column);
  }

  @override
  List<PopupMenuEntry<dynamic>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    final groupColumn = isGroupColumn(stateManager, column);

    // Get default menu items
    final defaultItems = _defaultDelegate
        .buildMenuItems(
      stateManager: stateManager,
      column: column,
    )
        .map((e) {
      if (e is PopupMenuItem<String>) {
        return PopupMenuItem<String>(
          value: e.value,
          height: 20,
          child: e.child,
        );
      }
      return e;
    }).toList();

    //remove the unfreeze item
    defaultItems.removeWhere((element) {
      if (element is PopupMenuItem<String>) {
        return element.value ==
                TrinaColumnMenuDelegateDefault.defaultMenuSetFilter ||
            element.value ==
                TrinaColumnMenuDelegateDefault.defaultMenuResetFilter;
      }
      return false;
    });

    // Add custom menu items (with a divider if there are default items)
    return [
      ...defaultItems,
      // if (defaultItems.isNotEmpty) const PopupMenuDivider(),
      PopupMenuItem<dynamic>(
        value: groupColumn ? _CustomMenuItem.offGroup : _CustomMenuItem.onGroup,
        height: 24,
        enabled: true,
        child: Text(
          groupColumn ? '그룹 해제' : '그룹 설정',
        ),
      ),
      if (column.type.isNumber ||
          column.type.isCurrency ||
          column.type.isPercentage)
        ..._CustomMenuItem.values
            .where((e) => !e.name.contains('Group') && e.name.contains('on'))
            .map((e) => PopupMenuItem<dynamic>(
                  height: 24,
                  value: colAggs['${column.field}-${e.name}'] ?? false
                      ? _CustomMenuItem.values
                          .byName(e.name.replaceAll('on', 'off'))
                      : e,
                  child: Text(
                    aggregateTitle[e.name] ?? e.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: colAggs['${column.field}-${e.name}'] ?? false
                          ? Colors.blueAccent
                          : Colors.grey,
                    ),
                  ),
                )),
      if (!column.type.isNumber &&
          !column.type.isCurrency &&
          !column.type.isPercentage)
        PopupMenuItem<dynamic>(
          height: 24,
          value: colAggs['${column.field}-onCount'] ?? false
              ? _CustomMenuItem.offCount
              : _CustomMenuItem.onCount,
          child: Text(
            "카운트",
            style: TextStyle(
              fontSize: 12,
              color: colAggs['${column.field}-onCount'] ?? false
                  ? Colors.blueAccent
                  : Colors.grey,
            ),
          ),
        )
    ];
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required dynamic selected,
  }) {
    // Handle custom menu items first
    context.read<HomeRepo>().addGridColumnMenuState(
      {
        'column': column,
        'selected': selected,
      },
    );

    if (selected == _CustomMenuItem.onGroup) {
      stateManager.setRowGroup(TrinaRowGroupByColumnDelegate(columns: [
        ...(stateManager.rowGroupDelegate as TrinaRowGroupByColumnDelegate)
            .columns,
        column,
      ]));
      stateManager.updateVisibilityLayout();
      ColumnStateManager().addGrpCol(column.field);
    } else if (selected == _CustomMenuItem.offGroup) {
      stateManager.setRowGroup(TrinaRowGroupByColumnDelegate(columns: [
        ...(stateManager.rowGroupDelegate as TrinaRowGroupByColumnDelegate)
            .columns
            .where((e) => e.field != column.field),
      ]));
      stateManager.updateVisibilityLayout();
      ColumnStateManager().removeGrpCol(column.field);
    } else if (selected is _CustomMenuItem) {
      final aggregateName = selected.name.replaceAll('off', 'on');

      // ColumnStateManager를 통해 업데이트
      ColumnStateManager().updateColAggsKey('${column.field}-$aggregateName',
          selected.name.contains('on') ? true : false);

      stateManager.setRowGroup(TrinaRowGroupByColumnDelegate(columns: [
        ...(stateManager.rowGroupDelegate as TrinaRowGroupByColumnDelegate)
            .columns
            .where((e) => e.field != column.field),
      ]));
      stateManager.updateVisibilityLayout();
    } else {
      _defaultDelegate.onSelected(
        context: context,
        stateManager: stateManager,
        column: column,
        mounted: mounted,
        selected: selected,
      );
    }
  }
}
