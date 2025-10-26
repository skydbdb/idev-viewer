import 'dart:async';

import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

typedef TrinaDualOnSelectedEventCallback = void Function(
    TrinaDualOnSelectedEvent event);

/// In [TrinaDualGrid], set the separation widget between the two grids.
class TrinaDualGridDivider {
  /// If [show] is set to true, a separator widget appears between the grids,
  /// and you can change the width of two grids by dragging them.
  final bool show;

  /// Set the background color.
  final Color backgroundColor;

  /// Set the icon color in the center of the separator widget.
  final Color indicatorColor;

  /// Set the background color when dragging the separator widget.
  final Color draggingColor;

  const TrinaDualGridDivider({
    this.show = true,
    this.backgroundColor = Colors.white,
    this.indicatorColor = const Color(0xFFA1A5AE),
    this.draggingColor = const Color(0xFFDCF5FF),
  });

  const TrinaDualGridDivider.dark({
    this.show = true,
    this.backgroundColor = const Color(0xFF111111),
    this.indicatorColor = const Color(0xFF000000),
    this.draggingColor = const Color(0xFF313131),
  });
}

/// [TrinaDualGrid] can connect the keyboard movement between the two grids
/// by arranging two [TrinaGrid] left and right.
class TrinaDualGrid extends StatefulWidget {
  final TrinaDualGridProps gridPropsA;

  final TrinaDualGridProps gridPropsB;

  final TrinaGridMode mode;

  final TrinaDualOnSelectedEventCallback? onSelected;

  /// [TrinaDualGridDisplayRatio]
  /// Set the width of the two grids by specifying the ratio of the left grid.
  /// 0.5 is 5(left grid):5(right grid).
  /// 0.8 is 8(left grid):2(right grid).
  ///
  /// [TrinaDualGridDisplayFixedAndExpanded]
  /// Fix the width of the left grid.
  ///
  /// [TrinaDualGridDisplayExpandedAndFixed]
  /// Fix the width of the right grid.
  final TrinaDualGridDisplay? display;

  final TrinaDualGridDivider divider;

  const TrinaDualGrid({
    required this.gridPropsA,
    required this.gridPropsB,
    this.mode = TrinaGridMode.normal,
    this.onSelected,
    this.display,
    this.divider = const TrinaDualGridDivider(),
    super.key,
  });

  static const double dividerWidth = 10;

  @override
  TrinaDualGridState createState() => TrinaDualGridState();
}

class TrinaDualGridResizeNotifier extends ChangeNotifier {
  resize() {
    notifyListeners();
  }
}

class TrinaDualGridState extends State<TrinaDualGrid> {
  final TrinaDualGridResizeNotifier resizeNotifier =
      TrinaDualGridResizeNotifier();

  late final TrinaDualGridDisplay display;

  late final TrinaGridStateManager _stateManagerA;

  late final TrinaGridStateManager _stateManagerB;

  late final StreamSubscription<TrinaGridEvent> _streamA;

  late final StreamSubscription<TrinaGridEvent> _streamB;

  @override
  void initState() {
    super.initState();

    display = widget.display ?? TrinaDualGridDisplayRatio();
  }

  @override
  void dispose() {
    _streamA.cancel();

    _streamB.cancel();

    super.dispose();
  }

  Widget _buildGrid({
    required TrinaDualGridProps props,
    required bool isGridA,
    required TrinaGridMode mode,
  }) {
    return LayoutId(
      id: isGridA == true ? _TrinaDualGridId.gridA : _TrinaDualGridId.gridB,
      child: TrinaGrid(
        columns: props.columns,
        rows: props.rows,
        columnGroups: props.columnGroups,
        onLoaded: (TrinaGridOnLoadedEvent onLoadedEvent) {
          if (isGridA) {
            _stateManagerA = onLoadedEvent.stateManager;
          } else {
            _stateManagerB = onLoadedEvent.stateManager;
          }

          handleEvent(TrinaGridEvent trinaEvent) {
            if (trinaEvent is TrinaGridCannotMoveCurrentCellEvent) {
              if (isGridA == true && trinaEvent.direction.isRight) {
                _stateManagerA.setKeepFocus(false);
                _stateManagerB.setKeepFocus(true);
              } else if (isGridA != true && trinaEvent.direction.isLeft) {
                _stateManagerA.setKeepFocus(true);
                _stateManagerB.setKeepFocus(false);
              }
            }
          }

          if (isGridA) {
            _streamA =
                onLoadedEvent.stateManager.eventManager!.listener(handleEvent);
          } else {
            _streamB =
                onLoadedEvent.stateManager.eventManager!.listener(handleEvent);
          }

          if (props.onLoaded != null) {
            props.onLoaded!(onLoadedEvent);
          }
        },
        onChanged: props.onChanged,
        onSelected: (TrinaGridOnSelectedEvent onSelectedEvent) {
          if (onSelectedEvent.row == null || onSelectedEvent.cell == null) {
            widget.onSelected!(
              TrinaDualOnSelectedEvent(
                gridA: null,
                gridB: null,
              ),
            );
          } else {
            widget.onSelected!(
              TrinaDualOnSelectedEvent(
                gridA: TrinaGridOnSelectedEvent(
                  row: _stateManagerA.currentRow,
                  rowIdx: _stateManagerA.currentRowIdx,
                  cell: _stateManagerA.currentCell,
                ),
                gridB: TrinaGridOnSelectedEvent(
                  row: _stateManagerB.currentRow,
                  rowIdx: _stateManagerB.currentRowIdx,
                  cell: _stateManagerB.currentCell,
                ),
              ),
            );
          }
        },
        onSorted: props.onSorted,
        onRowChecked: props.onRowChecked,
        onRowDoubleTap: props.onRowDoubleTap,
        onRowSecondaryTap: props.onRowSecondaryTap,
        onRowsMoved: props.onRowsMoved,
        onColumnsMoved: props.onColumnsMoved,
        createHeader: props.createHeader,
        createFooter: props.createFooter,
        noRowsWidget: props.noRowsWidget,
        rowColorCallback: props.rowColorCallback,
        columnMenuDelegate: props.columnMenuDelegate,
        configuration: props.configuration,
        mode: mode,
        key: props.key,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLTR = Directionality.of(context) == TextDirection.ltr;

    return CustomMultiChildLayout(
      delegate: TrinaDualGridLayoutDelegate(
        notifier: resizeNotifier,
        display: display,
        showDraggableDivider: widget.divider.show,
        isLTR: isLTR,
      ),
      children: [
        _buildGrid(
          props: widget.gridPropsA,
          isGridA: true,
          mode: widget.mode,
        ),
        if (widget.divider.show == true)
          LayoutId(
            id: _TrinaDualGridId.divider,
            child: TrinaDualGridDividerWidget(
              backgroundColor: widget.divider.backgroundColor,
              indicatorColor: widget.divider.indicatorColor,
              draggingColor: widget.divider.draggingColor,
              dragCallback: (details) {
                final RenderBox object =
                    context.findRenderObject() as RenderBox;

                display.offset = object
                    .globalToLocal(Offset(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    ))
                    .dx;

                resizeNotifier.resize();
              },
            ),
          ),
        _buildGrid(
          props: widget.gridPropsB,
          isGridA: false,
          mode: widget.mode,
        ),
      ],
    );
  }
}

class TrinaDualGridDividerWidget extends StatefulWidget {
  final Color backgroundColor;

  final Color indicatorColor;

  final Color draggingColor;

  final void Function(DragUpdateDetails) dragCallback;

  const TrinaDualGridDividerWidget({
    required this.backgroundColor,
    required this.indicatorColor,
    required this.draggingColor,
    required this.dragCallback,
    super.key,
  });

  @override
  State<TrinaDualGridDividerWidget> createState() =>
      TrinaDualGridDividerWidgetState();
}

class TrinaDualGridDividerWidgetState
    extends State<TrinaDualGridDividerWidget> {
  bool isDragging = false;

  void onHorizontalDragStart(DragStartDetails details) {
    if (isDragging == false) {
      setState(() {
        isDragging = true;
      });
    }
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    widget.dragCallback(details);

    if (isDragging == false) {
      setState(() {
        isDragging = true;
      });
    }
  }

  void onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutContext, size) {
        return GestureDetector(
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: ColoredBox(
            color: isDragging ? widget.draggingColor : widget.backgroundColor,
            child: Stack(
              children: [
                Positioned(
                  top: (size.maxHeight / 2) - 18,
                  left: -4,
                  child: Icon(
                    Icons.drag_indicator,
                    color: widget.indicatorColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _TrinaDualGridId {
  gridA,
  gridB,
  divider,
}

class TrinaDualGridLayoutDelegate extends MultiChildLayoutDelegate {
  TrinaDualGridLayoutDelegate({
    required ChangeNotifier notifier,
    required this.display,
    required this.showDraggableDivider,
    required this.isLTR,
  }) : super(relayout: notifier);

  final TrinaDualGridDisplay display;

  final bool showDraggableDivider;

  final bool isLTR;

  @override
  void performLayout(Size size) {
    final BoxConstraints constrains = BoxConstraints(
      maxWidth: size.width,
      maxHeight: size.height,
    );

    final dividerHalf =
        showDraggableDivider ? TrinaDualGrid.dividerWidth / 2 : 0;

    final dividerWidth = dividerHalf * 2;

    double gridAWidth = showDraggableDivider
        ? display.offset == null
            ? display.gridAWidth(constrains) - dividerHalf
            : display.offset! - dividerHalf
        : display.gridAWidth(constrains) - dividerHalf;
    double gridBWidth = size.width - gridAWidth - dividerWidth;

    if (!isLTR) {
      final savedGridBWidth = gridBWidth;
      gridBWidth = gridAWidth;
      gridAWidth = savedGridBWidth;
    }

    if (gridAWidth < 0) {
      gridAWidth = 0;
    } else if (gridAWidth > size.width - dividerWidth) {
      gridAWidth = size.width - dividerWidth;
    }

    if (gridBWidth < 0) {
      gridBWidth = 0;
    } else if (gridBWidth > size.width - dividerWidth) {
      gridBWidth = size.width - dividerWidth;
    }

    if (hasChild(_TrinaDualGridId.gridA)) {
      layoutChild(
        _TrinaDualGridId.gridA,
        BoxConstraints.tight(
          Size(gridAWidth, size.height),
        ),
      );

      final double posX = isLTR ? 0 : gridBWidth + dividerWidth;

      positionChild(_TrinaDualGridId.gridA, Offset(posX, 0));
    }

    if (hasChild(_TrinaDualGridId.divider)) {
      layoutChild(
        _TrinaDualGridId.divider,
        BoxConstraints.tight(
          Size(TrinaDualGrid.dividerWidth, size.height),
        ),
      );

      final double posX = isLTR ? gridAWidth : gridBWidth;

      positionChild(_TrinaDualGridId.divider, Offset(posX, 0));
    }

    if (hasChild(_TrinaDualGridId.gridB)) {
      layoutChild(
        _TrinaDualGridId.gridB,
        BoxConstraints.tight(
          Size(gridBWidth, size.height),
        ),
      );

      final double posX = isLTR ? gridAWidth + dividerWidth : 0;

      positionChild(_TrinaDualGridId.gridB, Offset(posX, 0));
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class TrinaDualOnSelectedEvent {
  TrinaGridOnSelectedEvent? gridA;

  TrinaGridOnSelectedEvent? gridB;

  TrinaDualOnSelectedEvent({
    this.gridA,
    this.gridB,
  });
}

abstract class TrinaDualGridDisplay {
  double gridAWidth(BoxConstraints size);

  double gridBWidth(BoxConstraints size);

  double? offset;
}

class TrinaDualGridDisplayRatio implements TrinaDualGridDisplay {
  final double ratio;

  TrinaDualGridDisplayRatio({
    this.ratio = 0.5,
  }) : assert(0 < ratio && ratio < 1);

  @override
  double? offset;

  @override
  double gridAWidth(BoxConstraints size) => size.maxWidth * ratio;

  @override
  double gridBWidth(BoxConstraints size) => size.maxWidth * (1 - ratio);
}

class TrinaDualGridDisplayFixedAndExpanded implements TrinaDualGridDisplay {
  final double width;

  TrinaDualGridDisplayFixedAndExpanded({
    this.width = 206.0,
  });

  @override
  double? offset;

  @override
  double gridAWidth(BoxConstraints size) => width;

  @override
  double gridBWidth(BoxConstraints size) => size.maxWidth - width;
}

class TrinaDualGridDisplayExpandedAndFixed implements TrinaDualGridDisplay {
  final double width;

  TrinaDualGridDisplayExpandedAndFixed({
    this.width = 206.0,
  });

  @override
  double? offset;

  @override
  double gridAWidth(BoxConstraints size) => size.maxWidth - width;

  @override
  double gridBWidth(BoxConstraints size) => width;
}

class TrinaDualGridProps {
  /// {@macro trina_grid_property_columns}
  final List<TrinaColumn> columns;

  /// {@macro trina_grid_property_rows}
  final List<TrinaRow> rows;

  /// {@macro trina_grid_property_columnGroups}
  final List<TrinaColumnGroup>? columnGroups;

  /// {@macro trina_grid_property_onLoaded}
  final TrinaOnLoadedEventCallback? onLoaded;

  /// {@macro trina_grid_property_onChanged}
  final TrinaOnChangedEventCallback? onChanged;

  /// {@macro trina_grid_property_onSorted}
  final TrinaOnSortedEventCallback? onSorted;

  /// {@macro trina_grid_property_onRowChecked}
  final TrinaOnRowCheckedEventCallback? onRowChecked;

  /// {@macro trina_grid_property_onRowDoubleTap}
  final TrinaOnRowDoubleTapEventCallback? onRowDoubleTap;

  /// {@macro trina_grid_property_onRowSecondaryTap}
  final TrinaOnRowSecondaryTapEventCallback? onRowSecondaryTap;

  /// {@macro trina_grid_property_onRowsMoved}
  final TrinaOnRowsMovedEventCallback? onRowsMoved;

  /// {@macro trina_grid_property_onColumnsMoved}
  final TrinaOnColumnsMovedEventCallback? onColumnsMoved;

  /// {@macro trina_grid_property_createHeader}
  final CreateHeaderCallBack? createHeader;

  /// {@macro trina_grid_property_createFooter}
  final CreateFooterCallBack? createFooter;

  /// {@macro trina_grid_property_noRowsWidget}
  final Widget? noRowsWidget;

  /// {@macro trina_grid_property_rowColorCallback}
  final TrinaRowColorCallback? rowColorCallback;

  /// {@macro trina_grid_property_columnMenuDelegate}
  final TrinaColumnMenuDelegate? columnMenuDelegate;

  /// {@macro trina_grid_property_configuration}
  final TrinaGridConfiguration configuration;

  /// Execution mode of [TrinaGrid].
  ///
  /// [TrinaGridMode.normal]
  /// {@macro trina_grid_mode_normal}
  ///
  /// [TrinaGridMode.select], [TrinaGridMode.selectWithOneTap]
  /// {@macro trina_grid_mode_select}
  ///
  /// [TrinaGridMode.popup]
  /// {@macro trina_grid_mode_popup}
  final TrinaGridMode? mode;

  final Key? key;

  const TrinaDualGridProps({
    required this.columns,
    required this.rows,
    this.columnGroups,
    this.onLoaded,
    this.onChanged,
    this.onSorted,
    this.onRowChecked,
    this.onRowDoubleTap,
    this.onRowSecondaryTap,
    this.onRowsMoved,
    this.onColumnsMoved,
    this.createHeader,
    this.createFooter,
    this.noRowsWidget,
    this.rowColorCallback,
    this.columnMenuDelegate,
    this.configuration = const TrinaGridConfiguration(),
    this.mode,
    this.key,
  });

  TrinaDualGridProps copyWith({
    List<TrinaColumn>? columns,
    List<TrinaRow>? rows,
    TrinaOptional<List<TrinaColumnGroup>?>? columnGroups,
    TrinaOptional<TrinaOnLoadedEventCallback?>? onLoaded,
    TrinaOptional<TrinaOnChangedEventCallback?>? onChanged,
    TrinaOptional<TrinaOnSortedEventCallback?>? onSorted,
    TrinaOptional<TrinaOnRowCheckedEventCallback?>? onRowChecked,
    TrinaOptional<TrinaOnRowDoubleTapEventCallback?>? onRowDoubleTap,
    TrinaOptional<TrinaOnRowSecondaryTapEventCallback?>? onRowSecondaryTap,
    TrinaOptional<TrinaOnRowsMovedEventCallback?>? onRowsMoved,
    TrinaOptional<TrinaOnColumnsMovedEventCallback?>? onColumnsMoved,
    TrinaOptional<CreateHeaderCallBack?>? createHeader,
    TrinaOptional<CreateFooterCallBack?>? createFooter,
    TrinaOptional<Widget?>? noRowsWidget,
    TrinaOptional<TrinaRowColorCallback?>? rowColorCallback,
    TrinaOptional<TrinaColumnMenuDelegate?>? columnMenuDelegate,
    TrinaGridConfiguration? configuration,
    TrinaOptional<TrinaGridMode?>? mode,
    Key? key,
  }) {
    return TrinaDualGridProps(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      columnGroups:
          columnGroups == null ? this.columnGroups : columnGroups.value,
      onLoaded: onLoaded == null ? this.onLoaded : onLoaded.value,
      onChanged: onChanged == null ? this.onChanged : onChanged.value,
      onSorted: onSorted == null ? this.onSorted : onSorted.value,
      onRowChecked:
          onRowChecked == null ? this.onRowChecked : onRowChecked.value,
      onRowDoubleTap:
          onRowDoubleTap == null ? this.onRowDoubleTap : onRowDoubleTap.value,
      onRowSecondaryTap: onRowSecondaryTap == null
          ? this.onRowSecondaryTap
          : onRowSecondaryTap.value,
      onRowsMoved: onRowsMoved == null ? this.onRowsMoved : onRowsMoved.value,
      onColumnsMoved:
          onColumnsMoved == null ? this.onColumnsMoved : onColumnsMoved.value,
      createHeader:
          createHeader == null ? this.createHeader : createHeader.value,
      createFooter:
          createFooter == null ? this.createFooter : createFooter.value,
      noRowsWidget:
          noRowsWidget == null ? this.noRowsWidget : noRowsWidget.value,
      rowColorCallback: rowColorCallback == null
          ? this.rowColorCallback
          : rowColorCallback.value,
      columnMenuDelegate: columnMenuDelegate == null
          ? this.columnMenuDelegate
          : columnMenuDelegate.value,
      configuration: configuration ?? this.configuration,
      mode: mode == null ? this.mode : mode.value,
      key: key ?? this.key,
    );
  }
}
