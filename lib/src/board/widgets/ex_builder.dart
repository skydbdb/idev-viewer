import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/src/board/helpers/safe_state.dart';

/// * Simplified `ExValueBuilder`
class ExBuilder<T> extends StatefulWidget {
  const ExBuilder({
    Key? key,
    required this.valueListenable,
    required this.builder,
    this.shouldRebuild,
  })  : child = null,
        childBuilder = null,
        super(key: key);

  const ExBuilder.child({
    Key? key,
    required this.valueListenable,
    required this.childBuilder,
    required this.child,
    this.shouldRebuild,
  })  : builder = null,
        super(key: key);

  final ValueListenable<T> valueListenable;

  final Widget? child;

  final Widget Function(T value)? builder;

  final Widget Function(T value, Widget child)? childBuilder;

  final bool Function(T previous, T next)? shouldRebuild;

  @override
  State<StatefulWidget> createState() => _ExBuilderState<T>();
}

class _ExBuilderState<T> extends State<ExBuilder<T>>
    with SafeState<ExBuilder<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ExBuilder<T> oldWidget) {
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      _value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    if (widget.shouldRebuild?.call(_value, widget.valueListenable.value) ??
        true) {
      safeSetState(() {
        _value = widget.valueListenable.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child == null) {
      return widget.builder?.call(_value) ??
          widget.childBuilder
              ?.call(_value, widget.child ?? const SizedBox.shrink()) ??
          const SizedBox.shrink();
    }

    return widget.childBuilder?.call(_value, widget.child!) ??
        const SizedBox.shrink();
  }
}
