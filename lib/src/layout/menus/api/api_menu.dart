import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/core/api/api_endpoint_ide.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '/src/repo/home_repo.dart';
import 'api_popup_dialog.dart';

class ApiMenu extends StatefulWidget {
  const ApiMenu({super.key});

  @override
  State<ApiMenu> createState() => _ApiMenuState();
}

class _ApiMenuState extends State<ApiMenu> {
  late HomeRepo homeRepo;
  List<TrinaColumn> columns = [];
  List<TrinaRow> rows = [];
  TrinaGridStateManager? stateManager;
  ValueKey renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
  late StreamSubscription _apiIdResponseSub;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    _initStateSettings();
    // _subscribeStreams();
  }

  @override
  void dispose() {
    _apiIdResponseSub.cancel();
    super.dispose();
  }

  void _initStateSettings() {
    columns = ApiUtils.getApiColumns();
    _loadApiList();
  }

  void _initializeApiRequests() {
    // homeRepo.addApiRequest({
    //   'method': 'get',
    //   'uri': '/apis',
    //   'if_id': 'apis',
    // });
    homeRepo.reqIdeApi('get', ApiEndpointIDE.apis);
  }

  void _loadApiList() {
    final apiRows = ApiUtils.createApiRows(homeRepo.apis);
    setState(() {
      rows = apiRows;
      renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  // void _subscribeStreams() {
  //   // _subscribeApiIdResponse();
  // }

  // void _subscribeApiIdResponse() {
  //   _apiIdResponseSub = homeRepo.getApiResponseStream.listen((v) {
  //     if (v != null) {
  //       _handleApiIdResponse(v);
  //     }
  //   });
  // }

  // void _handleApiIdResponse(dynamic v) async {
  //   _loadApiList();
  // }

  // void _onApiSaved(Map<String, dynamic> params) {
  //   ApiUtils.handleApiSaved(homeRepo, params,
  //       onRefresh: _initializeApiRequests);
  // }

  // void _onApiExecuted(String apiId, List<Map<String, dynamic>> apiParams) {
  //   ApiUtils.handleApiExecuted(homeRepo, apiId, apiParams);
  // }

  Future<void> _showApiDialog({TrinaRow? apiRow}) async {
    final dialog = ApiPopupDialog(
      context: context,
      homeRepo: homeRepo,
      // onApiSaved: _onApiSaved,
      // onApiExecuted: _onApiExecuted,
    );

    await dialog.showApiDialog(
        apiId: apiRow?.toJson()['apiId'].split('\n').first);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Theme(
              data: ThemeData.dark(),
              child: Container(
                  color: ThemeData.dark().dividerColor,
                  height: 20,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('API'),
                        ],
                      ),
                      Positioned(
                          right: 0,
                          bottom: 0,
                          child: Row(
                            children: [
                              InkWell(
                                  onTap: () async {
                                    await _showApiDialog();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Tooltip(
                                        message: 'API 등록',
                                        child: Icon(Icons.add, size: 16)),
                                  )),
                              InkWell(
                                  onTap: () {
                                    _initializeApiRequests();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Tooltip(
                                        message: 'Refresh',
                                        child: Icon(Icons.refresh, size: 16)),
                                  )),
                            ],
                          )),
                    ],
                  ))),
        ),
        !mounted
            ? const SizedBox()
            : Expanded(
                child: apiList(),
              )
      ],
    );
  }

  Widget apiList() {
    return Theme(
        data: ThemeData.dark(),
        child: TrinaGrid(
          key: renderKey,
          columns: columns,
          rows: rows,
          mode: TrinaGridMode.selectWithOneTap,
          onSelected: (event) {
            _showApiDialog(apiRow: event.row);
          },
          onLoaded: (TrinaGridOnLoadedEvent event) {
            stateManager = event.stateManager;
            stateManager?.setShowColumnFilter(true);
            stateManager?.setShowColumnTitle(false);
          },
          configuration: const TrinaGridConfiguration.dark(),
        ));
  }
}
