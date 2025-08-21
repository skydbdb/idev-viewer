import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/core/stack_board_controller.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_content.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_v1/src/board/core/alignment_guide.dart';

class HierarchicalDockBoardController {
  final List<HierarchicalDockBoardController> _children = [];
  final Set<String> _childIds = {}; // 중복 방지를 위한 ID Set
  List<HierarchicalDockBoardController> get children => _children;

  HierarchicalDockBoardController({
    required this.id,
    required this.parentId,
    required this.controller,
  }) {
    debugPrint(
        '[HierarchicalDockBoardController] 생성: id=$id, parentId=$parentId');
  }

  final String id;
  final String? parentId;
  final StackBoardController controller;

  // 계층 구조 관련 메서드
  void addChild(HierarchicalDockBoardController child) {
    // 동일 레벨에서 동일한 ID의 컨트롤러 중복 방지
    if (_childIds.contains(child.id)) {
      return;
    }

    // 동일한 객체 참조인지 확인
    if (_children.contains(child)) {
      return;
    }

    _children.add(child);
    _childIds.add(child.id);
  }

  void removeChild(HierarchicalDockBoardController child) {
    _children.remove(child);
    _childIds.remove(child.id);
  }

  List<HierarchicalDockBoardController> getAllChildren() {
    List<HierarchicalDockBoardController> allChildren = [];
    for (final child in children) {
      allChildren.add(child);
      allChildren.addAll(child.getAllChildren());
    }
    return allChildren;
  }

  bool isInScope(String targetId) {
    if (id == targetId) return true;
    for (final child in children) {
      if (child.isInScope(targetId)) return true;
    }
    return false;
  }

  // StackBoardController 프록시 메서드들
  // 프로퍼티 프록시
  List<StackItem<StackItemContent>> get innerData => controller.innerData;
  List<StackItem<StackItemContent>> get innerDataSelected =>
      controller.innerDataSelected;
  Map<String, dynamic> get innerApi => controller.innerApi;
  Size? get boardSize => controller.boardSize;
  List<AlignmentGuide> get currentGuides => controller.currentGuides;

  // 기본 메서드 프록시
  StackItem<StackItemContent>? getById(String id) => controller.getById(id);
  int getIndexById(String id) => controller.getIndexById(id);
  void addItem(StackItem<StackItemContent> item, {bool selectIt = false}) =>
      controller.addItem(item, selectIt: selectIt);
  void removeItem(StackItem<StackItemContent> item) =>
      controller.removeItem(item);
  void removeById(String id) => controller.removeById(id);
  void updateItem(StackItem<StackItemContent> item) =>
      controller.updateItem(item);
  void clear() => controller.clear();
  void dispose() {
    // Frame 탭 컨트롤러는 dispose하지 않음 (Frame_xxx_tabIndex 패턴)
    if (id.startsWith('Frame_') && id.contains('_')) {
      final parts = id.split('_');
      if (parts.length >= 3) {
        final tabIndex = int.tryParse(parts.last);
        if (tabIndex != null) {
          return;
        }
      }
    }

    controller.dispose();
    for (final child in _children) {
      child.dispose();
    }
    _children.clear();
  }

  // 선택 관련 메서드 프록시
  void selectOne(String id, {bool forceMoveToTop = false}) =>
      controller.selectOne(id, forceMoveToTop: forceMoveToTop);
  void unSelectAll() => controller.unSelectAll();

  // 위치/크기 관련 메서드 프록시
  void updateBasic(String id,
          {Size? size,
          Offset? offset,
          double? angle,
          bool? dock,
          StackItemStatus? status,
          StackItemContent? content}) =>
      controller.updateBasic(id,
          size: size,
          offset: offset,
          angle: angle,
          dock: dock,
          status: status,
          content: content);
  void setBoardSize(Size size) => controller.setBoardSize(size);

  // 정렬 가이드 관련 메서드 프록시
  void setCurrentGuides(List<AlignmentGuide> guides) =>
      controller.setCurrentGuides(guides);
  void clearCurrentGuides() => controller.clearCurrentGuides();
  List<AlignmentGuide> detectAlignments(
          StackItem<StackItemContent> movingItem) =>
      controller.detectAlignments(movingItem);

  // Undo/Redo 메서드 프록시
  void undo() => controller.undo();
  void redo() => controller.redo();

  // 데이터 조회 메서드 프록시
  Map<String, dynamic>? getSelectedData() => controller.getSelectedData();
  Map<String, dynamic>? getDataById(String id) => controller.getDataById(id);
  List<Map<String, dynamic>>
      getTypeData<T extends StackItem<StackItemContent>>() =>
          controller.getTypeData<T>();
  List<Map<String, dynamic>> getAllData() => controller.getAllData();

  // 연산자 오버라이드 프록시
  @override
  int get hashCode => controller.hashCode;

  @override
  bool operator ==(Object other) => controller == other;
}
