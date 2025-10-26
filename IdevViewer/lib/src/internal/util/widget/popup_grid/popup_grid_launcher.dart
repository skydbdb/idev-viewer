import 'package:flutter/material.dart';
import '../../../grid/trina_grid/trina_grid.dart';
import 'popup_grid_widget.dart'; // PopupGrid 위젯 파일 import

Future<PopupGridResult?> openPopupGrid(
  BuildContext context,
  String title,
  List<TrinaColumn> columns,
  List<TrinaRow> rows, {
  TrinaGridMode mode = TrinaGridMode.normal,
  TrinaRowColorCallback? rowColorCallback,
  bool autoFitColumn = true,
  bool darkMode = true,
  TrinaGridConfiguration? configuration,
}) async {
  final result = await showDialog<PopupGridResult>(
    context: context,
    builder: (BuildContext context) {
      return PopupGrid(
        title: title,
        columns: columns,
        rows: rows,
        mode: mode,
        rowColorCallback: rowColorCallback,
        autoFitColumn: autoFitColumn,
        darkMode: darkMode,
        configuration: configuration,
      );
    },
  );
  return result;
}

/// PopupGrid의 결과를 나타내는 클래스
class PopupGridResult {
  final TrinaGridOnSelectedEvent? selectedEvent; // 그리드 선택 이벤트
  final TrinaRow? row; // 선택된 행 (선택 사항)
  final List<TrinaRow>? selectedRows; // 선택된 행들 (선택 사항)
  final String? buttonKey; // 눌린 버튼 식별자 ('ok', 'cancel' 등)

  PopupGridResult({
    this.selectedEvent,
    this.row,
    this.selectedRows,
    this.buttonKey,
  });
}
