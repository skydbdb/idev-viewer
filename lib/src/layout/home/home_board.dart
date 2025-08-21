import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/core/api/api_endpoint_ide.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '/src/model/menu.dart';
import '/src/repo/home_repo.dart';

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
    homeRepo.addTabItemState(Menu(menuId: 0));

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
      homeRepo.reqIdeApi('get', ApiEndpointIDE.versions);

      // // 템플릿 미리보기 호출
      // homeRepo.addJsonMenuState({
      //   'templateId': 42,
      //   'templateNm': 'preview',
      //   'versionId': homeRepo.versionId,
      //   'script': jsonString,
      //   'commitInfo': 'preview',
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const PlutoLayoutTabsOrChild();
  }
}
