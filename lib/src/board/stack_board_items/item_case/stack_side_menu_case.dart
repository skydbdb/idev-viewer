import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import '/src/board/stack_items.dart';
import '/src/repo/app_streams.dart';

class StackSideMenuCase extends StatefulWidget {
  const StackSideMenuCase({super.key, required this.item});

  final StackSideMenuItem item;

  @override
  State<StackSideMenuCase> createState() => _StackSideMenuCaseState();
}

class _StackSideMenuCaseState extends State<StackSideMenuCase> {
  late final StreamSubscription _updateStackItemSub;
  late HomeRepo homeRepo;
  late AppStreams appStreams;

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
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
    appStreams = sl<AppStreams>();

    _subscribeUpdateStackItem();
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Body'));
  }
}
