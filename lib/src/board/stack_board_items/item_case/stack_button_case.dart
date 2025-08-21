import 'dart:async';

import 'package:flutter/material.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/repo/app_streams.dart';
import 'package:idev_v1/src/theme/theme_field.dart';
import '/src/board/stack_board_items/items/stack_button_item.dart';
import '/src/board/board/viewer/template_launcher.dart';
import '/src/layout/menus/api/api_popup_dialog.dart';
import '/src/layout/helper/launch_url.dart';
import '/src/repo/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late AppStreams appStreams;
  late StreamSubscription _updateStackItemSub;

  @override
  void initState() {
    currentItem = widget.item;
    theme = currentItem.theme;
    appStreams = sl<AppStreams>();
    _subscribeUpdateStackItem();
    super.initState();
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
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
    super.dispose();
  }

  @override
  void didUpdateWidget(StackButtonCase oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    if (apiId != null && apiId.isNotEmpty) {
      try {
        final homeRepo = context.read<HomeRepo>();

        final dialog = ApiPopupDialog(
          context: context,
          homeRepo: homeRepo,
        );

        await dialog.showApiDialog(apiId: apiId);
      } catch (e) {
        _showErrorSnackBar('An error occurred during API execution: $e');
      }
    } else {
      _showErrorSnackBar('API ID is not set.');
    }
  }

  Future<void> _handleUrlAction() async {
    final url = currentItem.content?.url;

    if (url != null && url.isNotEmpty) {
      try {
        launchUrl(url);
      } catch (e) {
        _showErrorSnackBar('An error occurred during URL execution: $e');
      }
    } else {
      _showErrorSnackBar('URL is not set.');
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
        _showErrorSnackBar('An error occurred during template execution: $e');
      }
    } else {
      _showErrorSnackBar('Template ID is not set.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getButtonText() {
    final buttonName = currentItem.content?.buttonName;
    if (buttonName != null && buttonName.isNotEmpty) {
      return buttonName;
    }

    return '실행';
  }

  IconData _getButtonIcon() {
    final buttonType = currentItem.content?.buttonType ?? 'template';
    switch (buttonType) {
      case 'api':
        return Icons.api;
      case 'url':
        return Icons.link;
      case 'template':
        return Icons.play_arrow;
      default:
        return Icons.play_arrow;
    }
  }

  Color _getBorderColor() {
    final buttonType = currentItem.content?.buttonType ?? 'template';
    switch (buttonType) {
      case 'api':
        return Colors.orange.shade300;
      case 'url':
        return Colors.green.shade300;
      case 'template':
        return Colors.blue.shade300;
      default:
        return Colors.blue.shade300;
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
        decoration: BoxDecoration(
          color: fieldStyle(theme, 'backgroundColor'),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getBorderColor()),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getButtonIcon(),
              color: _getIconColor(),
            ),
            const SizedBox(width: 4), // Reduced from 8 to 4
            Flexible(
              child: Text(
                _getButtonText(),
                style: fieldStyle(theme, 'textStyle'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
