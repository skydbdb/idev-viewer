import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_status.dart';
import '../../stack_board_items/item_case/stack_template_case.dart';
import '../../stack_board_items/items/stack_template_item.dart';

class TemplateViewerPage extends StatefulWidget {
  final int templateId;
  final String? templateNm;
  final String? script;
  final String? commitInfo;

  const TemplateViewerPage({
    super.key,
    required this.templateId,
    this.templateNm,
    this.script,
    this.commitInfo,
  });

  @override
  State<TemplateViewerPage> createState() => _TemplateViewerPageState();
}

class _TemplateViewerPageState extends State<TemplateViewerPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(fontFamily: 'SpoqaHanSansNeo', useMaterial3: false),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Theme(
          data: ThemeData.light(),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final templateItem = StackTemplateItem(
      content: TemplateItemContent(
        templateId: widget.templateId,
        templateNm: widget.templateNm ?? 'Template ${widget.templateId}',
        versionId: 1,
        script: widget.script,
        commitInfo: widget.commitInfo ?? 'Preview',
        sizeOption: 'Fit',
      ),
      boardId: 'template_viewer',
      id: 'template_viewer',
      size: const Size(double.infinity, double.infinity),
      offset: Offset.zero,
      status: StackItemStatus.selected,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        StackTemplateCase(
          key: ValueKey('template_viewer_${widget.templateId}'),
          item: templateItem,
        ),
      ],
    );
  }
}
