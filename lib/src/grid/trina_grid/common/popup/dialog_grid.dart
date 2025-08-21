import 'package:flutter/material.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '../config/trina_grid_config.dart';
import '../config/row_color_callback.dart';

Future<bool?> alertGrid(BuildContext context, String title, List<TrinaRow> rows,
    List<TrinaColumn> columns) async {
  TrinaGridStateManager? pGridStateManager;

  return await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: SizedBox(
            width: 500,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, size) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TrinaGrid(
                            columns: columns, //setColumnConfig(),
                            rows: rows,
                            onLoaded: (TrinaGridOnLoadedEvent event) {
                              event.stateManager
                                  .setSelectingMode(TrinaGridSelectingMode.row);
                              pGridStateManager = event.stateManager;
                              event.stateManager.setShowColumnFilter(true);
                            },
                            onSelected: (TrinaGridOnSelectedEvent event) {
                              // Navigator.pop(ctx, event);
                            },
                            mode: TrinaGridMode.readOnly,
                            rowColorCallback: (rowColorContext) {
                              return rowColorCallback(rowColorContext);
                            },
                            configuration: TrinaGridConfig,
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xffDEDEDE), width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0)),
                            backgroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('저장'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xffDEDEDE), width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0)),
                            backgroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('닫기'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      });
}
