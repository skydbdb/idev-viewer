import 'dart:convert';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/board/dock_board/board_menu.dart';
import 'package:idev_v1/src/board/board/hierarchical_dock_board_controller.dart';
import 'package:idev_v1/src/board/core/case_style.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_content.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_v1/src/board/stack_items.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/board/core/stack_board_controller.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import 'package:idev_v1/src/repo/app_streams.dart';
import 'package:idev_v1/src/board/board/stack_board.dart';
import 'package:idev_v1/src/board/stack_case.dart';
import '../../helpers/compact_id_generator.dart';

class StackTemplateCase extends StatefulWidget {
  const StackTemplateCase({
    super.key,
    required this.item,
  });

  /// StackTemplateItem
  final StackTemplateItem item;

  @override
  State<StackTemplateCase> createState() => _StackTemplateCaseState();
}

class _StackTemplateCaseState extends State<StackTemplateCase> {
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late StackBoardController stackBoardController;
  late final StreamSubscription _jsonMenuSub;

  // 크기 조정 옵션 상태
  String _sizeOption = 'Scroll';
  Size? _contentSize; // StackBoard 내부 콘텐츠의 실제 크기
  ValueKey? renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    final content = widget.item.content!;

    // content에서 sizeOption이 있으면 사용, 없으면 기본값 사용
    _sizeOption = content.sizeOption ?? 'Scroll';

    final stackController = StackBoardController();
    final HierarchicalDockBoardController hierarchicalController =
        HierarchicalDockBoardController(
      id: widget.item.id,
      parentId: null,
      controller: stackController,
    );
    homeRepo.hierarchicalControllers[widget.item.id] = hierarchicalController;
    stackBoardController = hierarchicalController.controller;

    if (content.script != null && content.script.toString().isNotEmpty) {
      generateFromJson(json: content.script);
    }
    _subscribeJsonMenu();
  }

  /// StackBoard 내부 콘텐츠의 실제 크기 계산
  Size _calculateContentSize() {
    if (stackBoardController.innerData.isEmpty) {
      return widget.item.size;
    }

    double maxX = 0;
    double maxY = 0;

    for (final item in stackBoardController.innerData) {
      final itemRight = item.offset.dx + item.size.width;
      final itemBottom = item.offset.dy + item.size.height;

      maxX = maxX < itemRight ? itemRight : maxX;
      maxY = maxY < itemBottom ? itemBottom : maxY;
    }

    return Size(maxX, maxY);
  }

  // JSON 메뉴 스트림 구독
  void _subscribeJsonMenu() {
    _jsonMenuSub = appStreams.jsonMenuStream.listen((v) async {
      if (v != null) {
        debugPrint('🔘 [StackTemplateCase] _subscribeJsonMenu: $v');
        stackBoardController.innerData.clear();
        await generateFromJson(json: v['script']).then((value) {
          setState(() {
            renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
          });
        });
      }
    });
  }

  /// Generate From Json
  Future<void> generateFromJson({String? json}) async {
    String jsonString =
        BoardMenu.replaceTemplateJson(json ?? '', '#TEMPLATE#', widget.item.id);

    try {
      // 1) first step: generate to boardId==new_1
      final List<dynamic> items = jsonDecode(jsonString) as List<dynamic>;

      List<dynamic> baseItems =
          items.where((e) => e['boardId'] == '#TEMPLATE#').toList();
      await generateItems(baseItems, mainBoardId: widget.item.id);

      // 2) second step: generate to other
      List<dynamic> childItems =
          items.where((e) => e['boardId'] != '#TEMPLATE#').toList();
      await generateItems(childItems);
    } catch (e) {
      debugPrint('🔘 [StackTemplateCase] generateFromJson: error: $e');
    }
  }

  String generateItemId(String itemType) {
    return CompactIdGenerator.generateItemId(itemType);
  }

  Future<void> generateItems(List<dynamic> items, {String? mainBoardId}) async {
    for (final dynamic item in items) {
      final boardId = mainBoardId ?? item['boardId'];
      final itemType = item['type'] ?? '';

      HierarchicalDockBoardController? hierarchicalController =
          homeRepo.hierarchicalControllers[boardId];

      if (hierarchicalController == null) {
        final stackController = StackBoardController();
        hierarchicalController = HierarchicalDockBoardController(
          id: boardId,
          parentId: null,
          controller: stackController,
        );
        homeRepo.hierarchicalControllers[boardId] = hierarchicalController;
      }

      final existingItem = hierarchicalController.controller.innerData
          .firstWhereOrNull((e) => e.id == item['id']);
      final itemId =
          existingItem == null ? item['id'] : generateItemId(item['type']);

      try {
        // 각 아이템을 locked 상태로 생성 (이동/크기 조정 불가)
        if (itemType == 'StackTextItem') {
          final textItem = StackTextItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked, // 잠금 상태로 설정
            lockZOrder: true, // Z 순서 잠금
          );
          hierarchicalController.controller.addItem(textItem);
        } else if (itemType == 'StackImageItem') {
          final imageItem = StackImageItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(imageItem);
        } else if (itemType == 'StackSearchItem') {
          final searchItem = StackSearchItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(searchItem);
        } else if (itemType == 'StackGridItem') {
          final gridItem = StackGridItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(gridItem);
        } else if (itemType == 'StackFrameItem') {
          final frameItem = StackFrameItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(frameItem);
        } else if (itemType == 'StackLayoutItem') {
          final layoutItem = StackLayoutItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(layoutItem);
        } else if (itemType == 'StackButtonItem') {
          final buttonItem = StackButtonItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(buttonItem);
        } else if (itemType == 'StackDetailItem') {
          final detailItem = StackDetailItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(detailItem);
        } else if (itemType == 'StackChartItem') {
          final chartItem = StackChartItem.fromJson(item).copyWith(
            boardId: boardId,
            id: itemId,
            status: StackItemStatus.locked,
            lockZOrder: true,
          );
          hierarchicalController.controller.addItem(chartItem);
        }
      } catch (e) {
        // 에러 처리
      }
    }
  }

  @override
  void dispose() {
    _jsonMenuSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 콘텐츠 크기 계산
    _contentSize = _calculateContentSize();

    final effectiveSize =
        _sizeOption == 'Fit' ? _contentSize! : widget.item.size;

    Widget stackBoardWidget = StackBoard(
      id: widget.item.id,
      controller: stackBoardController,
      caseStyle: const CaseStyle(
        buttonBorderColor: Colors.transparent, // 편집 버튼 숨김
        buttonIconColor: Colors.transparent,
      ),
      background: ColoredBox(
        color: ThemeData.light().colorScheme.surface,
      ),
      customBuilder: (StackItem<StackItemContent> item) {
        if (item is StackTextItem) {
          return StackTextCase(item: item);
        } else if (item is StackImageItem) {
          return StackImageCase(item: item);
        } else if (item is StackSearchItem) {
          return StackSearchCase(item: item);
        } else if (item is StackButtonItem) {
          return StackButtonCase(item: item);
        } else if (item is StackDetailItem) {
          return StackDetailCase(item: item);
        } else if (item is StackChartItem) {
          return StackChartCase(item: item);
        } else if (item is StackGridItem) {
          return StackGridCase(item: item);
        } else if (item is StackFrameItem) {
          return StackFrameCase(item: item);
        } else if (item is StackLayoutItem) {
          return StackLayoutCase(item: item);
        }
        return const SizedBox.shrink();
      },
    );

    // 스크롤 옵션일 때만 SingleChildScrollView로 감싸기
    if (_sizeOption == 'Scroll') {
      stackBoardWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: SizedBox(
            width: _contentSize!.width,
            height: _contentSize!.height,
            child: stackBoardWidget,
          ),
        ),
      );
    }

    return Scaffold(
      key: renderKey,
      body: Column(
        children: [
          // StackBoard 영역
          Expanded(
            child: SizedBox(
              width: effectiveSize.width,
              height: effectiveSize.height,
              child: stackBoardWidget,
            ),
          ),
        ],
      ),
    );
  }
}
