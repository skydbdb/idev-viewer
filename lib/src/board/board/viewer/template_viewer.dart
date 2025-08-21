import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/board/viewer/template_viewer_page.dart';

class TemplateViewer extends StatefulWidget {
  const TemplateViewer({
    super.key,
    required this.boardId,
  });

  final String boardId;

  @override
  State<TemplateViewer> createState() => _TemplateViewerState();
}

class _TemplateViewerState extends State<TemplateViewer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const TemplateViewerPage(
      templateId: 0,
      templateNm: 'preview',
      script: null,
      commitInfo: 'preview',
    );
  }
}
