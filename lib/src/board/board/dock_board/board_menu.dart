import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/helpers/compact_id_generator.dart';
import 'package:idev_v1/src/const/code.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import 'package:idev_v1/src/board/board/hierarchical_dock_board_controller.dart';

class BoardMenu extends StatelessWidget {
  const BoardMenu({super.key, required this.context, required this.homeRepo});
  final BuildContext context;
  final HomeRepo homeRepo;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  /// get template json
  Future<String> getTemplateJson() async {
    List<Map<String, dynamic>> toJson = [];
    final findBoardId = homeRepo.selectedBoardId ?? homeRepo.currentTab;
    final currentBoardController =
        homeRepo.hierarchicalControllers[findBoardId];

    if (currentBoardController == null) {
      return '[]';
    }

    final selectedData = currentBoardController.getSelectedData() != null
        ? currentBoardController.innerDataSelected
        : currentBoardController.innerData;

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
      _collectChildBoardData(item.id, toJson, processedChildBoards,
          homeRepo.hierarchicalControllers);
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
    String jsonString = replaceTemplateJson(json, findBoardId!, '#TEMPLATE#');

    return jsonString;
  }

  void _collectChildBoardData(
      String parentItemId,
      List<Map<String, dynamic>> toJson,
      Set<String> processedChildBoards,
      Map<String, HierarchicalDockBoardController> hierarchicalControllers) {
    // 새로운 ID 시스템을 위한 부모 정보 조회
    final parentInfo = CompactIdGenerator.getParentInfo(parentItemId);
    String? parentBoardId;
    if (parentInfo != null) {
      final parts = parentInfo.split(':');
      if (parts.isNotEmpty) {
        parentBoardId = parts[0];
      }
    }

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

  /// Delete all items - 새로운 ID 시스템만 사용
  Future<void> deleteAll() async {
    final findBoardId = homeRepo.selectedBoardId ?? homeRepo.currentTab;
    final currentBoardController =
        homeRepo.hierarchicalControllers[findBoardId];
    if (currentBoardController == null) {
      return;
    }
    final innerData = currentBoardController.innerData;
    if (innerData.isEmpty) {
      return;
    }

    final selectedData = currentBoardController.getSelectedData();

    String title = '';
    if (selectedData == null || selectedData.isEmpty) {
      title = '보드[$findBoardId]의 전체 위젯을';
    } else {
      title = '선택한 위젯을';
    }

    final bool? result = await _delDialog(title: title);

    if (result != true) {
      return;
    }

    if (selectedData == null || selectedData.isEmpty) {
      // 전체 삭제: 먼저 메인 보드의 아이템들을 삭제한 후 하위 컨트롤러 제거
      final itemsToRemove = List.from(currentBoardController.innerData);
      currentBoardController.clear();

      // 메인 보드 아이템 삭제 후 하위 컨트롤러 제거 (Layout/Frame만)
      for (var e in itemsToRemove) {
        if (isStackItemType(e, 'StackLayoutItem') ||
            isStackItemType(e, 'StackFrameItem')) {
          _removeChildControllers(e.id);
        }
      }
    } else {
      // 선택된 아이템만 삭제: 먼저 메인 보드에서 아이템 제거한 후 하위 컨트롤러 제거
      final selectedItemsToRemove =
          List.from(currentBoardController.innerDataSelected);

      for (var e in selectedItemsToRemove) {
        currentBoardController.removeById(e.id);
      }

      // 메인 보드 아이템 제거 후 하위 컨트롤러 제거 (Layout/Frame만)
      for (var e in selectedItemsToRemove) {
        if (isStackItemType(e, 'StackLayoutItem') ||
            isStackItemType(e, 'StackFrameItem')) {
          _removeChildControllers(e.id);
        }
      }
    }

    // UI 상태 강제 업데이트
    homeRepo.addTopMenuState({'removed': true});
    // 선택 상태 초기화
    currentBoardController.unSelectAll();
  }

  /// 새로운 ID 시스템과 구식 Frame_id_tabIndex 규칙을 모두 지원하는 하위 컨트롤러 제거 메서드
  void _removeChildControllers(String itemId) {
    final controllersToRemove = <String>[];

    // 새로운 ID 시스템을 통한 하위 보드 찾기
    for (var entry in homeRepo.hierarchicalControllers.entries) {
      final boardId = entry.key;
      final controller = entry.value;

      // 새로운 ID 시스템: 부모 정보를 통해 하위 보드 확인
      final childParentInfo = CompactIdGenerator.getParentInfo(boardId);
      if (childParentInfo != null) {
        final parts = childParentInfo.split(':');
        if (parts.isNotEmpty) {
          final childParentId = parts[0];
          if (childParentId == itemId) {
            controllersToRemove.add(boardId);
          }
        }
      }

      // 구식 Frame_id_tabIndex 패턴도 지원 (하위 호환성)
      if (boardId.startsWith('Frame_')) {
        final parts = boardId.split('_');
        if (parts.length >= 3) {
          // Frame_id 부분 추출 (마지막 tabIndex 제외)
          final frameId = parts.sublist(0, parts.length - 1).join('_');
          if (frameId == itemId) {
            controllersToRemove.add(boardId);
          }
        }
      }
    }

    // 컨트롤러 제거
    for (final boardId in controllersToRemove) {
      final controller = homeRepo.hierarchicalControllers[boardId];
      if (controller != null) {
        try {
          controller.dispose();
          homeRepo.hierarchicalControllers.remove(boardId);
        } catch (e) {
          // 이미 dispose된 컨트롤러인 경우 무시
          homeRepo.hierarchicalControllers.remove(boardId);
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

  Future<bool?> _delDialog({String? title}) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) {
        return Center(
          child: SizedBox(
            width: 300,
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('$title \n 삭제 합니까 ?'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            icon: const Icon(Icons.check)),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            icon: const Icon(Icons.clear)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
