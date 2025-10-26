import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:idev_viewer/src/internal/board/stack_board_item.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/board/core/case_style.dart';
import 'package:idev_viewer/src/internal/board/board/stack_board.dart';
import 'package:idev_viewer/src/internal/board/stack_item_case/config_builder.dart';
import 'package:idev_viewer/src/internal/board/core/alignment_guide.dart';

/// StackItem의 레이아웃 모드를 정의하는 열거형
enum StackItemLayoutMode {
  /// Stack 내부에서 Positioned 위젯으로 사용
  positioned,

  /// Wrap 내부에서 Container로 래핑하여 사용
  wrap,

  /// Column 내부에서 SizedBox로 래핑하여 사용
  column,
}

/// * Operate box
/// * 1. Drag
/// * 2. Scale
/// * 3. Resize
/// * 4. Rotate
/// * 5. Select
/// * 6. Edit
/// * 7. Delete
class StackItemCase extends StatefulWidget {
  const StackItemCase({
    super.key,
    required this.stackItem,
    required this.childBuilder,
    this.caseStyle,
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
    this.layoutMode = StackItemLayoutMode.positioned,
  });

  /// * StackItemData
  final StackItem<StackItemContent> stackItem;

  /// * Child builder, update when item status changed
  final Widget? Function(StackItem<StackItemContent> item)? childBuilder;

  /// * Outer frame style
  final CaseStyle? caseStyle;

  /// * Menu intercept
  final void Function(String menu)? onMenu;

  /// * Dock intercept
  final void Function()? onDock;

  /// * Remove intercept
  final void Function()? onDel;

  /// * Click callback
  final void Function()? onTap;

  /// * Size change callback
  final bool? Function(Size size)? onSizeChanged;

  /// * Position change callback
  final bool? Function(Offset offset)? onOffsetChanged;

  /// * Angle change callback
  final bool? Function(double angle)? onAngleChanged;

  /// * Operation status callback
  final bool? Function(StackItemStatus operatState)? onStatusChanged;

  /// * Operation layer builder
  final Widget Function(StackItemStatus operatState, CaseStyle caseStyle)?
      actionsBuilder;

  /// * Border builder
  final Widget Function(StackItemStatus operatState)? borderBuilder;

  /// * Layout mode for different container types
  final StackItemLayoutMode layoutMode;

  @override
  State<StatefulWidget> createState() {
    return _StackItemCaseState();
  }
}

class _StackItemCaseState extends State<StackItemCase> {
  Offset startGlobalPoint = Offset.zero;
  Offset startOffset = Offset.zero;
  Size startSize = Size.zero;
  double startAngle = 0;
  Alignment? startAlignment; // 비사용 검토
  double endDx = 0, endDy = 0;
  Offset dragOffset = Offset.zero;
  int itemIndex = 0;
  late HomeRepo homeRepo;
  AppStreams? appStreams;
  StreamSubscription? _updateStackItemSub;

  String get itemId => widget.stackItem.id;

  StackBoardController _controller(BuildContext context) =>
      StackBoardConfig.of(context).controller;

  /// * Outer frame style
  CaseStyle _caseStyle(BuildContext context) =>
      widget.caseStyle ??
      StackBoardConfig.of(context).caseStyle ??
      const CaseStyle();

  double _minSize(BuildContext context) => _caseStyle(context).buttonSize * 2;

  @override
  void initState() {
    super.initState();
    initStateSettings();
    subscribeUpdateStackItem();
  }

  void initStateSettings() {
    homeRepo = context.read<HomeRepo>();
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
  }

  void subscribeUpdateStackItem() {
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }
    _updateStackItemSub = appStreams!.updateStackItemStream.listen((v) {
      if (v == null) {
        return;
      }
      _handleUpdateStackItem(v);
    });
  }

  void _handleUpdateStackItem(StackItem<StackItemContent>? item) {
    if (item == null) {
      return;
    }
    final StackBoardController stackController = _controller(context);
    // content가 변경된 경우, 먼저 content만 업데이트된 새로운 item으로 업데이트
    StackItem<StackItemContent> updatedItem = item;
    if (item.content != null) {
      updatedItem = item.copyWith(content: item.content);
    }
    stackController.updateItem(updatedItem);
  }

  @override
  void dispose() {
    _updateStackItemSub?.cancel();
    super.dispose();
  }

  /// * Main body mouse pointer style
  MouseCursor _cursor(StackItemStatus status) {
    // locked 상태에서는 기본 커서 사용
    if (status == StackItemStatus.locked) {
      return SystemMouseCursors.basic;
    }

    if (status == StackItemStatus.moving) {
      return SystemMouseCursors.grabbing;
    } else if (status == StackItemStatus.editing) {
      return SystemMouseCursors.click;
    }

    return SystemMouseCursors.grab;
  }

  /// * Click
  void _onTap(BuildContext context) {
    // locked 상태에서는 탭 이벤트 무시 (선택 방지)
    if (widget.stackItem.status == StackItemStatus.locked) {
      return;
    }

    widget.onTap?.call();
    _controller(context).selectOne(itemId);
    widget.onStatusChanged?.call(StackItemStatus.selected);
    homeRepo.addOnTapState(_controller(context).getById(itemId)!);
  }

  /// * Click edit
  void _onEdit(BuildContext context, StackItemStatus status) {
    // locked 상태에서는 편집 이벤트 무시
    if (widget.stackItem.status == StackItemStatus.locked) {
      return;
    }

    if (status == StackItemStatus.editing) return;

    final StackBoardController stackController = _controller(context);
    status = StackItemStatus.editing;
    stackController.selectOne(itemId);
    stackController.updateBasic(itemId, status: status);
    widget.onStatusChanged?.call(status);

    // Display property
    homeRepo.addOnTapState(_controller(context).getById(itemId)!);
  }

  void _onPanStart(DragStartDetails details, BuildContext context,
      StackItemStatus newStatus) {
    // locked 상태에서는 드래그 시작 무시
    if (widget.stackItem.status == StackItemStatus.locked) {
      return;
    }

    final StackBoardController stackController = _controller(context);
    final StackItem<StackItemContent>? item = stackController.getById(itemId);
    if (item == null) return;

    if (item.status != newStatus) {
      if (item.status == StackItemStatus.editing) return;
      if (item.status != StackItemStatus.selected) {
        stackController.selectOne(itemId);
      }
      stackController.updateBasic(itemId, status: newStatus);
      widget.onStatusChanged?.call(newStatus);
    }

    startGlobalPoint = details.globalPosition;
    startOffset = item.offset;
    startSize = item.size;
    startAngle = item.angle;
  }

  /// * Drag end
  void _onPanEnd(BuildContext context, StackItemStatus status) {
    // locked 상태에서는 드래그 종료 무시
    if (widget.stackItem.status == StackItemStatus.locked) {
      return;
    }

    // 드래그 종료 시 모든 가이드라인 제거
    _controller(context).clearCurrentGuides();

    if (status != StackItemStatus.selected) {
      if (status == StackItemStatus.editing) return;
      status = StackItemStatus.selected;

      final StackBoardController stackController = _controller(context);
      final StackItem<StackItemContent>? item = stackController.getById(itemId);

      if (item != null) {
        if (startAlignment != null) {
          // 리사이즈/스케일 후: 소수점 이하 제거하여 최종 업데이트
          final Size roundedSize = Size(
            item.size.width.roundToDouble(),
            item.size.height.roundToDouble(),
          );
          final Offset roundedOffset = Offset(
            item.offset.dx.roundToDouble(),
            item.offset.dy.roundToDouble(),
          );

          stackController.updateBasic(itemId,
              size: roundedSize, offset: roundedOffset, status: status);
        } else {
          // 이동(드래그) 후: 소수점 이하 제거하여 정렬된 위치로 업데이트
          Offset o = Offset(
            (dragOffset.dx ~/ 5 * 5).roundToDouble(),
            (dragOffset.dy ~/ 5 * 5).roundToDouble(),
          );
          stackController.updateBasic(itemId, offset: o, status: status);
        }
        homeRepo.addOnTapState(stackController.getById(itemId));
      }
    }
    startAlignment = null;
  }

  void _onPanUpdate(DragUpdateDetails dud, BuildContext context) {
    final stackController = _controller(context);
    final item = stackController.getById(itemId);
    if (item == null || item.status == StackItemStatus.editing) return;
    final Offset newTopLeft = item.offset + dud.delta;
    final tempItem = item.copyWith(offset: newTopLeft);
    final guides = stackController.detectAlignments(tempItem);
    stackController.setCurrentGuides(guides);
    Offset aligned = newTopLeft;
    for (final guide in guides) {
      switch (guide.type) {
        case AlignmentType.verticalCenter:
          aligned = Offset(guide.position - item.size.width / 2, aligned.dy);
          break;
        case AlignmentType.horizontalCenter:
          aligned = Offset(aligned.dx, guide.position - item.size.height / 2);
          break;
        case AlignmentType.leftEdge:
          aligned = Offset(guide.position, aligned.dy);
          break;
        case AlignmentType.rightEdge:
          aligned = Offset(guide.position - item.size.width, aligned.dy);
          break;
        case AlignmentType.topEdge:
          aligned = Offset(aligned.dx, guide.position);
          break;
        case AlignmentType.bottomEdge:
          aligned = Offset(aligned.dx, guide.position - item.size.height);
          break;
      }
    }
    stackController.updateBasic(itemId, offset: aligned);
    widget.onOffsetChanged?.call(newTopLeft);
    homeRepo.addOnTapState(stackController.getById(itemId)!);
  }

  /// * Scale operation
  void _onScaleUpdate(DragUpdateDetails dud, BuildContext context,
      StackItemStatus status, Alignment alignment) {
    double deltaX = dud.globalPosition.dx - startGlobalPoint.dx;
    double deltaY = dud.globalPosition.dy - startGlobalPoint.dy;
    Size newSize = startSize;
    Offset newOffset = startOffset;
    switch (alignment) {
      case Alignment.topLeft:
        newSize = Size(
            (startSize.width - deltaX)
                .clamp(_minSize(context), double.infinity),
            (startSize.height - deltaY)
                .clamp(_minSize(context), double.infinity));
        newOffset = Offset(startOffset.dx + deltaX, startOffset.dy + deltaY);
        break;
      case Alignment.topRight:
        newSize = Size(
            (startSize.width + deltaX)
                .clamp(_minSize(context), double.infinity),
            (startSize.height - deltaY)
                .clamp(_minSize(context), double.infinity));
        newOffset = Offset(startOffset.dx, startOffset.dy + deltaY);
        break;
      case Alignment.bottomLeft:
        newSize = Size(
            (startSize.width - deltaX)
                .clamp(_minSize(context), double.infinity),
            (startSize.height + deltaY)
                .clamp(_minSize(context), double.infinity));
        newOffset = Offset(startOffset.dx + deltaX, startOffset.dy);
        break;
      case Alignment.bottomRight:
        newSize = Size(
            (startSize.width + deltaX)
                .clamp(_minSize(context), double.infinity),
            (startSize.height + deltaY)
                .clamp(_minSize(context), double.infinity));
        newOffset = startOffset;
        break;
      default:
        break;
    }
    if (!(widget.onSizeChanged?.call(newSize) ?? true)) return;
    _controller(context).updateBasic(itemId, size: newSize, offset: newOffset);
    // widget.onSizeChanged?.call(newSize);
    homeRepo.addOnTapState(_controller(context).getById(itemId)!);
  }

  /// * Horizontal, Vertical resize operation
  void _onResizeXYUpdate(DragUpdateDetails dud, BuildContext context,
      StackItemStatus status, Alignment alignment) {
    double deltaX = dud.globalPosition.dx - startGlobalPoint.dx;
    double deltaY = dud.globalPosition.dy - startGlobalPoint.dy;
    Size newSize = startSize;
    Offset newOffset = startOffset;
    switch (alignment) {
      case Alignment.centerLeft:
        newSize = Size(
            (startSize.width - deltaX)
                .clamp(_minSize(context), double.infinity),
            startSize.height);
        newOffset = Offset(startOffset.dx + deltaX, startOffset.dy);
        break;
      case Alignment.centerRight:
        newSize = Size(
            (startSize.width + deltaX)
                .clamp(_minSize(context), double.infinity),
            startSize.height);
        newOffset = startOffset;
        break;
      case Alignment.topCenter:
        newSize = Size(
            startSize.width,
            (startSize.height - deltaY)
                .clamp(_minSize(context), double.infinity));
        newOffset = Offset(startOffset.dx, startOffset.dy + deltaY);
        break;
      case Alignment.bottomCenter:
        newSize = Size(
            startSize.width,
            (startSize.height + deltaY)
                .clamp(_minSize(context), double.infinity));
        newOffset = startOffset;
        break;
      default:
        break;
    }
    widget.onSizeChanged?.call(newSize);
    _controller(context).updateBasic(itemId, size: newSize, offset: newOffset);
    homeRepo.addOnTapState(_controller(context).getById(itemId)!);
  }

  /// * Rotate operation - 개선된 버전 (시계방향이 양수)
  void _onRotateUpdate(
      DragUpdateDetails dud, BuildContext context, StackItemStatus status) {
    final StackBoardController stackController = _controller(context);
    final StackItem<StackItemContent>? item = stackController.getById(itemId);
    if (item == null) return;
    if (item.status == StackItemStatus.editing) return;

    // 아이템의 중심점 계산
    final Size itemSize = item.size;
    final Offset itemCenter = Offset(itemSize.width / 2, itemSize.height / 2);

    // 아이템의 현재 위치
    final Offset itemPosition = item.offset;

    // 마우스 위치를 아이템 중심 기준으로 변환
    final Offset mousePosition = dud.globalPosition;
    final Offset relativeToCenter = mousePosition - itemPosition - itemCenter;

    // 이전 프레임의 마우스 위치
    final Offset previousMousePosition = mousePosition - dud.delta;
    final Offset previousRelativeToCenter =
        previousMousePosition - itemPosition - itemCenter;

    // 중심점에서의 각도 계산 (시계방향이 양수)
    final double currentAngle = atan2(relativeToCenter.dy, relativeToCenter.dx);
    final double previousAngle =
        atan2(previousRelativeToCenter.dy, previousRelativeToCenter.dx);

    // 각도 변화량 계산
    double angleDelta = currentAngle - previousAngle;

    // 각도 차이가 너무 크면 반대 방향으로 보정
    if (angleDelta > pi) {
      angleDelta -= 2 * pi;
    } else if (angleDelta < -pi) {
      angleDelta += 2 * pi;
    }

    final double newAngle = (item.angle + angleDelta);

    stackController.updateBasic(itemId, angle: newAngle);
    widget.onAngleChanged?.call(newAngle);
    homeRepo.addOnTapState(stackController.getById(itemId)!);
  }

  @override
  Widget build(BuildContext context) {
    // 레이아웃 모드에 따라 다른 렌더링 방식 사용
    switch (widget.layoutMode) {
      case StackItemLayoutMode.positioned:
        return _buildPositionedLayout(context);
      case StackItemLayoutMode.wrap:
        return _buildWrapLayout(context);
      case StackItemLayoutMode.column:
        return _buildColumnLayout(context);
    }
  }

  /// Stack 내부에서 Positioned 위젯으로 렌더링
  Widget _buildPositionedLayout(BuildContext context) {
    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        return p.offset != n.offset ||
            p.angle != n.angle ||
            p.size != n.size ||
            p.dock != n.dock ||
            p.padding != n.padding ||
            p.content != n.content ||
            p.status != n.status;
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        return item.dock
            ? Positioned.fill(
                child: Padding(
                    padding: item.padding,
                    child: widget.childBuilder?.call(item) ??
                        const SizedBox.shrink()),
              )
            : Positioned(
                key: ValueKey<String>(
                    '${item.id}${item.padding.hashCode}${item.dock}'),
                top: item.offset.dy,
                left: item.offset.dx,
                child: Transform.rotate(angle: item.angle, child: c),
              );
      },
      child: ConfigBuilder.withItem(
        itemId,
        shouldRebuild:
            (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
          // 뷰어 모드에서는 더 적극적으로 리빌드
          if (BuildMode.isViewer) {
            return p.size != n.size ||
                p.padding != n.padding ||
                p.status != n.status ||
                p.borderRadius != n.borderRadius ||
                p.content?.toJson().toString() !=
                    n.content?.toJson().toString() ||
                p.offset != n.offset ||
                p.angle != n.angle;
          }
          // 에디터 모드에서는 기존 로직 사용
          return p.status != n.status || p.content != n.content;
        },
        childBuilder: (StackItem<StackItemContent> item, Widget c) {
          if (item.status == StackItemStatus.locked) {
            // locked 상태일 때는 GestureDetector 없이 단순히 content만 반환
            return _content(context, item);
          }

          // 뷰어 모드에서는 편집 기능을 비활성화하고 content만 표시
          if (BuildMode.isViewer) {
            // 뷰어 모드에서 위젯 상태를 강제로 활성화
            final activeItem = item.copyWith(
              status: StackItemStatus.idle, // 강제로 idle 상태로 설정
            );

            return Container(
              // 뷰어 모드에서 렌더링 안정성을 위한 추가 설정
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: RepaintBoundary(
                child: Builder(
                  builder: (context) {
                    try {
                      return _content(context, activeItem);
                    } catch (e) {
                      // 뷰어 모드에서 content 렌더링 실패 시 안전한 fallback
                      return Container(
                        width: item.size.width,
                        height: item.size.height,
                        color: Colors.grey[100],
                        child: const Center(
                          child: Text('위젯 로드 실패'),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }

          return MouseRegion(
            cursor: _cursor(item.status),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // 여러 아이템이 선택된 경우 개별 드래그 비활성화
              onPanStart: _controller(context).innerDataSelected.length > 1
                  ? null
                  : (DragStartDetails details) =>
                      _onPanStart(details, context, StackItemStatus.moving),
              onPanUpdate: _controller(context).innerDataSelected.length > 1
                  ? null
                  : (DragUpdateDetails dud) => _onPanUpdate(dud, context),
              onPanEnd: _controller(context).innerDataSelected.length > 1
                  ? null
                  : (_) => _onPanEnd(context, item.status),
              onTap: () => _onTap(context),
              onDoubleTap: () => _onEdit(context, item.status),
              child: _childrenStack(context, item),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _childrenStack(
      BuildContext context, StackItem<StackItemContent> item) {
    final CaseStyle style = _caseStyle(context);
    final double borderWidth = style.frameBorderWidth;

    List<Widget> children = [
      // 1. content (실제 아이템 내용)
      _content(context, item),
      // 2. border (외곽선) - content와 정확히 겹치게 overlay
      if (item.status != StackItemStatus.idle)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.frameBorderColor,
                  width: borderWidth,
                ),
              ),
            ),
          ),
        ),
    ];

    // actions/handle 등 기존 분기 추가 (content 내부/모서리에 위치)
    if (widget.actionsBuilder != null) {
      children.add(widget.actionsBuilder!(item.status, _caseStyle(context)));
    } else if (item.status != StackItemStatus.editing) {
      if (item.status != StackItemStatus.idle) {
        final double handleOffset = -style.buttonSize / 2;
        // border
        children.add(Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.frameBorderColor,
                  width: borderWidth,
                ),
              ),
            ),
          ),
        ));
        // 핸들(모서리/변) - 외곽선에 걸쳐 보이도록 위치 조정
        // 오른쪽 하단
        children.add(Positioned(
          right: handleOffset,
          bottom: handleOffset,
          child: _scaleHandle(context, item.status,
              SystemMouseCursors.resizeUpLeftDownRight, Alignment.bottomRight),
        ));
        // 왼쪽 하단
        children.add(Positioned(
          left: handleOffset,
          bottom: handleOffset,
          child: _scaleHandle(context, item.status,
              SystemMouseCursors.resizeUpRightDownLeft, Alignment.bottomLeft),
        ));
        // 오른쪽 상단
        children.add(Positioned(
          right: handleOffset,
          top: handleOffset,
          child: _scaleHandle(context, item.status,
              SystemMouseCursors.resizeUpRightDownLeft, Alignment.topRight),
        ));
        // 왼쪽 상단
        children.add(Positioned(
          left: handleOffset,
          top: handleOffset,
          child: _scaleHandle(context, item.status,
              SystemMouseCursors.resizeUpLeftDownRight, Alignment.topLeft),
        ));
        // 상단 중앙
        children.add(Positioned(
          left: 0,
          top: handleOffset,
          right: 0,
          child: _resizeHandle(
              context,
              item.status,
              style.buttonSize,
              style.buttonSize / 3,
              SystemMouseCursors.resizeRow,
              Alignment.topCenter,
              _onResizeXYUpdate),
        ));
        // 하단 중앙
        children.add(Positioned(
          left: 0,
          bottom: handleOffset,
          right: 0,
          child: _resizeHandle(
              context,
              item.status,
              style.buttonSize,
              style.buttonSize / 3,
              SystemMouseCursors.resizeRow,
              Alignment.bottomCenter,
              _onResizeXYUpdate),
        ));
        // 좌측 중앙
        children.add(Positioned(
          bottom: style.buttonSize,
          left: handleOffset,
          top: style.buttonSize,
          child: _resizeHandle(
              context,
              item.status,
              style.buttonSize / 3,
              style.buttonSize,
              SystemMouseCursors.resizeColumn,
              Alignment.centerLeft,
              _onResizeXYUpdate),
        ));
        // 우측 중앙
        children.add(Positioned(
          bottom: style.buttonSize,
          right: handleOffset,
          top: style.buttonSize,
          child: _resizeHandle(
              context,
              item.status,
              style.buttonSize / 3,
              style.buttonSize,
              SystemMouseCursors.resizeColumn,
              Alignment.centerRight,
              _onResizeXYUpdate),
        ));
        // 회전
        children.addAll(<Widget>[
          if (item.status == StackItemStatus.editing)
            _deleteHandle(context)
          else
            _rotateAndMoveHandle(context, item.status, item),
        ]);
      }
    } else {
      if (convertType(item) == '상세') {
        children.add(_tableHandle(context, item));
      } else {
        children.add(_deleteHandle(context));
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }

  /// * Child component
  Widget _content(BuildContext context, StackItem<StackItemContent> item) {
    final Widget content = Padding(
        padding: item.padding,
        child: widget.childBuilder?.call(item) ?? const SizedBox.shrink());

    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        return p.size != n.size ||
            p.padding != n.padding ||
            p.status != n.status ||
            p.borderRadius != n.borderRadius ||
            p.content?.toJson().toString() != n.content?.toJson().toString();
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        return Padding(
            padding: EdgeInsets.zero, // status와 무관하게 항상 0
            child: ClipRRect(
              borderRadius: BorderRadius.circular(item.borderRadius),
              child: SizedBox.fromSize(size: item.size, child: c),
            ));
      },
      child: content,
    );
  }

  /// * Delete handle
  Widget _deleteHandle(BuildContext context) {
    final CaseStyle style = _caseStyle(context);

    return Positioned(
      left: 0,
      bottom: 0,
      right: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onDel?.call(),
          child: _toolCase(context, style, const Icon(Icons.delete)),
        ),
      ),
    );
  }

  /// * Table handle
  Widget _tableHandle(BuildContext context, StackItem<StackItemContent> item) {
    final CaseStyle style = _caseStyle(context);

    return Positioned(
      left: 0,
      bottom: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('merge'),
              child: _toolCase(context, style, const Icon(Symbols.cell_merge),
                  message: '셀 병합'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('cancelMerge'),
              child: _toolCase(context, style, const Icon(Icons.sync),
                  message: '셀 병합 취소'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('addColumnLeft'),
              child: _toolCase(
                  context, style, const Icon(Symbols.add_column_left),
                  message: '좌측 열 추가'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('addColumnRight'),
              child: _toolCase(
                  context, style, const Icon(Symbols.add_column_right),
                  message: '우측 열 추가'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('removeColumn'),
              child: _toolCase(context, style, const Icon(Symbols.remove_road),
                  message: '열 삭제'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('addRowAbove'),
              child: _toolCase(
                  context, style, const Icon(Symbols.add_row_above),
                  message: '위 행 추가'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('addRowBelow'),
              child: _toolCase(
                  context, style, const Icon(Symbols.add_row_below),
                  message: '아래 행 추가'),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onMenu?.call('removeRow'),
              child: _toolCase(
                  context, style, const Icon(Symbols.variable_remove),
                  message: '행 삭제'),
            ),
          ),
        ],
      ),
    );
  }

  /// * Scale handle
  Widget _scaleHandle(BuildContext context, StackItemStatus status,
      MouseCursor cursor, Alignment alignment) {
    final CaseStyle style = _caseStyle(context);
    startAlignment = alignment;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onPanStart: (DragStartDetails dud) =>
            _onPanStart(dud, context, StackItemStatus.scaling),
        onPanUpdate: (DragUpdateDetails dud) =>
            _onScaleUpdate(dud, context, status, alignment),
        onPanEnd: (_) => _onPanEnd(context, status),
        child: _toolCase(
          context,
          style,
          null,
        ),
      ),
    );
  }

  /// * Resize handle
  Widget _resizeHandle(
      BuildContext context,
      StackItemStatus status,
      double width,
      double height,
      MouseCursor cursor,
      Alignment alignment,
      Function(DragUpdateDetails, BuildContext, StackItemStatus, Alignment)
          onPanUpdate) {
    final CaseStyle style = _caseStyle(context);
    startAlignment = alignment;

    return Center(
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (DragStartDetails dud) =>
                _onPanStart(dud, context, StackItemStatus.resizing),
            onPanUpdate: (DragUpdateDetails dud) =>
                onPanUpdate(dud, context, status, alignment),
            onPanEnd: (_) => _onPanEnd(context, status),
            child: SizedBox(
                width: width * 3,
                height: height * 3,
                child: Center(
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: style.buttonBgColor,
                      border: Border.all(
                          width: style.buttonBorderWidth,
                          color: style.buttonBorderColor),
                      borderRadius: BorderRadius.circular(style.buttonSize),
                    ),
                  ),
                ))),
      ),
    );
  }

  /// * Rotate handle
  Widget _rotateAndMoveHandle(BuildContext context, StackItemStatus status,
      StackItem<StackItemContent> item) {
    final CaseStyle style = _caseStyle(context);

    return Positioned(
      bottom: 10,
      right: 0,
      left: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          GestureDetector(
            onPanStart: (DragStartDetails dud) =>
                _onPanStart(dud, context, StackItemStatus.roating),
            onPanUpdate: (DragUpdateDetails dud) =>
                _onRotateUpdate(dud, context, status),
            onPanEnd: (_) => _onPanEnd(context, status),
            child: _toolCase(
              context,
              style,
              const Icon(Icons.sync),
            ),
          ),
          if (item.size.width + item.size.height < style.buttonSize * 6)
            Padding(
              padding: EdgeInsets.only(left: style.buttonSize / 2),
              child: GestureDetector(
                onPanStart: (DragStartDetails details) =>
                    _onPanStart(details, context, StackItemStatus.moving),
                onPanUpdate: (DragUpdateDetails dud) =>
                    _onPanUpdate(dud, context),
                onPanEnd: (_) => _onPanEnd(context, status),
                child: _toolCase(context, style, const Icon(Icons.open_with)),
              ),
            )
        ]),
      ),
    );
  }

  /// * Operation handle shell
  Widget _toolCase(BuildContext context, CaseStyle style, Widget? child,
      {String? message}) {
    return Container(
      width: style.buttonSize,
      height: style.buttonSize,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: style.buttonBgColor,
          border: Border.all(
              width: style.buttonBorderWidth, color: style.buttonBorderColor)),
      child: child == null
          ? null
          : Tooltip(
              message: message ?? '',
              child: IconTheme(
                data: Theme.of(context).iconTheme.copyWith(
                      color: style.buttonIconColor,
                      size: style.buttonSize * 0.8,
                    ),
                child: child,
              ),
            ),
    );
  }

  /// Wrap 내부에서 Container로 래핑하여 렌더링
  Widget _buildWrapLayout(BuildContext context) {
    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        return p.angle != n.angle ||
            p.size != n.size ||
            p.padding != n.padding ||
            p.content != n.content ||
            p.status != n.status;
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        return SizedBox(
          width: item.size.width,
          height: item.size.height,
          child: Transform.rotate(
            angle: item.angle,
            child: Padding(
              padding: item.padding,
              child: widget.childBuilder?.call(item) ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      child: _buildContent(context),
    );
  }

  /// Column 내부에서 SizedBox로 래핑하여 렌더링
  Widget _buildColumnLayout(BuildContext context) {
    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        return p.angle != n.angle ||
            p.size != n.size ||
            p.padding != n.padding ||
            p.content != n.content ||
            p.status != n.status;
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        return SizedBox(
          width: item.size.width,
          height: item.size.height,
          child: Transform.rotate(
            angle: item.angle,
            child: Padding(
              padding: item.padding,
              child: widget.childBuilder?.call(item) ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      child: _buildContent(context),
    );
  }

  /// 공통 콘텐츠 빌드 메서드
  Widget _buildContent(BuildContext context) {
    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        // 뷰어 모드에서는 더 적극적으로 리빌드
        if (BuildMode.isViewer) {
          return p.content != n.content || p.status != n.status;
        }
        return p.content != n.content ||
            p.status != n.status ||
            p.size != n.size;
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        // 뷰어 모드에서는 편집 기능을 비활성화하고 content만 표시
        if (BuildMode.isViewer) {
          // 뷰어 모드에서 위젯 상태를 강제로 활성화
          final activeItem = item.copyWith(
            status: StackItemStatus.idle, // 강제로 idle 상태로 설정
          );

          return Container(
            // 뷰어 모드에서 렌더링 안정성을 위한 추가 설정
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: RepaintBoundary(
              child: Builder(
                builder: (context) {
                  try {
                    return _content(context, activeItem);
                  } catch (e) {
                    // 뷰어 모드에서 content 렌더링 실패 시 안전한 fallback
                    return Container(
                      width: item.size.width,
                      height: item.size.height,
                      color: Colors.grey[100],
                      child: const Center(
                        child: Text('위젯 로드 실패'),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }

        return MouseRegion(
          cursor: _cursor(item.status),
          child: GestureDetector(
            onTap: () => _onTap(context),
            onPanStart: (DragStartDetails details) =>
                _onPanStart(details, context, StackItemStatus.moving),
            onPanUpdate: (DragUpdateDetails details) =>
                _onPanUpdate(details, context),
            onPanEnd: (DragEndDetails details) =>
                _onPanEnd(context, StackItemStatus.idle),
            child: _childrenStack(context, item),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
