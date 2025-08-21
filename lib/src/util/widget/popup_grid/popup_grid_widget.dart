import 'package:flutter/material.dart';
import 'package:idev_v1/src/const/const.dart';
import '../../../grid/trina_grid/trina_grid.dart';
import '/src/layout/helper/info_dialog.dart'; // 경로 수정 (가정)
import 'package:markdown_widget/markdown_widget.dart';
import 'popup_grid_launcher.dart';

class PopupGrid extends StatefulWidget {
  final String title;
  final List<TrinaColumn> columns;
  final List<TrinaRow> rows;
  final TrinaGridMode mode;
  final TrinaRowColorCallback? rowColorCallback;
  final bool autoFitColumn;
  final bool darkMode;

  const PopupGrid({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.mode = TrinaGridMode.normal,
    this.rowColorCallback,
    this.autoFitColumn = true,
    this.darkMode = true,
  });

  @override
  State<PopupGrid> createState() => _PopupGridState();
}

class _PopupGridState extends State<PopupGrid> {
  late TrinaGridStateManager stateManager;
  List<TrinaRow> currentSelectedRows = [];
  TrinaRow? currentSelectedRow;
  bool isCheckedAll = false;

  @override
  void initState() {
    super.initState();
    isCheckedAll =
        widget.rows.isNotEmpty && widget.rows.every((r) => r.checked ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final titleWidget = popupGridHeader(context, widget.title);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      backgroundColor: widget.darkMode ? const Color(0xFF242424) : Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      actionsPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
      title: titleWidget,
      content: SizedBox(
        width: 800, // Dialog width will be constrained by its parent
        height: 500, // Fixed height for the content area
        child: TrinaGrid(
          // key: ValueKey(
          //     widget.rows.hashCode), // Add key for potential state issues
          columns: widget.columns,
          rows: widget.rows,
          // rowColorCallback: widget.rowColorCallback,
          mode: widget.mode,
          onLoaded: (event) {
            try {
              stateManager = event.stateManager;
              stateManager.setShowColumnFilter(true);
              stateManager.setSelectingMode(TrinaGridSelectingMode.row);
              // if (widget.autoFitColumn) {
              //   // TODO: TrinaGrid API를 확인하여 stateManager로 컬럼 너비 자동 맞춤 기능 호출
              // }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    currentSelectedRows = stateManager.checkedRows;
                    currentSelectedRow = stateManager.currentRow;
                    isCheckedAll =
                        stateManager.checkedRows.length == widget.rows.length &&
                            widget.rows.isNotEmpty;
                  });
                }
              });
            } catch (e) {
              print('PopupGrid build() 호출, error: $e');
            }
          },
          onRowDoubleTap: (event) {
            // print(event.row.toJson());
            if (mounted) {
              setState(() {
                currentSelectedRows = [];
                currentSelectedRow = event.row;
                isCheckedAll =
                    stateManager.checkedRows.length == widget.rows.length &&
                        widget.rows.isNotEmpty;
              });
            }
          },
          onSelected: (event) {
            if (mounted) {
              setState(() {
                currentSelectedRows = event.selectedRows ?? [];
                currentSelectedRow = event.row;
                isCheckedAll =
                    stateManager.checkedRows.length == widget.rows.length &&
                        widget.rows.isNotEmpty;
              });
            }
          },
          configuration: TrinaGridConfiguration(
            style: widget.darkMode
                ? const TrinaGridStyleConfig.dark()
                : const TrinaGridStyleConfig(),
            localeText: const TrinaGridLocaleText.korean(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('취소'),
          onPressed: () {
            Navigator.of(context)
                .pop(PopupGridResult(buttonKey: 'cancel')); // Return cancel
          },
        ),
        TextButton(
          child: const Text('확인'),
          onPressed: () {
            currentSelectedRows = stateManager.checkedRows.isNotEmpty
                ? stateManager.checkedRows
                : stateManager.rows;

            Navigator.of(context).pop(PopupGridResult(
                selectedRows: currentSelectedRows,
                row:
                    currentSelectedRow, // Return last selected row as well if applicable
                buttonKey: 'ok'));
          },
        ),
      ],
    );
  }

  void addRows(TrinaGridStateManager stateManager) async {
    TrinaRow newRow = stateManager.getNewRows(count: 1).first;
    int rowIdx = stateManager.currentRowIdx ?? stateManager.rows.length;
    stateManager.insertRows(rowIdx, [newRow]);
    stateManager.setCurrentSelectingRowsByRange(rowIdx, rowIdx);
  }

  void removeRows(TrinaGridStateManager stateManager) async {
    for (var row in stateManager.checkedRows) {
      stateManager.removeRows([row]);
      row.setChecked(false);
    }

    stateManager.setShowLoading(true);
    stateManager.setPage(1, notify: false);
    stateManager.setShowLoading(false);
  }

  Widget popupGridHeader(BuildContext context, String title) {
    return title.toString().isEmpty
        ? const SizedBox()
        : SizedBox(
            child: Row(
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ListTile(
                    title: Text(
                  title,
                  textAlign: TextAlign.center,
                )),
              )),
              if (title.contains('요청 메뉴'))
                Row(children: [
                  Tooltip(
                      message: '추가',
                      child: IconButton(
                          onPressed: () {
                            addRows(stateManager);
                          },
                          icon: const Icon(Icons.add))),
                  Tooltip(
                      message: '삭제',
                      child: IconButton(
                          onPressed: () {
                            removeRows(stateManager);
                          },
                          icon: const Icon(Icons.remove))),
                ]),
              if (title.contains('Fx'))
                Tooltip(
                  message: '작성 방법',
                  child: IconButton(
                    icon: const Icon(Icons.help),
                    onPressed: () async {
                      await infoDialog(context,
                          title: null,
                          content: const SingleChildScrollView(
                              child: MarkdownBlock(data: FORMULA)));
                    },
                  ),
                ),
            ],
          ));
  }
}
