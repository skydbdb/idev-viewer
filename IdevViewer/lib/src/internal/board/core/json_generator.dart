import 'dart:convert';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/helpers/compact_id_generator.dart';
import 'package:idev_viewer/src/internal/board/board/hierarchical_dock_board_controller.dart';

class BoardJsonGenerator {
  /// 템플릿 JSON 생성
  static Future<String> generateJson({
    required String boardId,
    required List<StackItem> selectedData,
    required Map<String, HierarchicalDockBoardController>
        hierarchicalControllers,
    String templateId = '#TEMPLATE#',
  }) async {
    List<Map<String, dynamic>> toJson = [];

    if (selectedData.isEmpty) {
      return '[]';
    }

    double minDx = 999999.0, minDy = 999999.0;
    Set<String> mainBoardItemIds = {};
    Set<String> processedChildBoards = {};

    // 1단계: 선택된 아이템들의 JSON 생성 및 최소 좌표 계산
    for (var item in selectedData) {
      toJson.add(item.toJson());
      mainBoardItemIds.add(item.id);

      if (item.offset.dx < minDx) {
        minDx = item.offset.dx;
      }
      if (item.offset.dy < minDy) {
        minDy = item.offset.dy;
      }
    }

    // 2단계: 계층 구조를 따라 하위 보드들의 데이터 수집 (Layout과 Frame 모두 지원)
    for (var item in selectedData) {
      _collectChildBoardData(
          item.id, toJson, processedChildBoards, hierarchicalControllers);
    }

    // 3단계: 좌표 정규화 (최소 좌표를 0으로 조정)
    for (var id in mainBoardItemIds) {
      for (var item in toJson) {
        if (item['id'] == id) {
          item['offset']['dx'] -= minDx;
          item['offset']['dy'] -= minDy;
        }
      }
    }

    String json = jsonEncode(toJson);
    String jsonString = replaceTemplateJson(json, boardId, templateId);

    return jsonString;
  }

  /// 하위 보드 데이터 수집
  static void _collectChildBoardData(
      String parentItemId,
      List<Map<String, dynamic>> toJson,
      Set<String> processedChildBoards,
      Map<String, HierarchicalDockBoardController> hierarchicalControllers) {
    // 부모 아이템 ID를 포함하는 하위 보드들을 찾음
    for (var entry in hierarchicalControllers.entries) {
      final childBoardId = entry.key;
      final childController = entry.value;

      // 이미 처리된 보드는 건너뛰기
      if (processedChildBoards.contains(childBoardId)) {
        continue;
      }

      bool isChildBoard = false;

      // 새로운 ID 시스템: 부모 정보를 통해 하위 보드 확인
      final childParentInfo = CompactIdGenerator.getParentInfo(childBoardId);
      if (childParentInfo != null) {
        final parts = childParentInfo.split(':');
        if (parts.isNotEmpty) {
          final childParentId = parts[0];
          // 부모 아이템 ID와 하위 보드의 부모 ID가 일치하는지 확인
          if (childParentId == parentItemId) {
            isChildBoard = true;
          }
        }
      }

      // 구식 Frame_id_tabIndex 패턴도 지원 (하위 호환성)
      if (!isChildBoard && childBoardId.startsWith('Frame_')) {
        final parts = childBoardId.split('_');
        if (parts.length >= 3) {
          // Frame_id 부분 추출 (마지막 tabIndex 제외)
          final frameId = parts.sublist(0, parts.length - 1).join('_');
          if (frameId == parentItemId) {
            isChildBoard = true;
          }
        }
      }

      if (isChildBoard) {
        // 하위 보드의 모든 데이터 수집
        final childData = childController.getAllData();
        toJson.addAll(childData);

        // 처리 완료 표시
        processedChildBoards.add(childBoardId);

        // 하위 보드의 아이템들에 대해서도 재귀적으로 처리
        for (var childItem in childController.innerData) {
          _collectChildBoardData(childItem.id, toJson, processedChildBoards,
              hierarchicalControllers);
        }
      }
    }
  }

  /// 템플릿 JSON에서 특정 문자열을 대체하는 함수
  static String replaceTemplateJson(
      String jsonString, String findStr, String replStr) {
    try {
      // 정규식에서 특수문자 이스케이프 처리
      String escapedFindStr = RegExp.escape(findStr);
      RegExp regExp = RegExp(escapedFindStr);

      return jsonString.replaceAllMapped(regExp, (match) {
        // 매치된 전체 문자열에서 findStr 부분을 replStr로 대체
        return match.group(0)!.replaceAll(findStr, replStr);
      });
    } catch (e) {
      return jsonString; // 오류 발생 시 원본 반환
    }
  }
}
