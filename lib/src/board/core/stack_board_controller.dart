import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/helpers/ex_list.dart';
import '/src/board/helpers/safe_value_notifier.dart';
import '/src/board/core/alignment_guide.dart';

class StackConfig {
  StackConfig({
    required this.data,
    required this.indexMap,
  });

  factory StackConfig.init() => StackConfig(
        data: <StackItem<StackItemContent>>[],
        indexMap: <String, int>{},
      );

  final List<StackItem<StackItemContent>> data;

  final Map<String, int> indexMap;

  StackItem<StackItemContent> operator [](String id) {
    if (!indexMap.containsKey(id)) {
      throw Exception('Item with id $id not found in StackConfig');
    }
    return data[indexMap[id]!];
  }

  StackConfig copyWith({
    List<StackItem<StackItemContent>>? data,
    Map<String, int>? indexMap,
  }) {
    return StackConfig(
      data: data ?? this.data,
      indexMap: indexMap ?? this.indexMap,
    );
  }

  @override
  String toString() {
    return 'StackConfig(data: $data, indexMap: $indexMap)';
  }
}

@immutable
// ignore: must_be_immutable
class StackBoardController extends SafeValueNotifier<StackConfig> {
  final String? boardId;

  StackBoardController({
    this.boardId,
    String? tag,
  })  : assert(tag != 'def', 'tag can not be "def"'),
        _tag = tag,
        super(StackConfig.init());

  factory StackBoardController.def() => _defaultController;

  final String? _tag;
  bool _isDisposed = false; // dispose 상태 추적

  Size? _boardSize;
  Size? get boardSize => _boardSize;

  final Map<String, int> _indexMap = <String, int>{};

  static final StackBoardController _defaultController =
      StackBoardController(tag: 'def');

  List<StackItem<StackItemContent>> get innerData {
    _checkDisposed();
    return value.data;
  }

  List<StackItem<StackItemContent>> get innerDataSelected {
    _checkDisposed();
    return value.data
        .where((e) => e.status == StackItemStatus.selected)
        .toList();
  }

  final Map<String, dynamic> innerApi = {}; //보드에 추가된 Api

  Map<String, int> get _newIndexMap => Map<String, int>.from(_indexMap);

  // dispose 상태 확인 메소드
  void _checkDisposed() {
    if (_isDisposed) {
      throw Exception(
          'StackBoardController was used after being disposed. BoardId: $boardId');
    }
  }

  // dispose 메소드 오버라이드
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  static const double _snapDistance = 5.0;
  List<AlignmentGuide> _currentGuides = [];
  List<AlignmentGuide> get currentGuides => _currentGuides;
  void setCurrentGuides(List<AlignmentGuide> guides) => _currentGuides = guides;
  void clearCurrentGuides() => _currentGuides = [];

  List<AlignmentGuide> detectAlignments(
      StackItem<StackItemContent> movingItem) {
    final List<StackItem<StackItemContent>> others = innerData
        .where(
            (e) => e.id != movingItem.id && e.status != StackItemStatus.locked)
        .toList();
    final List<AlignmentGuide> guides = [];
    for (final other in others) {
      guides.addAll(_calcAlignmentGuides(movingItem, other));
    }
    return guides.where((g) => g.distance < _snapDistance).toList();
  }

  List<AlignmentGuide> _calcAlignmentGuides(
      StackItem<StackItemContent> a, StackItem<StackItemContent> b) {
    final ax = a.offset.dx,
        ay = a.offset.dy,
        aw = a.size.width,
        ah = a.size.height;
    final bx = b.offset.dx,
        by = b.offset.dy,
        bw = b.size.width,
        bh = b.size.height;
    final acx = ax + aw / 2,
        bcx = bx + bw / 2,
        acy = ay + ah / 2,
        bcy = by + bh / 2;
    return [
      if ((acx - bcx).abs() < _snapDistance)
        AlignmentGuide(
            type: AlignmentType.verticalCenter,
            position: bcx,
            distance: (acx - bcx).abs()),
      if ((acy - bcy).abs() < _snapDistance)
        AlignmentGuide(
            type: AlignmentType.horizontalCenter,
            position: bcy,
            distance: (acy - bcy).abs()),
      if ((ax - bx).abs() < _snapDistance)
        AlignmentGuide(
            type: AlignmentType.leftEdge,
            position: bx,
            distance: (ax - bx).abs()),
      if ((ax + aw - (bx + bw)).abs() < _snapDistance)
        AlignmentGuide(
            type: AlignmentType.rightEdge,
            position: bx + bw,
            distance: (ax + aw - (bx + bw)).abs()),
      if ((ay - by).abs() < _snapDistance)
        AlignmentGuide(
            type: AlignmentType.topEdge,
            position: by,
            distance: (ay - by).abs()),
      if ((ay + ah - (by + bh)).abs() < _snapDistance)
        AlignmentGuide(
            type: AlignmentType.bottomEdge,
            position: by + bh,
            distance: (ay + ah - (by + bh)).abs()),
    ];
  }

  /// added undo redo
  final List<StackConfig> _history = [];
  final List<StackConfig> _redoHistory = [];

  List<StackConfig> get history => _history;
  List<StackConfig> get redoHistory => _redoHistory;

  void _saveState() {
    _history.add(value.copyWith(
      data: List<StackItem<StackItemContent>>.from(value.data),
      indexMap: Map<String, int>.from(value.indexMap),
    ));
    // _redoHistory.clear(); // 새 작업이 추가되면 redo 기록을 초기화
  }

  void undo() {
    if (_history.isNotEmpty) {
      _redoHistory.add(value.copyWith(
        data: List<StackItem<StackItemContent>>.from(value.data),
        indexMap: Map<String, int>.from(value.indexMap),
      ));
      final prev = _history.removeLast();
      value = prev;
    }
  }

  void redo() {
    if (_redoHistory.isNotEmpty) {
      _history.add(value.copyWith(
        data: List<StackItem<StackItemContent>>.from(value.data),
        indexMap: Map<String, int>.from(value.indexMap),
      ));
      final next = _redoHistory.removeLast();
      value = next;
    }
  }

  /// 히스토리 초기화
  void clearHistory() {
    _history.clear();
    _redoHistory.clear();
  }

  /// * get item by id
  StackItem<StackItemContent>? getById(String id) {
    if (!_indexMap.containsKey(id)) return null;
    return innerData[_indexMap[id]!];
  }

  /// * get index by id
  int getIndexById(String id) {
    return _indexMap[id]!;
  }

  /// * reorder index
  List<StackItem<StackItemContent>> _reorder(
      List<StackItem<StackItemContent>> data) {
    for (int i = 0; i < data.length; i++) {
      _indexMap[data[i].id] = i;
    }

    return data;
  }

  /// * add item
  void addItem(StackItem<StackItemContent> item, {bool selectIt = false}) {
    _saveState(); // 변경 사항 저장

    if (innerData.contains(item)) {
      return;
    }

    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    // Set items status to idle
    data.asMap().forEach((int index, StackItem<StackItemContent> item) {
      data[index] = item.copyWith(status: StackItemStatus.idle);
    });

    data.add(item);

    _indexMap[item.id] = data.length - 1;

    _reorder(data); // ★ 반드시 동기화
    value = value.copyWith(data: data, indexMap: _newIndexMap);
  }

  /// * remove item
  void removeItem(StackItem<StackItemContent> item) {
    _saveState(); // 변경 사항 저장

    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    data.remove(item);
    _indexMap.remove(item.id);

    _reorder(data);

    value = value.copyWith(data: data, indexMap: _newIndexMap);
  }

  /// * remove item by id
  void removeById(String id) {
    if (!_indexMap.containsKey(id)) return;

    _saveState(); // 변경 사항 저장

    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    data.removeAt(_indexMap[id]!);
    _indexMap.remove(id);

    _reorder(data);

    value = value.copyWith(data: data, indexMap: _newIndexMap);
  }

  /// * select only item
  void selectOne(String id, {bool forceMoveToTop = false}) {
    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    for (int i = 0; i < data.length; i++) {
      final StackItem<StackItemContent> item = data[i];
      final bool selectedOne = item.id == id;

      // locked 상태인 아이템은 절대 선택하지 않음
      if (item.status == StackItemStatus.locked) {
        continue; // locked 상태인 아이템은 건너뛰기
      }

      data[i] = item.copyWith(
          status:
              selectedOne ? StackItemStatus.selected : StackItemStatus.idle);
    }

    if (_indexMap.containsKey(id)) {
      final StackItem<StackItemContent> item = data[_indexMap[id]!];
      // locked 상태인 아이템은 Z 순서 변경도 하지 않음
      if (!item.lockZOrder && item.status != StackItemStatus.locked ||
          forceMoveToTop) {
        data.removeAt(_indexMap[id]!);
        data.add(item);
      }
    }

    _reorder(data);

    value = value.copyWith(data: data, indexMap: _newIndexMap);
  }

  void setBoardSize(Size size) {
    _boardSize = size;
  }

  /// * unselect all items
  void unSelectAll() {
    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    for (int i = 0; i < data.length; i++) {
      final StackItem<StackItemContent> item = data[i];
      if (item.status != StackItemStatus.locked) {
        data[i] = item.copyWith(
            status: item.status == StackItemStatus.editing
                ? StackItemStatus.selected
                : StackItemStatus.idle);
      }
    }

    value = value.copyWith(data: data, indexMap: _newIndexMap);
  }

  /// * update basic config
  void updateBasic(String id,
      {Size? size,
      Offset? offset,
      double? angle,
      bool? dock,
      StackItemStatus? status,
      StackItemContent? content}) {
    if (!_indexMap.containsKey(id)) return;

    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    final oldItem = data[_indexMap[id]!];
    final newItem = oldItem.copyWith(
      size: size,
      offset: offset,
      angle: angle,
      dock: dock,
      status: status,
      content: content,
    );

    data[_indexMap[id]!] = newItem;

    _reorder(data); // ★ 반드시 동기화

    value = value.copyWith(data: data, indexMap: _newIndexMap);
  }

  void updateItem(StackItem<StackItemContent> item) {
    if (!_indexMap.containsKey(item.id)) return;

    _saveState(); // 변경 사항 저장

    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    data[_indexMap[item.id]!] = item;

    value = value.copyWith(data: data);
  }

  /// * clear
  void clear() {
    _saveState(); // 변경 사항 저장

    value = StackConfig.init();
    _indexMap.clear();
  }

  /// * get selected item json data
  Map<String, dynamic>? getSelectedData() {
    return innerData
        .firstWhereOrNull(
          (StackItem<StackItemContent> item) =>
              item.status == StackItemStatus.selected,
        )
        ?.toJson();
  }

  /// * get data json by id
  Map<String, dynamic>? getDataById(String id) {
    return innerData
        .firstWhereOrNull((StackItem<StackItemContent> item) => item.id == id)
        ?.toJson();
  }

  /// * get data json list by type
  List<Map<String, dynamic>>
      getTypeData<T extends StackItem<StackItemContent>>() {
    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];

    for (int i = 0; i < data.length; i++) {
      final StackItem<StackItemContent> item = data[i];
      if (item is T) {
        final Map<String, dynamic> map = item.toJson();
        list.add(map);
      }
    }

    return list;
  }

  /// * get data json list
  List<Map<String, dynamic>> getAllData() {
    final List<StackItem<StackItemContent>> data =
        List<StackItem<StackItemContent>>.from(innerData);

    final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];

    for (int i = 0; i < data.length; i++) {
      final StackItem<StackItemContent> item = data[i];
      final Map<String, dynamic> map = item.toJson();
      list.add(map);
    }

    return list;
  }

  @override
  int get hashCode => _tag.hashCode;

  @override
  bool operator ==(Object other) =>
      other is StackBoardController && _tag == other._tag;

  @override
  set value(StackConfig newValue) {
    super.value = newValue;
    _indexMap
      ..clear()
      ..addAll(newValue.indexMap);
  }
}
