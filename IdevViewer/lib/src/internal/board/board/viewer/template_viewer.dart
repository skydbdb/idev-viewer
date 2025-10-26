import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/board/viewer/template_viewer_page.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';

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
  late HomeRepo homeRepo;

  @override
  void initState() {
    super.initState();
    debugPrint('🎭 [TemplateViewer] initState 시작 - boardId: ${widget.boardId}');

    homeRepo = context.read<HomeRepo>();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎭 [TemplateViewer] build 호출');

    return TemplateViewerPage(
      key: ValueKey('template_viewer_${widget.boardId}'),
      templateId: 0,
      templateNm: 'preview',
      script: null,
      commitInfo: 'preview',
    );
  }
}
