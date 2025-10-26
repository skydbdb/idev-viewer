import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/board/hierarchical_dock_board_controller.dart';
import 'package:idev_viewer/src/internal/board/core/case_style.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_viewer/src/internal/board/stack_items.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_controller.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/board/board/stack_board.dart';
import 'package:idev_viewer/src/internal/board/stack_case.dart';
import 'package:idev_viewer/src/internal/board/core/item_generator.dart';

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
  AppStreams? appStreams;
  late StackBoardController stackBoardController;
  late HierarchicalDockBoardController hierarchicalController;
  late TemplateItemContent content;
  late final StreamSubscription _jsonMenuSub;
  late StreamSubscription _updateStackItemSub;

  // 크기 조정 옵션 상태
  String _sizeOption = 'Scroll';
  Size? _contentSize; // StackBoard 내부 콘텐츠의 실제 크기

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
    content = widget.item.content!;

    // content에서 sizeOption이 있으면 사용, 없으면 기본값 사용
    _sizeOption = content.sizeOption ?? 'Scroll';

    debugPrint(
        '[StackTemplateCase] initState 시작: ${widget.item.id}, boardId: ${widget.item.boardId}');
    initStateSettings();

    // 템플릿 모드에서는 모든 아이템을 locked 상태로 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockAllItems();
    });

    _subscribeStreams();
  }

  /// 모든 아이템을 locked 상태로 설정
  void _lockAllItems() {
    // 템플릿 상세 팝업에서는 현재 템플릿의 아이템들만 잠금
    if (widget.item.boardId == 'template_viewer') {
      debugPrint('[StackTemplateCase] 템플릿 상세 팝업에서 아이템 잠금: ${widget.item.id}');
      final items = stackBoardController.innerData.toList();
      for (final item in items) {
        if (item.status != StackItemStatus.locked) {
          stackBoardController.updateBasic(item.id,
              status: StackItemStatus.locked);
        }
      }
    } else {
      // 일반 템플릿 위젯에서는 선택된 보드의 아이템들만 잠금
      final items = stackBoardController.innerData
          .where((item) => item.boardId == homeRepo.selectedBoardId)
          .toList();
      for (final item in items) {
        if (item.status != StackItemStatus.locked) {
          stackBoardController.updateBasic(item.id,
              status: StackItemStatus.locked);
        }
      }
    }
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

  /// 크기 옵션 변경
  void _changeSizeOption(String option) {
    setState(() {
      _sizeOption = option;
      if (option == 'Fit') {
        final it = homeRepo
            .hierarchicalControllers[widget.item.boardId]?.controller
            .getById(widget.item.id);

        if (it != null) {
          _contentSize = _calculateContentSize();
          homeRepo.hierarchicalControllers[widget.item.boardId]?.controller
              .updateItem(it.copyWith(size: _contentSize, content: content));
        }
      }

      // content의 sizeOption도 업데이트
      content = content.copyWith(sizeOption: option);
    });
  }

  void initStateSettings() {
    final stackController = StackBoardController();
    hierarchicalController = HierarchicalDockBoardController(
      id: widget.item.id,
      parentId: null,
      controller: stackController,
    );
    homeRepo.hierarchicalControllers[widget.item.id] = hierarchicalController;

    stackBoardController = hierarchicalController.controller;

    if (content.script != null && content.script!.isNotEmpty) {
      debugPrint(
          '[StackTemplateCase] initStateSettings에서 직접 JSON 처리: ${widget.item.id}');
      generateFromJson(json: content.script);
    }
  }

  void _subscribeStreams() {
    _subscribeJsonMenu();
    _subscribeUpdateStackItem();
  }

  // 1) 스크립트로부터 위젯 생성 기능 - JSON 메뉴 스트림 구독
  void _subscribeJsonMenu() {
    _jsonMenuSub = homeRepo.jsonMenuStream.listen((v) async {
      if (v != null) {
        try {
          debugPrint(
              '[StackTemplateCase] 템플릿 위젯에서 JSON 스크립트 수신: ${widget.item.id}');

          // 템플릿 상세 팝업인지 확인 (template_viewer 보드)
          bool isTemplateViewer = widget.item.boardId == 'template_viewer';

          if (isTemplateViewer) {
            debugPrint('[StackTemplateCase] 템플릿 상세 팝업에서 처리: ${widget.item.id}');
            // 템플릿 상세 팝업에서는 모든 조건을 건너뛰고 바로 처리
          } else {
            // 일반 템플릿 위젯에서의 분기 로직
            // 템플릿 위젯이 실제로 선택된 상태인지 확인
            if (widget.item.status != StackItemStatus.selected) {
              debugPrint(
                  '[StackTemplateCase] 템플릿 위젯이 선택되지 않아 처리 건너뜀: ${widget.item.id}');
              return;
            }

            // 현재 보드가 선택된 보드인지 확인
            if (homeRepo.selectedBoardId != widget.item.boardId) {
              debugPrint(
                  '[StackTemplateCase] 현재 보드가 아니어서 처리 건너뜀: ${widget.item.boardId} vs ${homeRepo.selectedBoardId}');
              return;
            }

            // 템플릿 ID 매칭 확인 (가장 중요한 분기 조건)
            final templateId = v['templateId'];
            if (templateId != null && widget.item.content?.templateId != null) {
              if (templateId.toString() !=
                  widget.item.content!.templateId.toString()) {
                debugPrint(
                    '[StackTemplateCase] 템플릿 ID가 일치하지 않아 처리 건너뜀: $templateId vs ${widget.item.content!.templateId}');
                return;
              }
            }
            // 템플릿 위젯이 선택되어 있으면 templateId 조건을 우회하고 바로 처리
          }

          // JSON 스크립트 유효성 검사
          if (v['script'] == null || v['script'].toString().isEmpty) {
            debugPrint('[StackTemplateCase][_subscribeJsonMenu] 스크립트가 비어있습니다.');
            return;
          }

          await generateFromJson(json: v['script']).then((value) {
            try {
              StackTemplateItem? item = homeRepo
                  .hierarchicalControllers[widget.item.boardId]
                  ?.getById(widget.item.id) as StackTemplateItem?;

              if (item == null) {
                debugPrint(
                    '[StackTemplateCase][_subscribeJsonMenu] 아이템을 찾을 수 없습니다: ${widget.item.id}');
                return;
              }

              final it = item.copyWith(
                content: item.content?.copyWith(
                    templateId: v['templateId'],
                    templateNm: v['templateNm'],
                    versionId: v['versionId'],
                    script: v['script'],
                    commitInfo: v['commitInfo']),
              );

              homeRepo.hierarchicalControllers[widget.item.boardId]
                  ?.updateItem(it);
              homeRepo.addOnTapState(it);
              setState(() {
                content = it.content!;
              });

              homeRepo.addJsonMenuState(null);
            } catch (e) {
              debugPrint(
                  '[StackTemplateCase][_subscribeJsonMenu] 템플릿 생성 오류: $e');
            }
          });
        } catch (e) {
          debugPrint(
              '[StackTemplateCase][_subscribeJsonMenu] JSON 스트림 처리 오류: $e');
        }
      }
    });
  }

  void _subscribeUpdateStackItem() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _updateStackItemSub = appStreams!.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackTemplateItem &&
          v.boardId == widget.item.boardId) {
        final StackTemplateItem item = v;

        setState(() {
          content = item.content!;
          _changeSizeOption(content.sizeOption ?? 'Scroll');
        });
      }
    });
  }

  /// Generate From Json
  Future<void> generateFromJson({String? json}) async {
    if (json == null || json.isEmpty) {
      debugPrint('🔘 [StackTemplateCase] generateFromJson: JSON이 비어있습니다.');
      return;
    }

    try {
      await BoardItemGenerator.generateFromJson(
        json: json,
        boardId: widget.item.id,
        controller: hierarchicalController,
        hierarchicalControllers: homeRepo.hierarchicalControllers,
        lockItems: true, // 템플릿의 경우 항상 잠금
      );

      debugPrint(
          '✅ [StackTemplateCase] generateFromJson: 템플릿 위젯에서 성공적으로 아이템 생성 완료');
    } catch (e) {
      debugPrint('🔘 [StackTemplateCase] generateFromJson: error: $e');
      debugPrint('🔘 [StackTemplateCase] generateFromJson: 원본 JSON: $json');
    }
  }

  @override
  void dispose() {
    _jsonMenuSub.cancel();
    // 뷰어 모드에서는 구독이 없을 수 있음
    if (BuildMode.isEditor && appStreams != null) {
      _updateStackItemSub.cancel();
    }
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
      // 편집 기능 제외 - null로 설정
      onMenu: null,
      onDock: null,
      onDel: null,
      onTap: null, // 탭 이벤트도 비활성화
      onSizeChanged: null, // 크기 변경 비활성화
      onOffsetChanged: null, // 위치 변경 비활성화
      onAngleChanged: null, // 회전 비활성화
      onStatusChanged: null, // 상태 변경 비활성화
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
          return StackButtonCase(
            item: item,
            onItemUpdated: (updatedItem) {
              // 아이템 업데이트 처리
              debugPrint('📝 StackButtonCase 아이템 업데이트: ${updatedItem.id}');
              // 필요시 추가 처리 로직 구현
            },
          );
        } else if (item is StackDetailItem) {
          return StackDetailCase(item: item);
        } else if (item is StackChartItem) {
          return StackChartCase(item: item);
        } else if (item is StackSchedulerItem) {
          return StackSchedulerCase(item: item);
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
