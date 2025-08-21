import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';

import 'ui.dart';

class TrinaBaseColumnGroup extends StatelessWidget
    implements TrinaVisibilityLayoutChild {
  final TrinaGridStateManager stateManager;

  final TrinaColumnGroupPair columnGroup;

  final int depth;

  TrinaBaseColumnGroup({
    required this.stateManager,
    required this.columnGroup,
    required this.depth,
  }) : super(key: columnGroup.key);

  int get _childrenDepth => columnGroup.group.hasChildren
      ? stateManager.columnGroupDepth(columnGroup.group.children!)
      : 0;

  @override
  double get width => columnGroup.width;

  @override
  double get startPosition => columnGroup.startPosition;

  @override
  bool get keepAlive => false;

  @override
  Widget build(BuildContext context) {
    if (columnGroup.group.expandedColumn == true) {
      return _ExpandedColumn(
        stateManager: stateManager,
        column: columnGroup.columns.first,
        height: ((depth + 1) * stateManager.columnHeight),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnGroupTitle(
          stateManager: stateManager,
          columnGroup: columnGroup,
          depth: depth,
          childrenDepth: _childrenDepth,
        ),
        _ColumnGroup(
          stateManager: stateManager,
          columnGroup: columnGroup,
          depth: _childrenDepth,
        ),
      ],
    );
  }
}

class _ExpandedColumn extends StatelessWidget {
  final TrinaGridStateManager stateManager;

  final TrinaColumn column;

  final double height;

  const _ExpandedColumn({
    required this.stateManager,
    required this.column,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return TrinaBaseColumn(
      stateManager: stateManager,
      column: column,
      columnTitleHeight: height,
    );
  }
}

class _ColumnGroupTitle extends StatelessWidget {
  final TrinaGridStateManager stateManager;

  final TrinaColumnGroupPair columnGroup;

  final int depth;

  final int childrenDepth;

  const _ColumnGroupTitle({
    required this.stateManager,
    required this.columnGroup,
    required this.depth,
    required this.childrenDepth,
  });

  EdgeInsets get _padding =>
      columnGroup.group.titlePadding ??
      stateManager.configuration.style.defaultColumnTitlePadding;

  @override
  Widget build(BuildContext context) {
    final double groupTitleHeight = columnGroup.group.hasChildren
        ? (depth - childrenDepth) * stateManager.columnHeight
        : depth * stateManager.columnHeight;

    final style = stateManager.style;

    return SizedBox(
      height: groupTitleHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: columnGroup.group.backgroundColor,
          border: BorderDirectional(
            end: style.enableColumnBorderVertical
                ? BorderSide(
                    color: style.borderColor,
                    width: 1.0,
                  )
                : BorderSide.none,
            bottom: style.enableColumnBorderHorizontal
                ? BorderSide(
                    color: style.borderColor,
                    width: 1.0,
                  )
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: _padding,
          child: Center(
            child: columnGroup.group.title,
          ),
        ),
      ),
    );
  }
}

class _ColumnGroup extends StatelessWidget {
  final TrinaGridStateManager stateManager;

  final TrinaColumnGroupPair columnGroup;

  final int depth;

  const _ColumnGroup({
    required this.stateManager,
    required this.columnGroup,
    required this.depth,
  });

  List<TrinaColumnGroupPair> get _separateLinkedGroup =>
      stateManager.separateLinkedGroup(
        columnGroupList: columnGroup.group.children!,
        columns: columnGroup.columns,
      );

  Widget _makeFieldWidget(TrinaColumn column) {
    return LayoutId(
      id: column.field,
      child: TrinaBaseColumn(
        stateManager: stateManager,
        column: column,
      ),
    );
  }

  Widget _makeChildWidget(TrinaColumnGroupPair columnGroupPair) {
    return LayoutId(
      id: columnGroupPair.key,
      child: TrinaBaseColumnGroup(
        stateManager: stateManager,
        columnGroup: columnGroupPair,
        depth: depth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (columnGroup.group.hasFields) {
      return CustomMultiChildLayout(
        delegate: ColumnsLayout(
          stateManager: stateManager,
          columns: columnGroup.columns,
          textDirection: stateManager.textDirection,
        ),
        children:
            columnGroup.columns.map(_makeFieldWidget).toList(growable: false),
      );
    }

    return CustomMultiChildLayout(
      delegate: ColumnGroupLayout(
        stateManager: stateManager,
        separateLinkedGroups: _separateLinkedGroup,
        depth: depth,
        textDirection: stateManager.textDirection,
      ),
      children:
          _separateLinkedGroup.map(_makeChildWidget).toList(growable: false),
    );
  }
}

class ColumnGroupLayout extends MultiChildLayoutDelegate {
  final TrinaGridStateManager stateManager;

  final List<TrinaColumnGroupPair> separateLinkedGroups;

  final int depth;

  final TextDirection textDirection;

  ColumnGroupLayout({
    required this.stateManager,
    required this.separateLinkedGroups,
    required this.depth,
    required this.textDirection,
  }) : super(relayout: stateManager.resizingChangeNotifier);

  late double totalHeightOfGroup;

  @override
  Size getSize(BoxConstraints constraints) {
    totalHeightOfGroup = (depth + 1) * stateManager.columnHeight;

    totalHeightOfGroup += stateManager.columnFilterHeight;

    var totalWidthOfGroup = separateLinkedGroups.fold<double>(
      0,
      (previousValue, element) =>
          previousValue +
          element.columns.fold(
            0,
            (previousValue, element) => previousValue + element.width,
          ),
    );

    return Size(totalWidthOfGroup, totalHeightOfGroup);
  }

  @override
  void performLayout(Size size) {
    final isLTR = textDirection == TextDirection.ltr;
    final items = isLTR ? separateLinkedGroups : separateLinkedGroups.reversed;
    double dx = 0;

    for (TrinaColumnGroupPair pair in items) {
      final double width = pair.columns.fold<double>(
        0,
        (previousValue, element) => previousValue + element.width,
      );

      var boxConstraints = BoxConstraints.tight(
        Size(width, totalHeightOfGroup),
      );

      layoutChild(pair.key, boxConstraints);

      positionChild(pair.key, Offset(dx, 0));

      dx += width;
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class ColumnsLayout extends MultiChildLayoutDelegate {
  final TrinaGridStateManager stateManager;

  final List<TrinaColumn> columns;

  final TextDirection textDirection;

  ColumnsLayout({
    required this.stateManager,
    required this.columns,
    required this.textDirection,
  }) : super(relayout: stateManager.resizingChangeNotifier);

  double totalColumnsHeight = 0;

  @override
  Size getSize(BoxConstraints constraints) {
    totalColumnsHeight = 0;

    totalColumnsHeight = stateManager.columnHeight;

    totalColumnsHeight += stateManager.columnFilterHeight;

    double width = columns.fold(
      0,
      (previousValue, element) => previousValue + element.width,
    );

    return Size(width, totalColumnsHeight);
  }

  @override
  void performLayout(Size size) {
    final isLTR = textDirection == TextDirection.ltr;
    final items = isLTR ? columns : columns.reversed;
    double dx = 0;

    for (TrinaColumn col in items) {
      final double width = col.width;

      var boxConstraints = BoxConstraints.tight(
        Size(width, totalColumnsHeight),
      );

      layoutChild(col.field, boxConstraints);

      positionChild(col.field, Offset(dx, 0));

      dx += width;
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}
