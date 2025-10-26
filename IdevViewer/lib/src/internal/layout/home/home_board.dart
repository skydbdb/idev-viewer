import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/board/board/viewer/template_viewer.dart';
import 'package:idev_viewer/src/internal/core/api/api_endpoint_ide.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '../../pms/model/menu.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';

class HomeBoard extends StatefulWidget {
  const HomeBoard({super.key});

  @override
  HomeBoardState createState() => HomeBoardState();
}

class HomeBoardState extends State<HomeBoard> {
  late HomeRepo homeRepo;
  bool _isInitialized = false; // 중복 초기화 방지 플래그

  @override
  void initState() {
    super.initState();

    // 중복 초기화 방지
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    homeRepo = context.read<HomeRepo>();
    homeRepo.eventStreamController =
        PlutoLayout.getEventStreamController(context);
    homeRepo.eventStreamController?.listen((tab) {
      if (tab is PlutoInsertTabItemEvent &&
          tab.layoutId == PlutoLayoutId.body) {
        print('insert--> systemMenu bodyTab: ${tab.itemResolver}');
      }
      if (tab is PlutoRemoveTabItemEvent &&
          tab.layoutId == PlutoLayoutId.body) {
        print('remove--> systemMenu bodyTab: ${tab.itemId}');
        homeRepo.tabs.remove(tab.itemId);
      }
    });

    if (BuildMode.isEditor) {
      homeRepo.addTabItemState(Menu(menuId: 0));
    }

    // String userId = '202205104';
    int versionId = 7;
    int domainId = 10001;

    // homeRepo.userId = userId;
    homeRepo.domainId = domainId;
    homeRepo.versionId = versionId;

    if (mounted) {
      // API 초기화는 한 번만 실행
      homeRepo.reqIdeApi('get', ApiEndpointIDE.apis);
      homeRepo.reqIdeApi('get', ApiEndpointIDE.params);
      // homeRepo.reqIdeApi('get', ApiEndpointIDE.versions);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeBoard oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // return const PlutoLayoutTabsOrChild();
    return BuildMode.isEditor
        ? const PlutoLayoutTabsOrChild()
        : const TemplateViewer(
            key: GlobalObjectKey('NewTab_1'),
            boardId: 'new_1',
          );
  }
}
