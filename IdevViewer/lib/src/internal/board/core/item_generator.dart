import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_viewer/src/internal/board/stack_items.dart';
import 'package:idev_viewer/src/internal/board/board/hierarchical_dock_board_controller.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_controller.dart';
import 'package:idev_viewer/src/internal/board/helpers/compact_id_generator.dart';
import 'package:idev_viewer/src/internal/board/core/json_generator.dart';

class BoardItemGenerator {
  static String prevJson = '';
  static int copyCount = 0;

  static setStartCopy(String json) {
    prevJson = json;
    copyCount = 0;
  }

  /// JSON으로부터 아이템들을 생성
  static Future<void> generateFromJson({
    required String json,
    required String boardId,
    required HierarchicalDockBoardController controller,
    required Map<String, HierarchicalDockBoardController>
        hierarchicalControllers,
    bool lockItems = false,
    String? templateId,
  }) async {
    if (json.isEmpty) {
      debugPrint('🔘 [BoardItemGenerator] generateFromJson: JSON이 비어있습니다.');
      return;
    }

    if (json.compareTo(prevJson) == 0) {
      copyCount = copyCount + 1;
    } else {
      copyCount = 0;
    }
    prevJson = json;

    try {
      String jsonString =
          BoardJsonGenerator.replaceTemplateJson(json, '#TEMPLATE#', boardId);

      // 1) first step: generate to boardId==new_1
      final List<dynamic> items = jsonDecode(jsonString) as List<dynamic>;

      if (items.isEmpty) {
        debugPrint('🔘 [BoardItemGenerator] generateFromJson: 파싱된 아이템이 없습니다.');
        return;
      }

      // ID 매핑을 위한 처리
      Map<String, String> idMapping = {};
      Map<String, String> boardIdMapping = {};

      // 기존 ID와 boardId를 수집하고 새로운 ID 생성
      for (var item in items) {
        String oldId = item['id'];
        String oldBoardId = item['boardId'];
        String type = item['type'];

        // 새로운 itemId 생성
        if (!idMapping.containsKey(oldId)) {
          String newId = CompactIdGenerator.generateItemId(type);
          idMapping[oldId] = newId;
        }

        // boardId 매핑 처리
        if (!boardIdMapping.containsKey(oldBoardId)) {
          if (oldBoardId == '#TEMPLATE#') {
            // #TEMPLATE#은 전달받은 boardId로 대체
            boardIdMapping[oldBoardId] = boardId;
          } else if (oldBoardId.startsWith('Frame_') &&
              oldBoardId.split('_').length > 2) {
            // Frame 내부 보드인 경우 (Frame_xxx_1, Frame_xxx_2 형식)
            String frameId =
                oldBoardId.substring(0, oldBoardId.lastIndexOf('_'));
            int tabIndex = int.parse(oldBoardId.split('_').last);
            String newFrameId = idMapping[frameId] ?? frameId;
            String newBoardId =
                CompactIdGenerator.generateFrameBoardId(newFrameId, tabIndex);
            boardIdMapping[oldBoardId] = newBoardId;
          } else {
            // 기타 boardId는 전달받은 boardId로 통일
            boardIdMapping[oldBoardId] = boardId;
          }
        }
      }

      // JSON 데이터 업데이트
      for (var item in items) {
        // ID 업데이트
        item['id'] = idMapping[item['id']]!;

        // BoardId 업데이트 (모든 아이템을 전달받은 boardId로 통일)
        item['boardId'] = boardIdMapping[item['boardId']]!;

        // tabsTitle 내부의 boardId도 업데이트 (Frame 아이템의 경우)
        if (item['type'] == 'StackFrameItem' && item['content'] != null) {
          var content = item['content'];
          if (content['tabsTitle'] != null && content['tabsTitle'].isNotEmpty) {
            try {
              List<dynamic> tabs = jsonDecode(content['tabsTitle']);
              bool updated = false;

              for (var tab in tabs) {
                if (tab['boardId'] != null &&
                    boardIdMapping.containsKey(tab['boardId'])) {
                  tab['boardId'] = boardIdMapping[tab['boardId']]!;
                  updated = true;
                }
              }

              if (updated) {
                content['tabsTitle'] = jsonEncode(tabs);
              }
            } catch (e) {
              // JSON 파싱 오류 처리
              debugPrint('tabsTitle JSON 파싱 오류: $e');
            }
          }
        }
      }

      // 메인 보드 아이템들 생성 (#TEMPLATE# 또는 전달받은 boardId와 같은 아이템들)
      List<dynamic> mainBoardItems =
          items.where((e) => e['boardId'] == boardId).toList();

      await generateItems(mainBoardItems,
          mainBoardId: boardId,
          hierarchicalControllers: hierarchicalControllers,
          lockItems: lockItems,
          applyOffset: copyCount > 0,
          originalIdMapping: idMapping);

      // Frame 내부 보드 아이템들 생성
      List<dynamic> frameBoardItems =
          items.where((e) => e['boardId'] != boardId).toList();

      await generateItems(frameBoardItems,
          hierarchicalControllers: hierarchicalControllers,
          lockItems: lockItems);
    } catch (e) {
      debugPrint('🔘 [BoardItemGenerator] generateFromJson: error: $e');
    }
  }

  /// 아이템 ID 생성
  static String generateItemId(String itemType) {
    return CompactIdGenerator.generateItemId(itemType);
  }

  /// 아이템들 생성
  static Future<void> generateItems(
    List<dynamic> items, {
    String? mainBoardId,
    required Map<String, HierarchicalDockBoardController>
        hierarchicalControllers,
    bool lockItems = false,
    bool applyOffset = false,
    Map<String, String>? originalIdMapping,
  }) async {
    for (dynamic item in items) {
      final boardId = mainBoardId ?? item['boardId'];

      HierarchicalDockBoardController? hierarchicalController =
          hierarchicalControllers[boardId];

      if (hierarchicalController == null) {
        final stackController = StackBoardController(
          boardId: boardId,
        );
        hierarchicalController = HierarchicalDockBoardController(
          id: boardId,
          parentId: mainBoardId != null
              ? null
              : _getParentBoardId(boardId, mainBoardId),
          controller: stackController,
        );
        hierarchicalControllers[boardId] = hierarchicalController;

        // 부모-자식 관계를 즉시 연결하여 트리/렌더 타이밍 문제 방지
        final String? parentId = hierarchicalController.parentId;
        if (parentId != null) {
          final parentController = hierarchicalControllers[parentId];
          if (parentController != null &&
              !parentController.children.contains(hierarchicalController)) {
            parentController.addChild(hierarchicalController);
          }
        }
      }

      // 오프셋 계산 - applyOffset이 true이고 기존 아이템이 있으면 약간 이동된 위치에 배치
      if (applyOffset) {
        //} && existingItem != null) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        final currentOffset = itemMap['offset'] as Map<String, dynamic>;

        // 오프셋을 copyCount * 20픽셀씩 이동
        currentOffset['dx'] =
            (currentOffset['dx'] as double) + 20.0 * copyCount;
        currentOffset['dy'] =
            (currentOffset['dy'] as double) + 20.0 * copyCount;

        itemMap['offset'] = currentOffset;
        // itemMap['id'] = itemId; // 새로운 ID로 업데이트
        item = itemMap;
      }

      try {
        // 각 아이템을 생성 (잠금 상태 옵션 적용)
        await _createItemByType(
          item: item,
          hierarchicalController: hierarchicalController,
          boardId: boardId,
          itemId: item['id'], // itemId,
          lockItems: lockItems,
        );
      } catch (e) {
        debugPrint(
            '🔘 [BoardItemGenerator] generateItems: 아이템 생성 오류 (${item['type']}): $e');
      }
    }
  }

  /// 아이템 타입에 따라 적절한 아이템 생성
  static Future<void> _createItemByType({
    required dynamic item,
    required HierarchicalDockBoardController hierarchicalController,
    required String boardId,
    required String itemId,
    bool lockItems = false,
  }) async {
    final itemType = item['type'] ?? '';
    final status = lockItems ? StackItemStatus.locked : StackItemStatus.idle;

    try {
      switch (itemType) {
        case 'StackTextItem':
          final textItem = StackTextItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(textItem);
          break;
        case 'StackImageItem':
          final imageItem = StackImageItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(imageItem);
          break;
        case 'StackSearchItem':
          final searchItem = StackSearchItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(searchItem);
          break;
        case 'StackGridItem':
          final gridItem = StackGridItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(gridItem);
          break;
        case 'StackFrameItem':
          final frameItem = StackFrameItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(frameItem);
          break;
        case 'StackLayoutItem':
          final layoutItem = StackLayoutItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(layoutItem);
          break;
        case 'StackButtonItem':
          final buttonItem = StackButtonItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(buttonItem);
          break;
        case 'StackDetailItem':
          final detailItem = StackDetailItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(detailItem);
          break;
        case 'StackChartItem':
          final chartItem = StackChartItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(chartItem);
          break;
        case 'StackSchedulerItem':
          final schedulerItem = StackSchedulerItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(schedulerItem);
          break;
        case 'StackTemplateItem':
          final templateItem = StackTemplateItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: status,
            lockZOrder: lockItems,
          );
          hierarchicalController.addItem(templateItem);
          break;
        default:
          debugPrint('[BoardItemGenerator] Unknown item type: $itemType');
          break;
      }
    } catch (e) {
      debugPrint('[BoardItemGenerator] Failed to create item: $itemId - $e');
    }
  }

  /// boardId에서 부모 보드 ID 추출
  static String? _getParentBoardId(String boardId, String? selectedBoardId) {
    // 최상위 보드인 경우 null 반환 (자체 참조 방지)
    if (boardId == selectedBoardId) {
      return null;
    }

    // CompactIdGenerator 매핑에서 찾기
    final parentInfo = CompactIdGenerator.getParentInfo(boardId);
    if (parentInfo != null) {
      final parentId = parentInfo.split(':')[0];
      return parentId;
    }

    // Frame_ 보드인 경우 Frame 찾기
    if (boardId.startsWith('Frame_')) {
      return 'new_1';
    }

    // 기존 로직
    final parts = boardId.split('_');
    if (parts.length >= 2) {
      final parentId = parts.sublist(0, parts.length - 1).join('_');
      return parentId;
    }

    return null;
  }
}
