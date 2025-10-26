import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/board/stack_items.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';

class StackSideMenuCase extends StatefulWidget {
  const StackSideMenuCase({super.key, required this.item});

  final StackSideMenuItem item;

  @override
  State<StackSideMenuCase> createState() => _StackSideMenuCaseState();
}

class _StackSideMenuCaseState extends State<StackSideMenuCase> {
  late final StreamSubscription _updateStackItemSub;
  late HomeRepo homeRepo;
  AppStreams? appStreams;

  void _subscribeUpdateStackItem() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _updateStackItemSub = appStreams!.updateStackItemStream.listen((v) {
      if (v == null) {
        return;
      }
      final StackItem<StackItemContent> item = v;
      if (item.id == widget.item.id) {
        setState(() {
          // final json = item.content?.toJson() ?? {};
          homeRepo.addOnTapState(item);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }

    _subscribeUpdateStackItem();
  }

  @override
  void dispose() {
    // 뷰어 모드에서는 구독이 없을 수 있음
    if (BuildMode.isEditor && appStreams != null) {
      _updateStackItemSub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Body'));
  }
}
