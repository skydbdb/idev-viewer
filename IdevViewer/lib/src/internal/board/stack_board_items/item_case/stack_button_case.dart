import 'dart:async';

import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/theme/theme_field.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/items/stack_button_item.dart';
import 'package:idev_viewer/src/internal/board/board/viewer/template_launcher.dart';
import 'package:idev_viewer/src/internal/layout/menus/api/api_popup_dialog.dart';
import 'package:idev_viewer/src/internal/layout/helper/launch_url.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/core/location/location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/item_case/common/api_utils.dart'
    as CommonApiUtils;
import 'package:idev_viewer/src/internal/board/stack_board_items/item_case/common/snackbar_utils.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Button case
class StackButtonCase extends StatefulWidget {
  const StackButtonCase({
    super.key,
    required this.item,
    this.onItemUpdated, // 아이템 업데이트 콜백 추가
  });

  /// StackButtonItem
  final StackButtonItem item;
  final Function(StackButtonItem)? onItemUpdated; // 콜백 함수

  @override
  State<StackButtonCase> createState() => _StackButtonCaseState();
}

class _StackButtonCaseState extends State<StackButtonCase> {
  late StackButtonItem currentItem;
  late String theme;
  late HomeRepo homeRepo;
  AppStreams? appStreams;
  late StreamSubscription _updateStackItemSub;
  late StreamSubscription _apiIdResponseSub;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;
    theme = currentItem.theme;
    homeRepo = context.read<HomeRepo>();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
    _subscribeUpdateStackItem();
    _subscribeApiIdResponse();
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub =
        CommonApiUtils.ApiUtils.subscribeApiIdResponse<StackButtonItem>(
      widget.item.boardId,
      widget.item.id,
      homeRepo,
      (item, receivedApiId, targetWidgetIds) =>
          _fetchResponseData(item, receivedApiId, targetWidgetIds),
    );
  }

  void _fetchResponseData(StackButtonItem item, String receivedApiId,
      List<String> targetWidgetIds) {
    // 기설정된 API ID이거나 강제 주입 요청인지 검사
    if (!targetWidgetIds.contains(item.id)) {
      return;
    }

    CommonApiUtils.ApiUtils.fetchResponseData<StackButtonItem>(
      item,
      receivedApiId,
      homeRepo,
      widget.item.boardId,
      widget.item.id,
      (currentContent) => widget.item.copyWith(
        content: widget.item.content!.copyWith(
          buttonName: homeRepo.apis[receivedApiId]?['apiNm'],
          apiId: receivedApiId,
          apiParameters: CommonApiUtils.ApiUtils.extractParamKeysByApiId(
              homeRepo, receivedApiId),
        ),
      ),
      (updatedItem) => homeRepo.hierarchicalControllers[widget.item.boardId]
          ?.updateItem(updatedItem),
      (updatedItem) => homeRepo.addOnTapState(updatedItem),
      (updatedItem, apiParameters) => CommonApiUtils.ApiUtils
          .updateScriptFromApiParameters<StackButtonItem>(
        updatedItem,
        apiParameters,
        homeRepo,
        appStreams ?? AppStreams(), // null인 경우 빈 AppStreams 인스턴스 사용
        (item) => item.copyWith(
            content: item.content?.copyWith(
                script: CommonApiUtils.ApiUtils.generateScript(apiParameters))),
        (updated) => homeRepo.updateStackItemState(updated),
        (updated) => appStreams?.addOnTapState(updated),
      ),
    );
  }

  @override
  void didUpdateWidget(StackButtonCase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      currentItem = widget.item;
      theme = currentItem.theme;
    }
  }

  void _subscribeUpdateStackItem() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _updateStackItemSub = appStreams!.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackButtonItem &&
          v.boardId == widget.item.boardId) {
        final StackButtonItem item = v;

        setState(() {
          theme = item.theme;
          currentItem = item;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    _apiIdResponseSub.cancel();
    super.dispose();
  }

  void _handleButtonTap() async {
    final buttonType =
        currentItem.content?.buttonType ?? 'template'; // 기본값은 template

    switch (buttonType) {
      case 'api':
        await _handleApiAction();
        break;
      case 'url':
        await _handleUrlAction();
        break;
      case 'template':
        await _handleTemplateAction();
        break;
      default:
        await _handleTemplateAction(); // 기본값
        break;
    }
  }

  Future<void> _handleApiAction() async {
    final apiId = currentItem.content?.apiId;
    final script = currentItem.content?.script;

    if (apiId != null && apiId.isNotEmpty) {
      try {
        // script가 비어있으면 기존 API 팝업 표시
        if (script == null || script.isEmpty) {
          final dialog = ApiPopupDialog(
            context: context,
            homeRepo: homeRepo,
          );
          await dialog.showApiDialog(apiId: apiId);
        } else {
          // script가 있으면 파라미터 입력 팝업 표시
          await _showParameterInputDialog(apiId, homeRepo);
        }
      } catch (e) {
        SnackBarUtils.showErrorSnackBar(context, 'API 실행 중 오류가 발생했습니다: $e');
      }
    } else {
      SnackBarUtils.showErrorSnackBar(context, 'API ID가 설정되지 않았습니다.');
    }
  }

  /// 파라미터 입력 팝업 다이얼로그 표시
  Future<void> _showParameterInputDialog(
      String apiId, HomeRepo homeRepo) async {
    try {
      // apiParameters 파싱
      final parameters = CommonApiUtils.ApiUtils.parseApiParameters(
          currentItem.content?.apiParameters);
      final scriptConfig = CommonApiUtils.ApiUtils.parseScriptConfig(
          currentItem.content?.script);

      // GPS 위치 정보 미리 획득
      Map<String, dynamic>? locationData;
      bool hasGpsParams = parameters.any((param) =>
          param['paramKey'] == 'latitude' || param['paramKey'] == 'longitude');

      if (hasGpsParams) {
        try {
          debugPrint('🔍 GPS 위치 정보 획득 시도...');
          locationData = await LocationService().getCurrentLocation();
          debugPrint('✅ GPS 위치 정보 획득 성공: $locationData');
        } catch (e) {
          debugPrint('❌ GPS 위치 정보 획득 실패: $e');

          // MissingPluginException은 기본값 사용으로 처리 (오류 메시지 표시하지 않음)
          if (e.toString().contains('MissingPluginException')) {
            debugPrint('🔌 플러그인 미등록 - 기본값 사용');
          } else {
            // 사용자에게 오류 메시지 표시
            if (e is LocationException) {
              SnackBarUtils.showErrorSnackBar(context, 'GPS 오류: ${e.message}');
            } else {
              SnackBarUtils.showErrorSnackBar(
                  context, 'GPS 위치 정보를 가져올 수 없습니다: $e');
            }
          }

          // GPS 실패 시 기본값 설정 (서울시청 좌표)
          locationData = {
            'latitude': 37.5665,
            'longitude': 126.9780,
            'accuracy': 100.0,
          };
          debugPrint('📍 기본값 사용: 서울시청 좌표');
        }
      }

      // 파라미터 입력 폼 생성
      final formKey = GlobalKey<FormState>();
      final Map<String, TextEditingController> controllers = {};

      // 컨트롤러 초기화
      for (final param in parameters) {
        String key = param['paramKey'];
        String initialValue = '';

        // script 설정에 따른 값 할당
        if (scriptConfig.containsKey(key)) {
          final config = scriptConfig[key];
          initialValue = CommonApiUtils.ApiUtils.getValueByScript(
              key, config!, locationData);
          debugPrint(
              '📝 스크립트 기반 파라미터 초기화: $key = $initialValue (config: $config)');
        } else {
          // 기존 방식 (하위 호환성)
          initialValue =
              CommonApiUtils.ApiUtils.getDefaultValue(key, locationData);
          debugPrint('📝 기본 파라미터 초기화: $key = $initialValue');
        }

        controllers[key] = TextEditingController(text: initialValue);
      }

      // 표시할 파라미터만 필터링 (hide: true인 것 제외)
      final visibleParameters = parameters.where((param) {
        final key = param['paramKey'];
        if (scriptConfig.containsKey(key)) {
          final config = scriptConfig[key];
          return config!['hide'] != true;
        }
        return true; // script 설정이 없으면 기본적으로 표시
      }).toList();

      debugPrint(
          '👁️ 표시할 파라미터: ${visibleParameters.map((p) => p['paramKey']).toList()}');

      // 다이얼로그 표시
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on,
                  color: hasGpsParams ? Colors.blue : Colors.grey),
              const SizedBox(width: 8),
              Text('${currentItem.content?.buttonName ?? 'API'} 입력'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 파라미터 입력 필드들 (표시할 것만)
                    ...visibleParameters.map((param) {
                      String key = param['paramKey'];
                      String label = param['paramKey'];
                      bool isRequired = param['isRequired'] == 'true';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          controller: controllers[key],
                          decoration: InputDecoration(
                            labelText: '$label${isRequired ? ' *' : ''}',
                            border: const OutlineInputBorder(),
                            helperText: param['description'] ?? '',
                            prefixIcon: _getParameterIcon(key) != null
                                ? Icon(_getParameterIcon(key)!)
                                : null,
                          ),
                          validator: isRequired
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return '$label은 필수 입력 항목입니다.';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Map<String, dynamic> result = {};
                  for (final param in parameters) {
                    String key = param['paramKey'];
                    result[key] = controllers[key]!.text;
                  }
                  Navigator.of(context).pop(result);
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (result != null) {
        // 모든 파라미터의 값을 포함하여 API 실행 (hide된 파라미터도 포함)
        final allParams = <String, dynamic>{};

        // 사용자가 입력한 값들
        for (final entry in result.entries) {
          allParams[entry.key] = entry.value;
        }

        // hide된 파라미터들의 값도 추가
        for (final param in parameters) {
          final key = param['paramKey'];
          if (!allParams.containsKey(key)) {
            // 컨트롤러에서 값을 가져오거나 기본값 사용
            if (controllers.containsKey(key)) {
              allParams[key] = controllers[key]!.text;
            } else {
              // 스크립트 설정에 따른 값 할당
              if (scriptConfig.containsKey(key)) {
                final config = scriptConfig[key];
                allParams[key] = CommonApiUtils.ApiUtils.getValueByScript(
                    key, config!, locationData);
              } else {
                allParams[key] =
                    CommonApiUtils.ApiUtils.getDefaultValue(key, locationData);
              }
            }
          }
        }

        debugPrint('🚀 최종 API 파라미터: $allParams');

        // API 실행
        await CommonApiUtils.ApiUtils.executeApiWithParameters(
          apiId,
          homeRepo,
          allParams,
          (message) => SnackBarUtils.showErrorSnackBar(context, message),
          (message) => SnackBarUtils.showSuccessSnackBar(context, message),
        );
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackBar(context, '파라미터 입력 중 오류가 발생했습니다: $e');
    }
  }

  /// 파라미터 타입에 따른 아이콘 반환
  IconData? _getParameterIcon(String key) {
    switch (key.toLowerCase()) {
      case 'latitude':
      case 'longitude':
        return Icons.location_on;
      case 'check_in_time':
      case 'check_out_time':
        return Icons.access_time;
      case 'user_id':
        return Icons.person;
      case 'check_in_method':
      case 'check_out_method':
        return Icons.gps_fixed;
      default:
        return Icons.edit;
    }
  }

  Future<void> _handleUrlAction() async {
    final url = currentItem.content?.url;

    if (url != null && url.isNotEmpty) {
      try {
        launchUrl(url);
      } catch (e) {
        SnackBarUtils.showErrorSnackBar(
            context, 'An error occurred during URL execution: $e');
      }
    } else {
      SnackBarUtils.showErrorSnackBar(context, 'URL is not set.');
    }
  }

  Future<void> _handleTemplateAction() async {
    final templateId = currentItem.content?.templateId;
    final templateNm = currentItem.content?.templateNm;
    final versionId = currentItem.content?.versionId;
    final script = currentItem.content?.script;
    final commitInfo = currentItem.content?.commitInfo;

    if (templateId != null) {
      try {
        // Provide default value if script is empty
        String? finalScript = script;
        if (finalScript?.isEmpty ?? true) {
          finalScript =
              '{"widgets":[],"layout":{"type":"grid","columns":1,"rows":1}}';
        }

        await launchTemplate(
          templateId,
          templateNm: templateNm,
          versionId: versionId,
          script: finalScript,
          commitInfo: commitInfo,
          context: context,
        );
      } catch (e) {
        SnackBarUtils.showErrorSnackBar(
            context, 'An error occurred during template execution: $e');
      }
    } else {
      SnackBarUtils.showErrorSnackBar(context, 'Template ID is not set.');
    }
  }

  String _getButtonText() {
    final buttonName = currentItem.content?.buttonName;
    if (buttonName != null && buttonName.isNotEmpty) {
      return buttonName;
    }

    return '';
  }

  IconData _getButtonIcon() {
    // 사용자가 지정한 아이콘이 있으면 Material Symbols 아이콘 사용
    if (currentItem.content?.icon != null &&
        currentItem.content!.icon!.isNotEmpty) {
      try {
        // iconStringToWidget 대신 직접 IconData 반환하도록 수정
        final predefinedIcon = icons
            .firstWhere((icon) => icon['value'] == currentItem.content!.icon!);
        return (predefinedIcon['icon'] as Icon).icon!;
      } catch (e) {
        print('아이콘 로딩 오류: ${currentItem.content!.icon}, 기본 아이콘 사용');
        return Symbols.error;
      }
    }

    // 기본 아이콘도 Material Symbols로 변경
    final buttonType = currentItem.content?.buttonType ?? 'template';
    switch (buttonType) {
      case 'api':
        return Symbols.api;
      case 'url':
        return Symbols.link;
      case 'template':
        return Symbols.play_arrow;
      default:
        return Symbols.play_arrow;
    }
  }

  Color _getIconColor() {
    final buttonType = currentItem.content?.buttonType ?? 'template';
    switch (buttonType) {
      case 'api':
        return Colors.orange.shade700;
      case 'url':
        return Colors.green.shade700;
      case 'template':
        return Colors.blue.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleButtonTap,
      child: Container(
          padding: const EdgeInsets.all(0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fieldStyle(theme, 'backgroundColor'),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(_getButtonIcon(), color: _getIconColor()),
              const SizedBox(width: 4), // Reduced from 8 to 4
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _getButtonText(),
                  style: fieldStyle(theme, 'textStyle'),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          )),
    );
  }
}
