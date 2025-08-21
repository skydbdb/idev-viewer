import 'package:flutter/material.dart';
import 'dart:async';
import 'property_fields.dart';

// copyWith를 key-value로 동적으로 호출하는 헬퍼
T copyWithDynamic<T>(T content, String key, dynamic value) {
  if (content == null) return content;
  final contentMap = (content as dynamic).toJson() as Map<String, dynamic>?;
  if (contentMap == null || !contentMap.keys.contains(key)) return content;
  final copyWith = (content as dynamic).copyWith;
  if (copyWith == null) return content;
  return Function.apply(copyWith, [], {Symbol(key): value}) as T;
}

class DynamicTextField extends StatefulWidget {
  final String fieldKey;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final InputDecoration? decoration;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  const DynamicTextField({
    required this.fieldKey,
    required this.initialValue,
    required this.onChanged,
    required this.onSubmitted,
    this.decoration,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    super.key,
  });
  @override
  State<DynamicTextField> createState() => _DynamicTextFieldState();
}

class _DynamicTextFieldState extends State<DynamicTextField> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant DynamicTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 값이 바뀌었을 때만 갱신
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          widget.onChanged(v);
        });
      },
      onSubmitted: (v) {
        _debounce?.cancel();
        widget.onSubmitted(v);
      },
      decoration: widget.decoration,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
    );
  }
}

Widget buildDynamicContentFields<T>(
  BuildContext context,
  T content, {
  required Function(T) onChanged,
}) {
  final contentMap = (content as dynamic)?.toJson() as Map<String, dynamic>?;
  if (contentMap == null) return const Text('content is null');

  void handleChanged(String key, dynamic value) {
    final newContent = copyWithDynamic(content, key, value);
    onChanged(newContent);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: contentMap.entries.map((entry) {
      final key = entry.key;
      final value = entry.value;
      if (value is bool) {
        // Switch: 즉시 onChanged (dock 스타일과 동일하게)
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildStyledSwitch(
            value: value,
            onChanged: (v) {
              handleChanged(key, v);
            },
            label: key,
            context: context,
          ),
        );
      } else {
        // TextField: 커서 튐 방지, 0.5초 디바운스 + 엔터 즉시
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(key, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4.0),
              DynamicTextField(
                fieldKey: key,
                initialValue: value?.toString() ?? '',
                onChanged: (v) => handleChanged(key, v),
                onSubmitted: (v) => handleChanged(key, v),
                decoration: buildInputDecoration(
                  hintText: key,
                  isDense: true,
                ),
              ),
            ],
          ),
        );
      }
    }).toList(),
  );
}

Widget buildGridItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildTextItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildDetailItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildImageItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildTableItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildButtonItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildLayoutItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildFrameItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildSearchItemContent(
  BuildContext context,
  dynamic content, {
  required Function(dynamic) onChanged,
}) {
  return buildDynamicContentFields(context, content, onChanged: onChanged);
}

Widget buildDynamicContentFallback(BuildContext context, dynamic content) {
  return buildDynamicContentFields(context, content, onChanged: (_) {});
}
