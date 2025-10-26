import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/theme/theme_field.dart';
import 'package:idev_viewer/src/internal/fx/formula_parser.dart';
import 'package:intl/intl.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:idev_viewer/src/internal/pms/view/common/config/pluto_grid_config.dart';
import 'package:idev_viewer/src/internal/core/config/env.dart'; // 환경 설정 import 추가

enum FieldType {
  text,
  // textField,
  // textLabel,
  number,
  currency,
  stepper,
  percentage,
  boolean,
  formula,
  date,
  time,
  dateTime,
  select,
  checkGroup,
  radioGroup,
  popup,
  // password,
  // phone,
  // email,
  imageUrl,
  // dropdown,
}

List<String> typeFormat(FieldType type) {
  return switch (type) {
    FieldType.popup => ['showAlert', 'textField'],
    FieldType.imageUrl => ['fitSize', 'showPopup'],
    FieldType.number => ['default', '###,###', '###,###.0#'],
    FieldType.currency => ['kr', 'us', 'eu', 'cn', 'da', 'jp'],
    FieldType.formula => ['###', '###,###', '###,###.0#'],
    FieldType.date => [
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'yyyy년 MM월 dd일',
      ],
    FieldType.time => [
        'HH:mm:ss',
        'HH:mm',
        'HH시 mm분 ss초',
        'HH시 mm분',
      ],
    FieldType.dateTime => [
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'yyyy년 MM월 dd일',
        'yyyy-MM-dd HH:mm:ss',
        'yyyy/MM/dd HH:mm:ss',
        'yyyy년 MM월 dd일 HH시 mm분 ss초'
      ],
    _ => ['default']
  };
}

FormFieldValidator<String>? typeValidator(FieldType type) {
  return switch (type) {
    // FieldType.text => FormBuilderValidators.compose([FormBuilderValidators.match(r'([a-zA-Z0-9]*): ([#a-zA-Z0-9ㄱ-ㅎ가-힣]*)', errorText: '형식 오류')]),
    // FieldType.textLabel => FormBuilderValidators.compose([FormBuilderValidators.numeric(errorText: '문자 오류.')]),
    FieldType.number => FormBuilderValidators.compose(
        [FormBuilderValidators.numeric(errorText: '숫자 오류.')]),
    // FieldType.password =>
    //   FormBuilderValidators.compose([FormBuilderValidators.required()]),
    // FieldType.phone => FormBuilderValidators.compose([
    //     FormBuilderValidators.match(r'^\d{2,3}-\d{3,4}-\d{4}$',
    //         errorText: '전화 번호 오류')
    //   ]),
    // FieldType.email => FormBuilderValidators.compose(
    //     [FormBuilderValidators.email(errorText: 'email 오류.')]),
    FieldType.imageUrl => FormBuilderValidators.compose(
        [FormBuilderValidators.url(errorText: 'image url 오류.')]),
    // FieldType.dateTime => FormBuilderValidators.compose(
    //     [FormBuilderValidators.dateString(errorText: '날짜/시간 오류.')]),
    _ => null
  };
}

class NewField extends StatefulWidget {
  const NewField({
    super.key,
    this.id,
    required this.type,
    required this.name,
    required this.labelText,
    this.initialValue,
    this.textAlign,
    this.items,
    this.format,
    this.enabled,
    this.theme,
    this.widgetName,
    this.callback,
    this.fxsData,
    this.homeRepo,
  });

  final String? id;
  final FieldType type;
  final String name;
  final String labelText;
  final String? initialValue;
  final List<String>? items;
  final String? format;
  final bool? enabled;
  final String? textAlign;
  final String? theme;
  final String? widgetName; // grid, detail, search
  final Function? callback;
  final Map<String, dynamic>? fxsData;
  final HomeRepo? homeRepo;

  @override
  State<NewField> createState() => _NewFieldState();
}

class _NewFieldState extends State<NewField> {
  FieldType get type => widget.type;
  String get id => widget.id ?? '';
  String get name => widget.name;
  String get labelText => widget.labelText;
  String get initialValue => widget.initialValue ?? '';
  TextAlign get textAlign =>
      TextAlign.values.byName(widget.textAlign ?? 'left');
  String get format => widget.format ?? '';
  bool get enabled => widget.enabled ?? true;
  String get theme => widget.theme ?? 'White';
  String get widgetName => widget.widgetName ?? '';
  Map<String, dynamic>? get fxsData => widget.fxsData;

  late TextEditingController controller;
  late TextEditingController renderer;
  late FocusNode focusNode;
  late List<String> items;
  bool isFocused = false;
  late bool resetEnabled;

  @override
  void initState() {
    super.initState();
    final paramKey = 'haksa/$name';

    if (widget.items != null) {
      items = widget.items!;
    } else {
      if (widget.homeRepo != null) {
        items = widget.homeRepo!.params.keys.contains(paramKey)
            ? [
                if (widgetName == 'search') '/전체',
                ...(widget.homeRepo!.params[paramKey]['children']
                        as Map<String, dynamic>)
                    .entries
                    .map((e) => '${e.key}/${e.value}')
              ]
            : [];
      }
    }

    resetEnabled = enabled;
    controller = TextEditingController(text: widget.initialValue);
    renderer = TextEditingController(text: widget.initialValue);

    focusNode = FocusNode();
    // focusNode.requestFocus(); // initState에서 포커스 요청 시 문제 발생 가능성 제거
    isFocusedChange();
  }

  @override
  void dispose() {
    controller.dispose();
    renderer.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (flag) {
        // print('focus changed-->$name ${controller.text} $flag');

        isFocusedChange().then((value) {
          if (mounted) {
            // 위젯이 여전히 트리에 있는지 확인
            setState(() {
              isFocused = flag;
            });
          }
        });
      },
      child: Row(
        children: [
          Expanded(
              child: switch (type) {
            FieldType.formula => formula(),
            FieldType.popup => popup(),
            // FieldType.textLabel => textField(type: type, readOnly: true),
            FieldType.imageUrl => imageUrl(),
            FieldType.date => dateTime(type: type),
            FieldType.time => dateTime(type: type),
            FieldType.dateTime => dateTime(type: type),
            FieldType.select => select(),
            FieldType.checkGroup => checkGroup(),
            FieldType.radioGroup => radioGroup(),
            _ => textField(type: type, enabled: enabled),
          }),
        ],
      ),
    );
  }

  // Future<void> isFocusedChange() async {
  //   renderer.text = switch (type) {
  //     FieldType.number =>
  //       NumberFormat(format).format(int.tryParse(controller.text)),
  //     _ => controller.text
  //   };
  // }

  Future<void> isFocusedChange() async {
    // FormulaParser 및 homeRepo.fxs가 제거되었으므로 관련 로직 수정/제거 필요
    // controller.text가 숫자일 때만 NumberFormat 적용하도록 수정
    if (type == FieldType.number &&
        controller.text.isNotEmpty &&
        int.tryParse(controller.text) != null) {
      renderer.text =
          NumberFormat(format).format(int.tryParse(controller.text));
    } else {
      renderer.text = controller.text;
    }
  }

  // Widget formula({bool enabled = true, Icon? suffixIcon}) {
  //   var exp =
  //       FormulaParser(homeRepo.fxs[id]['formula'], jsonDecode(initialValue));
  //   var result = exp.parse;
  //   controller.text = result['value'].toString();

  //   return Row(
  //     key: ValueKey(controller.text),
  //     children: [
  //       Expanded(child: Text(controller.text)),
  //     ],
  //   );
  // }

  Widget formula({bool enabled = true, Icon? suffixIcon}) {
    if (fxsData != null &&
        fxsData!.containsKey(id) &&
        fxsData![id]['formula'] != null) {
      try {
        var exp =
            FormulaParser(fxsData![id]['formula'], jsonDecode(initialValue));
        var result = exp.parse();
        controller.text = result['value'].toString();
      } catch (e) {
        print('Error parsing formula: $e');
        controller.text = 'Error'; // 오류 발생 시 Error 표시
      }
    } else {
      controller.text = initialValue; // fxsData가 없거나 formula 정보가 없으면 초기값 사용
    }

    return Row(
      key: ValueKey(controller.text),
      children: [
        Expanded(
            child: Text(controller.text, textAlign: textAlign)), // textAlign 적용
      ],
    );
  }

  Widget textField(
      {FieldType type = FieldType.text,
      bool readOnly = false,
      bool enabled = true,
      Icon? suffixIcon}) {
    return !isFocused
        ? textLabel(type: type, enabled: enabled, suffixIcon: suffixIcon)
        : FormBuilderTextField(
            name: name,
            controller: controller,
            textAlign: textAlign,
            readOnly: readOnly,
            enabled: enabled,
            obscureText: false, // 'password' 타입은 현재 enum에 없으므로 false로 고정
            autovalidateMode: AutovalidateMode.always,
            validator: typeValidator(type),
            style: fieldStyle(theme, 'textStyle'),
            decoration: InputDecoration(
              labelText: widget.widgetName == 'grid' ? null : labelText,
              suffixIcon: suffixIcon,
              border: widget.widgetName == 'grid' ? InputBorder.none : null,
            ),
            textAlignVertical: TextAlignVertical.top,
            onChanged: (v) {
              if (widget.callback != null) {
                widget.callback?.call(v);
              }
            },
          );
  }

  Widget textLabel(
      {FieldType type = FieldType.text,
      bool enabled = true,
      Icon? suffixIcon}) {
    return FormBuilderTextField(
      key: ValueKey(renderer.text), // controller.text 대신 renderer.text 사용
      name: name,
      controller: renderer,
      textAlign: textAlign,
      readOnly: true,
      enabled: enabled,
      obscureText: false, // 'password' 타입은 현재 enum에 없으므로 false로 고정
      autovalidateMode: null,
      validator: null,
      style: fieldStyle(theme, 'textStyle'),
      decoration: InputDecoration(
        labelText: widget.widgetName == 'grid' ? null : labelText,
        suffixIcon: suffixIcon,
        border: widget.widgetName == 'grid' ? InputBorder.none : null,
      ),
      textAlignVertical: TextAlignVertical.top,
    );
  }

  Widget popup({int? maxLines}) {
    if (widgetName == 'grid') {
      return popupGrid(maxLines: maxLines);
    }

    return InkWell(
        onTap: () => popupOnTap(maxLines: maxLines),
        child: textField(
            type: type,
            enabled: false,
            readOnly: true,
            suffixIcon: format.contains('showAlert')
                ? const Icon(Icons.message, color: Colors.grey)
                : format.contains('textField')
                    ? const Icon(Icons.text_fields, color: Colors.grey)
                    : null));
  }

  Future<void> popupOnTap({int? maxLines, String? url}) async {
    if (!enabled) return;

    if (format.contains('showAlert')) {
      await showOkAlertDialog(
        message: controller.text,
        context: context,
        style: AdaptiveStyle.material,
      );
      if (mounted) {
        setState(() {
          resetEnabled = true;
        });
      }
    }

    if (format.contains('textField')) {
      final result = await showTextInputDialog(
        context: context,
        style: AdaptiveStyle.material,
        textFields: [
          DialogTextField(
              initialText: controller.text, maxLines: maxLines ?? 4),
        ],
      );
      if (mounted && result != null) {
        setState(() {
          controller.text = result.first;
          renderer.text = result.first;
          resetEnabled = true;
          if (widget.callback != null) {
            widget.callback?.call(controller.text);
          }
        });
      }
    }

    if (url != null) {
      await showPopupCard(
        context: context,
        builder: (context) {
          return PopupCard(
            elevation: 8,
            color: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: SizedBox(
              width: 400,
              height: 320,
              child: Image.network(
                _getProxiedImageUrl(url),
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading popup card image: $error - URL: $url');
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'URL: ${url.length > 50 ? '${url.substring(0, 50)}...' : url}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '이미지 로딩 중...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                headers: const {
                  'User-Agent':
                      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
                  'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                  'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
                  'Cache-Control': 'no-cache',
                },
              ),
            ),
          );
        },
        offset: const Offset(-300, 0),
        alignment: Alignment.centerRight,
        useSafeArea: true,
        dimBackground: true,
      );
    }
  }

  Widget popupGrid({int? maxLines}) {
    return InkWell(
      onTap: () => popupOnTap(maxLines: maxLines),
      child: Row(
        children: [
          Expanded(child: Text(controller.text)),
          if (format.contains('showAlert'))
            const Icon(Icons.message, color: Colors.grey),
          if (format.contains('textField'))
            const Icon(Icons.text_fields, color: Colors.grey)
        ],
      ),
    );
  }

  Widget dateTime({FieldType type = FieldType.dateTime}) {
    if (widgetName == 'grid') {
      return dateTimeGrid();
    }

    return FormBuilderDateTimePicker(
      name: name,
      controller: controller,
      enabled: enabled,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.day,
      initialValue: DateTime.tryParse(initialValue) ?? DateTime.now(),
      inputType: switch (type) {
        FieldType.date => InputType.date,
        FieldType.time => InputType.time,
        _ => InputType.both,
      },
      format: DateFormat(format.isEmpty ? 'yyyy-MM-dd' : format),
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: IconButton(
          icon: Icon(
              format.contains('HH') ? Icons.access_time : Icons.calendar_month),
          onPressed: () {
            // _formKey.currentState!.fields['date']?.didChange(null);
          },
        ),
      ),
      onChanged: (v) {
        if (widget.callback != null) {
          widget.callback?.call(v.toString());
        }
      },
    );
  }

  Widget dateTimeGrid() {
    return FormBuilderDateTimePicker(
      name: name,
      controller: controller,
      enabled: enabled,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.day,
      initialValue: DateTime.tryParse(initialValue) ?? DateTime.now(),
      inputType: format.contains('HH') ? InputType.both : InputType.date,
      format: DateFormat(format.isEmpty ? 'yyyy-MM-dd' : format),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: Icon(
              format.contains('HH') ? Icons.access_time : Icons.calendar_month),
          onPressed: () {
            // _formKey.currentState!.fields['date']?.didChange(null);
          },
        ),
      ),
      onChanged: (v) {
        if (widget.callback != null) {
          widget.callback?.call(v.toString());
        }
      },
    );
  }

  /// S3 이미지 로딩 실패 시 대체 방법을 제공
  Widget _buildFallbackImage(String originalUrl, String errorType) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(errorType == '403' ? Icons.lock : Icons.broken_image,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              errorType == '403' ? 'S3 접근 권한이 없습니다' : '이미지를 불러올 수 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          if (originalUrl.contains('s3.amazonaws.com'))
            Text(
              'S3 설정을 확인해주세요',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          // 재시도 버튼 추가
          ElevatedButton(
            onPressed: () {
              setState(() {
                // 상태를 새로고침하여 이미지 재로딩 시도
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100],
              foregroundColor: Colors.blue[700],
              minimumSize: const Size(80, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text(
              '재시도',
              style: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 4),
          // S3 403 오류인 경우 추가 안내
          if (errorType == '403')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'S3 버킷 정책 확인 필요',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget imageUrl() {
    String url;

    if (initialValue.isEmpty) {
      url = 'https://via.placeholder.com/150';
    } else if (initialValue.startsWith('http://') ||
        initialValue.startsWith('https://')) {
      // 모든 외부 이미지 URL에 대해 CORS 문제 해결을 위해 프록시 사용
      url = 'https://corsproxy.io/?${Uri.encodeComponent(initialValue)}';
    } else if (initialValue.startsWith('/')) {
      // 상대 경로인 경우 환경에 맞는 S3 URL 사용
      try {
        // imgUrl이 /template-images/... 형태로 전달됨
        // /static/upload 경로 제거 로직은 불필요
        String cleanPath = initialValue;

        url = '${AppConfig.instance.s3ImageBaseUrl}$cleanPath';
        print('Constructed S3 URL: $url'); // 디버깅용 로그
      } catch (e) {
        print('Error constructing S3 URL: $e');
        url = 'https://via.placeholder.com/150';
      }
    } else {
      // 기타 경우 기본 이미지 사용
      url = 'https://via.placeholder.com/150';
    }

    if (format == 'showPopup') {
      return popupImage(url: url);
    }

    // S3 이미지 로딩을 위한 개선된 에러 처리
    return Image.network(
      url,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error - URL: $url');

        // S3 403 오류인 경우 사용자에게 안내
        String errorType = 'unknown';
        if (error.toString().contains('403') ||
            error.toString().contains('Forbidden')) {
          errorType = '403';
          // S3 접근 실패 시 로그에 상세 정보 출력
          print(
              'S3 Access Denied - Bucket: i-dev-template-images, Path: $initialValue');
          print('Suggestion: Check S3 bucket policy and CORS settings');
        } else if (error.toString().contains('404') ||
            error.toString().contains('Not Found')) {
          errorType = '404';
        }

        return _buildFallbackImage(url, errorType);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  '로딩 중...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        'Cache-Control': 'no-cache',
        'Referer': 'http://localhost:59141/', // 로컬 개발 환경 referer 추가
      },
      // S3 이미지 로딩을 위한 추가 설정
      fit: BoxFit.cover,
      cacheWidth: 300, // 메모리 사용량 최적화
      cacheHeight: 300,
    );
  }

  Widget popupImage({String? url}) {
    return InkWell(
      onTap: () => popupOnTap(url: url),
      child: Row(
        children: [
          Expanded(
              child: url != null && url.isNotEmpty
                  ? SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.network(
                        _getProxiedImageUrl(url),
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              'Error loading popup image: $error - URL: $url');
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 32, color: Colors.grey[400]),
                                const SizedBox(height: 4),
                                Text(
                                  '이미지 오류',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        headers: const {
                          'User-Agent':
                              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
                          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                          'Accept-Language':
                              'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
                          'Cache-Control': 'no-cache',
                        },
                      ),
                    )
                  : Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 32, color: Colors.grey[400]),
                          const SizedBox(height: 4),
                          Text(
                            '이미지 없음',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )),
          const Icon(Icons.image, color: Colors.grey)
        ],
      ),
    );
  }

  Widget select() {
    if (items.isEmpty && type != FieldType.boolean) {
      return textField(type: FieldType.select);
    }

    if (widgetName == 'grid') {
      return selectGrid();
    }

    return FormBuilderDropdown<String>(
      name: name,
      initialValue: initialValue.isNotEmpty &&
              items.any((item) => item.split('/').first == initialValue)
          ? initialValue
          : null,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
      ),
      elevation: 0,
      dropdownColor: fieldStyle(theme, 'menuBackgroundColor'),
      items: items
          .map((v) => DropdownMenuItem(
                alignment: AlignmentDirectional.centerStart,
                value: v.split('/').first,
                child: Text(
                  v.split('/').last,
                  style: fieldStyle(theme, 'textStyle'),
                ),
              ))
          .toList(),
      onChanged: (v) {
        print('v-->$v');
        if (widget.callback != null) {
          widget.callback?.call(v);
        }
      },
    );
  }

  Widget selectGrid() {
    if (items.isEmpty && type != FieldType.boolean) {
      return textField(type: FieldType.select);
    }

    return FormBuilderDropdown<String>(
      name: name,
      initialValue: initialValue.isNotEmpty &&
              items.any((item) => item.split('/').first == initialValue)
          ? initialValue
          : null,
      enabled: enabled,
      dropdownColor: fieldStyle(theme, 'menuBackgroundColor'),
      decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(top: 0, bottom: 8),
          border: InputBorder.none),
      elevation: 0,
      items: items
          .map((v) => DropdownMenuItem(
                alignment: AlignmentDirectional.centerStart,
                value: v.split('/').first,
                child: Text(
                  v.split('/').last,
                  style: fieldStyle(theme, 'textStyle'),
                ),
              ))
          .toList(),
      onChanged: (v) {
        print('v-->$v');
        if (widget.callback != null) {
          widget.callback?.call(v);
        }
      },
    );
  }

  Widget checkGroup() {
    if (items.isEmpty) {
      return textField(type: FieldType.checkGroup);
    }

    if (widgetName == 'grid') {
      return checkGroupGrid();
    }

    List<String> currentInitialValue = initialValue.isNotEmpty &&
            items.any((item) => item.split('/').first == initialValue)
        ? [initialValue]
        : [];

    return FormBuilderCheckboxGroup<String>(
      name: name,
      initialValue: currentInitialValue,
      enabled: enabled,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: 11, bottom: 0),
        labelText: labelText,
      ),
      options: items
          .map((v) => FormBuilderFieldOption<String>(
              value: v.split('/').first, child: Text(v.split('/').last)))
          .toList(),
      onChanged: (v) {
        if (widget.callback != null) {
          widget.callback?.call(v);
        }
      },
    );
  }

  Widget checkGroupGrid() {
    if (items.isEmpty) {
      return textField(type: FieldType.checkGroup);
    }

    List<String> currentInitialValue = initialValue.isNotEmpty &&
            items.any((item) => item.split('/').first == initialValue)
        ? [initialValue]
        : [];

    return FormBuilderCheckboxGroup<String>(
      name: name,
      initialValue: currentInitialValue,
      enabled: enabled,
      decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(top: 0, bottom: 8),
          border: InputBorder.none),
      options: items
          .map((v) => FormBuilderFieldOption<String>(
              value: v.split('/').first,
              child: Text(v.split('/').last,
                  style: TextStyle(fontSize: gridFontSize))))
          .toList(),
      onChanged: (v) {
        if (widget.callback != null) {
          widget.callback?.call(v);
        }
      },
    );
  }

  Widget radioGroup() {
    if (items.isEmpty) {
      return textField(type: FieldType.radioGroup);
    }

    if (widgetName == 'grid') {
      return radioGroupGrid();
    }

    final String? currentInitialValue = initialValue.isNotEmpty &&
            items.any((item) => item.split('/').first == initialValue)
        ? initialValue
        : null;

    return FormBuilderRadioGroup<String>(
      name: name,
      initialValue: currentInitialValue,
      enabled: enabled,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: 11, bottom: 0),
        labelText: labelText,
      ),
      options: items
          .map((v) => FormBuilderFieldOption<String>(
              value: v.split('/').first, child: Text(v.split('/').last)))
          .toList(),
      onChanged: (v) {
        if (widget.callback != null) {
          widget.callback?.call(v);
        }
      },
    );
  }

  Widget radioGroupGrid() {
    if (items.isEmpty) {
      return textField(type: FieldType.radioGroup);
    }

    final String? currentInitialValue = initialValue.isNotEmpty &&
            items.any((item) => item.split('/').first == initialValue)
        ? initialValue
        : null;

    return FormBuilderRadioGroup<String>(
      name: name,
      initialValue: currentInitialValue,
      enabled: enabled,
      decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(top: 0, bottom: 8),
          border: InputBorder.none),
      options: items
          .map((v) => FormBuilderFieldOption<String>(
              value: v.split('/').first,
              child: Text(v.split('/').last,
                  style: TextStyle(fontSize: gridFontSize))))
          .toList(),
      onChanged: (v) {
        if (widget.callback != null) {
          widget.callback?.call(v);
        }
      },
    );
  }

  String _getProxiedImageUrl(String originalUrl) {
    // 모든 외부 이미지 URL에 대해 CORS 문제를 해결하기 위한 프록시 URL 생성
    if (originalUrl.startsWith('http://') ||
        originalUrl.startsWith('https://')) {
      // 더 안정적인 프록시 서버 사용
      return 'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}';
    }

    return originalUrl;
  }
}
