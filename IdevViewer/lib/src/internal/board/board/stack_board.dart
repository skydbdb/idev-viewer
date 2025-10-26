import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/stack_item_case/config_builder.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/board/stack_item_case/stack_item_case.dart';
import 'package:idev_viewer/src/internal/board/widgets/ex_builder.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';

import 'package:idev_viewer/src/internal/board/core/case_style.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_controller.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_viewer/src/internal/board/core/alignment_guide_painter.dart';

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
  AppStreams? appStreams;
  StreamSubscription? _selectRectSub;

  // 선택된 아이템들의 초기 위치를 저장하기 위한 맵
  Map<String, Offset> selectedItemsInitialOffsets = {};
  // 드래그 시작 위치 저장
  Offset? dragStartPosition;

  StackBoardController get _controller => widget.controller;

  // IDE/편집 모드 여부를 확인하는 getter
  bool get _isEditMode {
    // 뷰어 모드이거나 미리보기 보드에서는 편집 모드 비활성화
    if (BuildMode.isViewer || widget.id == 'template_viewer') {
      return false;
    }

    // 에디터 모드에서는 편집 기능 활성화
    return BuildMode.isEditor;
  }

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
    initStateSettings();
    _subscribeStreams();
  }

  void initStateSettings() {
    // homeRepo = context.read<HomeRepo>(); // initState에서 이미 초기화됨
  }

  void _subscribeStreams() {
    // 뷰어 모드에서는 편집 관련 스트림 구독 생략
    if (BuildMode.isViewer) {
      return;
    }
    _subscribeSelectRect();
  }

  void _subscribeSelectRect() {
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }
    _selectRectSub = appStreams!.selectRectStream.listen((rect) {
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
    _selectRectSub?.cancel();
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
              return _buildOriginalStackLayout(constraints);
            }

            // 런타임 모드에서만 반응형 레이아웃 체크
            final shouldUseWrap = _shouldUseWrapLayout(constraints.maxWidth);

            return shouldUseWrap
                ? _buildWrapLayout(constraints)
                : _buildOriginalStackLayout(constraints);
          },
        ),
      ),
    );
  }

  // Wrap 레이아웃 사용 여부 결정
  bool _shouldUseWrapLayout(double availableWidth) {
    try {
      final items = _controller.innerData;

      if (items.isEmpty) {
        return false;
      }

      // 아이템들의 최대 X값 계산 (offset.x + width)
      double maxItemX = 0;

      for (var item in items) {
        final itemMaxX = item.offset.dx + item.size.width;
        maxItemX = maxItemX > itemMaxX ? maxItemX : itemMaxX;
      }

      // Wrap 모드 전환 조건:
      // 가장 큰 아이템의 최대 X값이 사용 가능한 너비를 초과하는 경우
      final shouldUseWrap = maxItemX > availableWidth;

      return shouldUseWrap;
    } catch (e) {
      return false;
    }
  }

  // Wrap 레이아웃 빌드 (실제 Wrap 위젯 사용)
  Widget _buildWrapLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _controller.value.data.map((item) {
          return StackItemCase(
            stackItem: item,
            childBuilder: widget.customBuilder ?? _defaultItemBuilder,
            caseStyle: widget.caseStyle,
            onMenu: (v) => widget.onMenu?.call(v),
            onDock: () => widget.onDock?.call(item),
            onDel: () => widget.onDel?.call(item),
            onTap: () => widget.onTap?.call(item),
            onSizeChanged: (Size size) =>
                widget.onSizeChanged?.call(item, size) ?? true,
            onOffsetChanged: (Offset offset) =>
                widget.onOffsetChanged?.call(item, offset) ?? true,
            onAngleChanged: (double angle) =>
                widget.onAngleChanged?.call(item, angle) ?? true,
            onStatusChanged: (StackItemStatus operatState) =>
                widget.onStatusChanged?.call(item, operatState) ?? true,
            actionsBuilder: widget.actionsBuilder,
            borderBuilder: widget.borderBuilder,
            layoutMode: StackItemLayoutMode.wrap, // Wrap 모드 사용
            // Wrap 모드에서는 뷰어 모드로 강제 전환하여 안정적인 렌더링 보장
            forceViewerMode: true,
          );
        }).toList(),
      ),
    );
  }

  // 기존 Stack 레이아웃 빌드 (원래 코드 그대로 유지)
  Widget _buildOriginalStackLayout(BoxConstraints constraints) {
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

  /// 기본 아이템 빌더 (customBuilder가 null일 때 사용)
  Widget? _defaultItemBuilder(StackItem<StackItemContent> item) {
    // 기본적으로는 null을 반환하여 StackItemCase의 _buildDefaultContent가 사용되도록 함
    return null;
  }

  Widget _itemBuilder(StackItem<StackItemContent> item) {
    try {
      return StackItemCase(
        stackItem: item,
        childBuilder: widget.customBuilder,
        caseStyle: widget.caseStyle,
        onMenu: (v) => widget.onMenu?.call(v),
        onDock: () => widget.onDock?.call(item),
        onDel: () => widget.onDel?.call(item),
        onTap: () => widget.onTap?.call(item),
        onSizeChanged: (Size size) =>
            widget.onSizeChanged?.call(item, size) ?? true,
        onOffsetChanged: (Offset offset) =>
            widget.onOffsetChanged?.call(item, offset) ?? true,
        onAngleChanged: (double angle) =>
            widget.onAngleChanged?.call(item, angle) ?? true,
        onStatusChanged: (StackItemStatus operatState) =>
            widget.onStatusChanged?.call(item, operatState) ?? true,
        actionsBuilder: widget.actionsBuilder,
        borderBuilder: widget.borderBuilder,
        layoutMode: StackItemLayoutMode.positioned, // 기본적으로 positioned 모드 사용
      );
    } catch (e) {
      rethrow;
    }
  }
}
