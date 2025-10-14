import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/stack_item_case/config_builder.dart';
import '/src/di/service_locator.dart';
import '/src/repo/home_repo.dart';
import '/src/repo/app_streams.dart';
import '/src/board/stack_item_case/stack_item_case.dart';
import '/src/board/widgets/ex_builder.dart';

import '/src/board/core/case_style.dart';
import '/src/board/core/stack_board_controller.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/core/alignment_guide_painter.dart';

class StackBoardConfig extends InheritedWidget {
  const StackBoardConfig({
    super.key,
    required this.controller,
    this.caseStyle,
    required super.child,
  });

  final StackBoardController controller;
  final CaseStyle? caseStyle;

  static StackBoardConfig of(BuildContext context) {
    final StackBoardConfig? result =
        context.dependOnInheritedWidgetOfExactType<StackBoardConfig>();
    assert(result != null, 'No StackBoardConfig found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant StackBoardConfig oldWidget) =>
      oldWidget.controller != controller || oldWidget.caseStyle != caseStyle;
}

class StackBoard extends StatefulWidget {
  const StackBoard({
    super.key,
    required this.id,
    required this.controller,
    this.background,
    this.caseStyle,
    this.customBuilder,
    this.onMenu,
    this.onDock,
    this.onDel,
    this.onTap,
    this.onSizeChanged,
    this.onOffsetChanged,
    this.onAngleChanged,
    this.onStatusChanged,
    this.actionsBuilder,
    this.borderBuilder,
  });

  final String id;
  final StackBoardController controller;
  final Widget? background;
  final CaseStyle? caseStyle;

  final Widget? Function(StackItem<StackItemContent> item)? customBuilder;
  final void Function(String menu)? onMenu;
  final void Function(StackItem<StackItemContent> item)? onDock;
  final void Function(StackItem<StackItemContent> item)? onDel;
  final void Function(StackItem<StackItemContent> item)? onTap;
  final bool? Function(StackItem<StackItemContent> item, Size size)?
      onSizeChanged;

  final bool? Function(StackItem<StackItemContent> item, Offset offset)?
      onOffsetChanged;

  final bool? Function(StackItem<StackItemContent> item, double angle)?
      onAngleChanged;

  final bool? Function(
          StackItem<StackItemContent> item, StackItemStatus operatState)?
      onStatusChanged;

  final Widget Function(StackItemStatus operatState, CaseStyle caseStyle)?
      actionsBuilder;

  final Widget Function(StackItemStatus operatState)? borderBuilder;

  @override
  State<StackBoard> createState() => _StackBoardState();
}

class _StackBoardState extends State<StackBoard> {
  double startX = 0, startY = 0, endX = 0, endY = 0;
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late final StreamSubscription _selectRectSub;

  // 선택된 아이템들의 초기 위치를 저장하기 위한 맵
  Map<String, Offset> selectedItemsInitialOffsets = {};
  // 드래그 시작 위치 저장
  Offset? dragStartPosition;

  StackBoardController get _controller => widget.controller;

  // IDE/편집 모드 여부를 확인하는 getter
  bool get _isEditMode {
    // 미리보기 보드(template_viewer)에서는 항상 편집 모드 비활성화
    if (widget.id == 'template_viewer') {
      return false;
    }
    // FLUTTER_EDIT_MODE 환경변수를 확인
    const editModeEnv = String.fromEnvironment('FLUTTER_EDIT_MODE');
    if (editModeEnv.isNotEmpty) {
      return editModeEnv.toLowerCase() == 'true';
    }

    // 환경변수가 없으면 기본 로직 사용 (디버그 모드이면서 웹이 아닌 경우)
    return kDebugMode && !kIsWeb;
  }

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    initStateSettings();
    _subscribeStreams();
  }

  void initStateSettings() {
    // homeRepo = context.read<HomeRepo>(); // initState에서 이미 초기화됨
  }

  void _subscribeStreams() {
    _subscribeSelectRect();
  }

  void _subscribeSelectRect() {
    _selectRectSub = appStreams.selectRectStream.listen((rect) {
      if (rect != null) {
        _handleSelectRect(rect);
      }
    });
  }

  void _handleSelectRect((double, double, double, double) rect) {
    final (left, top, width, height) = rect;
    final x1 = left, x2 = left + width, y1 = top, y2 = top + height;

    final items = _controller.innerData
        .where((e) => e.boardId == homeRepo.selectedBoardId)
        .toList();

    for (var e in items) {
      // locked 상태인 아이템은 선택하지 않음
      if (e.status == StackItemStatus.locked) {
        continue;
      }

      // left-top 기준으로 충돌 판정
      final eX1 = e.offset.dx;
      final eX2 = e.offset.dx + e.size.width;
      final eY1 = e.offset.dy;
      final eY2 = e.offset.dy + e.size.height;

      if (x1 < eX2 && x2 > eX1 && y1 < eY2 && y2 > eY1) {
        _controller.updateBasic(e.id, status: StackItemStatus.selected);
        if (_controller.innerDataSelected.length == 1) {
          homeRepo.addOnTapState(_controller.innerDataSelected.first);
        }
      }
    }
  }

  @override
  void dispose() {
    _selectRectSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StackBoardConfig(
      controller: _controller,
      caseStyle: widget.caseStyle,
      child: GestureDetector(
        onTap: () {
          _controller.unSelectAll();
          homeRepo.selectDockBoardState(widget.id);
        },
        behavior: HitTestBehavior.opaque,
        onPanStart: (DragStartDetails dud) {
          _onPanStart(dud);
        },
        onPanUpdate: (DragUpdateDetails dud) {
          _onPanUpdate(dud);
        },
        onPanEnd: (DragEndDetails dud) {
          _onPanEnd(dud);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 편집 모드일 때는 항상 원본 스택 레이아웃 사용
            if (_isEditMode) {
              return _buildOriginalStackLayout();
            }

            // 런타임 모드에서만 반응형 레이아웃 체크
            final shouldUseWrap = _shouldUseWrapLayout(constraints.maxWidth);
            return shouldUseWrap
                ? _buildWrapLayout(constraints)
                : _buildOriginalStackLayout();
          },
        ),
      ),
    );
  }

  // Wrap 레이아웃 사용 여부 결정
  bool _shouldUseWrapLayout(double availableWidth) {
    try {
      final items = _controller.innerData;
      if (items.isEmpty) return false;

      // 아이템들의 최대 X값 계산 (offset.x + width)
      double maxItemX = 0;

      for (var item in items) {
        final itemMaxX = item.offset.dx + item.size.width;
        maxItemX = maxItemX > itemMaxX ? maxItemX : itemMaxX;
      }

      // Wrap 모드 전환 조건:
      // 가장 큰 아이템의 최대 X값이 사용 가능한 너비를 초과하는 경우
      return maxItemX > availableWidth;
    } catch (e) {
      return false;
    }
  }

  // Wrap 레이아웃 빌드
  Widget _buildWrapLayout(BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 배경을 Stack의 첫 번째 자식으로 배치
        if (widget.background != null) widget.background!,
        // Wrap 레이아웃을 배경 위에 배치
        SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: _controller.innerData.map((item) {
              return SizedBox(
                width: item.size.width,
                height: item.size.height,
                child: _itemBuilder(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 기존 Stack 레이아웃 빌드 (원래 코드 그대로 유지)
  Widget _buildOriginalStackLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExBuilder<StackConfig>(
          valueListenable: _controller,
          shouldRebuild: (StackConfig p, StackConfig n) =>
              p.indexMap != n.indexMap || p.data.asMap() != n.data.asMap(),
          builder: (StackConfig sc) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const SizedBox.expand(),
                if (widget.background != null) widget.background!,
                ...sc.data.map((item) => _itemBuilder(item)),
                ..._controller.currentGuides.map((g) => Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: AlignmentGuidePainter(guide: g),
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
        if ((endX - startX).abs() > 0 &&
            widget.id == context.read<HomeRepo>().selectedBoardId)
          Positioned(
            left: startX < endX ? startX : endX,
            top: startY < endY ? startY : endY,
            child: Container(
              width: (endX - startX).abs(),
              height: (endY - startY).abs(),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                  width: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onPanStart(DragStartDetails dud) {
    // 드래그 시작 시 선택된 아이템들의 초기 위치 저장
    if (_controller.innerDataSelected.isNotEmpty) {
      selectedItemsInitialOffsets = {
        for (var item in _controller.innerDataSelected) item.id: item.offset
      };
      dragStartPosition = dud.globalPosition;
    }
    endX = startX = dud.localPosition.dx;
    endY = startY = dud.localPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails dud) {
    if (widget.id == context.read<HomeRepo>().selectedBoardId) {
      if (_controller.innerDataSelected.isNotEmpty &&
          dragStartPosition != null) {
        // 선택된 모든 아이템 이동 - 전체 드래그 거리 계산
        final totalDelta = dud.globalPosition - dragStartPosition!;
        for (var item in _controller.innerDataSelected) {
          final initialOffset = selectedItemsInitialOffsets[item.id];
          if (initialOffset != null) {
            final newOffset = initialOffset + totalDelta;
            _controller.updateBasic(item.id, offset: newOffset);
          }
        }
      } else {
        setState(() {
          endX += dud.delta.dx;
          endY += dud.delta.dy;
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails dud) {
    if (widget.id == context.read<HomeRepo>().selectedBoardId) {
      if (_controller.innerDataSelected.isNotEmpty) {
        // 선택된 모든 아이템의 최종 위치 정렬 (5픽셀 단위로)
        for (var item in _controller.innerDataSelected) {
          final currentOffset = _controller.getById(item.id)?.offset;
          if (currentOffset != null) {
            final alignedOffset = Offset(
              (currentOffset.dx ~/ 5 * 5).roundToDouble(),
              (currentOffset.dy ~/ 5 * 5).roundToDouble(),
            );
            _controller.updateBasic(item.id, offset: alignedOffset);
          }
        }
        // 초기 위치 맵과 드래그 시작 위치 초기화
        selectedItemsInitialOffsets.clear();
        dragStartPosition = null;
      } else {
        final rect = (
          startX < endX ? startX : endX, //left
          startY < endY ? startY : endY, //top
          (endX - startX).abs(), //width
          (endY - startY).abs(), //height
        );
        context.read<HomeRepo>().selectRectState(rect);
      }
      setState(() {
        startX = endX = 0;
      });
    }
  }

  Widget _itemBuilder(StackItem<StackItemContent> item) {
    final content = StackItemCase(
      stackItem: item,
      childBuilder: widget.customBuilder,
      // caseStyle: widget.caseStyle,
      // onMenu: (v) => widget.onMenu?.call(v),
      // onDock: () => widget.onDock?.call(item),
      // onDel: () => widget.onDel?.call(item),
      // onTap: () => widget.onTap?.call(item),
      // onSizeChanged: (Size size) =>
      //     widget.onSizeChanged?.call(item, size) ?? true,
      // onOffsetChanged: (Offset offset) =>
      //     widget.onOffsetChanged?.call(item, offset) ?? true,
      // onAngleChanged: (double angle) =>
      //     widget.onAngleChanged?.call(item, angle) ?? true,
      // onStatusChanged: (StackItemStatus operatState) =>
      //     widget.onStatusChanged?.call(item, operatState) ?? true,
      // actionsBuilder: widget.actionsBuilder,
      // borderBuilder: widget.borderBuilder,
    );

    if (item.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(item.borderRadius),
        child: content,
      );
    }
    return content;
  }
}
