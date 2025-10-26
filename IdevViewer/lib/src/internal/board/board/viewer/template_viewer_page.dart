import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import '../../board/dock_board.dart';

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
  HomeRepo? homeRepo;

  @override
  void initState() {
    super.initState();

    try {
      homeRepo = context.read<HomeRepo>();
    } catch (e) {
      homeRepo = null;
    }

    // 이전 템플릿 상세 팝업 컨트롤러 정리
    _clearPreviousTemplateViewer();

    // 템플릿 상세 팝업에서 JSON 스트림 트리거
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (widget.script != null &&
            widget.script!.isNotEmpty &&
            homeRepo != null) {
          homeRepo!.addJsonMenuState({
            'templateId': widget.templateId,
            'templateNm': widget.templateNm,
            'versionId': 1,
            'script': widget.script,
            'commitInfo': widget.commitInfo ?? 'Preview',
          });
        }
      });
    });
  }

  void _clearPreviousTemplateViewer() {
    // 이전 템플릿 상세 팝업 컨트롤러가 있으면 정리
    if (homeRepo?.hierarchicalControllers.containsKey('template_viewer') ==
        true) {
      homeRepo!.hierarchicalControllers.remove('template_viewer');
    }
  }

  @override
  void dispose() {
    // 템플릿 상세 팝업이 닫힐 때 컨트롤러 정리
    if (homeRepo?.hierarchicalControllers.containsKey('template_viewer') ==
        true) {
      homeRepo!.hierarchicalControllers.remove('template_viewer');
    }
    super.dispose();
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
    // DockBoard가 JSON 스트림을 구독하므로 항상 생성
    return DockBoard(
      id: 'template_viewer',
      key: ValueKey('template_viewer_${widget.templateId}'),
    );
  }
}
