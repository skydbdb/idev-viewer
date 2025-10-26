import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/board/helpers/compact_id_generator.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/board/core/json_generator.dart';

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

    return await BoardJsonGenerator.generateJson(
      boardId: findBoardId!,
      selectedData: selectedData,
      hierarchicalControllers: homeRepo.hierarchicalControllers,
      templateId: '#TEMPLATE#',
    );
  }

  /// 템플릿 JSON에서 특정 문자열을 대체하는 함수
  static String replaceTemplateJson(
      String jsonString, String findStr, String replStr) {
    return BoardJsonGenerator.replaceTemplateJson(jsonString, findStr, replStr);
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
