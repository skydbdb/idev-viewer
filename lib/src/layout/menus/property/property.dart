import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/src/di/service_locator.dart';
import '/src/repo/home_repo.dart';
import '/src/repo/app_streams.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item.dart';
import 'property_inspector.dart';

class Property extends StatefulWidget {
  const Property({super.key});

  @override
  State<Property> createState() => _PropertyState();
}

class _PropertyState extends State<Property> {
  late HomeRepo homeRepo;
  late AppStreams appStreams;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
  }

  Widget _buildPropertyHeader() {
    return SizedBox(
      width: double.infinity,
      child: Theme(
        data: ThemeData.dark(),
        child: Container(
          color: ThemeData.dark().dividerColor,
          alignment: Alignment.center,
          height: 20,
          child: const Text('속성'),
        ),
      ),
    );
  }

  Widget _buildPropertyContent(
      {required dynamic displayItem, String? currentBoardId}) {
    if (displayItem == null) {
      return const Center(
        child: Text('선택된 아이템이 없거나, 올바른 타입이 아닙니다.'),
      );
    }

    Widget contentWidget;
    if (displayItem is StackItem) {
      contentWidget = PropertyInspector(
        key: ValueKey('property_inspector_${displayItem.hashCode}'),
        selectedItem: displayItem,
      );
    } else {
      contentWidget = const Center(child: Text('표시할 속성이 없습니다.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Theme(
          data: ThemeData.dark(),
          child: contentWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: appStreams.onTapStream,
      builder: (context, snapshot) {
        dynamic displayItem;
        String? currentBoardId;

        final data = snapshot.data;
        if (data is StackItem) {
          displayItem = data;
          currentBoardId = data.boardId;
          homeRepo.currentProperties = displayItem;
        }

        return Column(
          children: [
            _buildPropertyHeader(),
            Expanded(
                child: _buildPropertyContent(
                    displayItem: displayItem, currentBoardId: currentBoardId)),
          ],
        );
      },
    );
  }
}
