import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '/src/di/service_locator.dart';
import '/src/board/stack_board_items/common/new_field.dart';
import '/src/board/stack_items.dart';
import '/src/repo/home_repo.dart';
import '/src/repo/app_streams.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/api_config.dart';

class StackSearchCase extends StatefulWidget {
  const StackSearchCase({
    super.key,
    required this.item,
  });

  final StackSearchItem item;

  @override
  State<StackSearchCase> createState() => _StackSearchCaseState();
}

class _StackSearchCaseState extends State<StackSearchCase> {
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  dynamic get item => widget.item;
  GlobalKey<FormBuilderState> formKey = GlobalKey();
  String savedValue = '';
  List<ApiConfig> reqApis = [];
  List<ApiConfig> fields = [];

  late StreamSubscription _updateStackItemSub;

  @override
  void initState() {
    super.initState();
    _initStateSettings();
    _mergeFields();
    _subscribeUpdateStackItem();
  }

  void _initStateSettings() {
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    reqApis = widget.item.content?.reqApis ?? [];
  }

  void _mergeFields() {
    final fieldsSet = reqApis.map((api) => api.fieldNm).toSet().toList();
    if (reqApis.isNotEmpty) {
      fields = [
        ...fieldsSet.map((m) => reqApis.firstWhere((api) => api.fieldNm == m))
      ];
    }
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackSearchItem &&
          v.boardId == widget.item.boardId) {
        final StackSearchItem item = v;
        setState(() {
          reqApis = item.content?.reqApis ?? [];
          _mergeFields();
        });
      }
    });
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    super.dispose();
  }

  void _search() {
    formKey.currentState!.saveAndValidate();
    savedValue = formKey.currentState?.value.toString() ?? '';

    Map<String, Map<String, dynamic>>? apiParams = {};
    formKey.currentState?.value.forEach((key, value) {
      final apis = reqApis.where((api) => api.fieldNm == key);
      for (var reqApi in apis) {
        final apiId = reqApi.apiId.split(RegExp('\\n')).first;
        apiParams[apiId] = {
          ...apiParams[apiId] ?? {},
          '${reqApi.field}': value.toString().isEmpty ? null : value
        };
      }
    });

    // print('apiParams: $apiParams');
    apiParams.forEach((key, value) {
      // homeRepo.addApiRequest((key, value));
      homeRepo.addApiRequest(key, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      FormBuilder(
          key: formKey,
          clearValueOnUnregister: true,
          onChanged: () {
            // print('1 changed: ${formKey.currentState?.value}');
          },
          child: ListView(
            children: [
              Wrap(children: <Widget>[
                ...fields.map((apiConfig) => SizedBox(
                      width:
                          double.parse((apiConfig.width?.toString()) ?? '100'),
                      child: NewField(
                          type: FieldType.values
                              .byName(apiConfig.type ?? FieldType.text.name),
                          name: apiConfig.fieldNm ?? '',
                          labelText: apiConfig.fieldNm ?? '',
                          format: apiConfig.format?.toString() ?? '',
                          enabled: apiConfig.enabled ?? true,
                          widgetName: 'search',
                          homeRepo: homeRepo),
                    )),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: MaterialButton(
                    color: Theme.of(context).colorScheme.secondary,
                    onPressed: _search,
                    child: Text(
                      (item.content as SearchItemContent?)?.buttonName ?? '조회',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ],
          ))
    ]);
  }
}
