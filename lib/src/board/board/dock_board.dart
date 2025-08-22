import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repo/home_repo.dart';
import '../flutter_stack_board.dart';
import '../stack_board_item.dart';
import '../stack_case.dart';
import '../stack_items.dart';
import 'hierarchical_dock_board_controller.dart';

// ignore: must_be_immutable
class DockBoard extends StatefulWidget {
  DockBoard({
    super.key,
    required this.id,
    this.parentId,
    this.focusNode,
  });

  String id;
  String? parentId;
  FocusNode? focusNode;

  @override
  State<DockBoard> createState() => _DockBoardState();
}

class _DockBoardState extends State<DockBoard> {
  late HomeRepo homeRepo;
  late HierarchicalDockBoardController hierarchicalController;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();

    // 컨트롤러 생성 또는 재사용
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
    } else {
      hierarchicalController = HierarchicalDockBoardController(
        id: widget.id,
        parentId: null,
        controller: StackBoardController(boardId: widget.id),
      );
      homeRepo.hierarchicalControllers[widget.id] = hierarchicalController;
    }
    _initializeHierarchicalController();
  }

  void _initializeHierarchicalController() {
    // 중복 생성 방지
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
      return;
    }

    // 새로운 계층 구조 관리 메서드 사용
    final success = homeRepo.createHierarchicalController(
      widget.id,
      widget.parentId,
    );
    if (success) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
    } else {
      // 실패 시 기본 컨트롤러 생성 (호환성 유지)
      hierarchicalController = HierarchicalDockBoardController(
        id: widget.id,
        parentId: widget.parentId,
        controller: StackBoardController(
          boardId: widget.id,
        ),
      );
      homeRepo.hierarchicalControllers[widget.id] = hierarchicalController;
    }
  }

  @override
  void dispose() {
    // 컨트롤러가 존재하는 경우에만 dispose
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      homeRepo.disposeHierarchicalController(widget.id);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 컨트롤러가 유효한지 확인
    try {
      // 컨트롤러의 상태를 확인하기 위해 간단한 접근 시도
      final _ = hierarchicalController.controller.innerData;
    } catch (e) {
      return const Center(child: CircularProgressIndicator());
    }

    return Theme(
      data: ThemeData.light(),
      child: StackBoard(
        id: widget.id,
        controller: hierarchicalController.controller,
        caseStyle: const CaseStyle(
          buttonBorderColor: Colors.grey,
          buttonIconColor: Colors.grey,
        ),
        background: ColoredBox(
          key: ValueKey(ThemeData.light().dialogBackgroundColor),
          color: ThemeData.light().colorScheme.surface,
        ),
        customBuilder: (StackItem<StackItemContent> item) {
          if (item is StackTextItem) {
            return StackTextCase(item: item);
          } else if (item is StackImageItem) {
            return StackImageCase(item: item);
          } else if (item is StackSearchItem) {
            return StackSearchCase(
              item: item,
            );
          } else if (item is StackButtonItem) {
            return StackButtonCase(item: item);
          } else if (item is StackDetailItem) {
            return StackDetailCase(
              item: item,
            );
          } else if (item is StackChartItem) {
            return StackChartCase(item: item);
          } else if (item is StackGridItem) {
            return StackGridCase(item: item);
          } else if (item is StackFrameItem) {
            return StackFrameCase(item: item);
          } else if (item is StackTemplateItem) {
            return StackTemplateCase(item: item);
          } else if (item is StackLayoutItem) {
            return StackLayoutCase(item: item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
