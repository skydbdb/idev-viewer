import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/src/const/code.dart';
import '/src/repo/home_repo.dart';

class WidgetMenu extends StatefulWidget {
  const WidgetMenu({super.key});

  @override
  State<WidgetMenu> createState() => _WidgetMenuState();
}

class _WidgetMenuState extends State<WidgetMenu> {
  bool isLoaded = false;
  late HomeRepo homeRepo;

  @override
  void initState() {
    isLoaded = true;
    homeRepo = context.read<HomeRepo>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const SizedBox();
    } else {
      return Column(
        children: [
          SizedBox(
              width: double.infinity,
              child: Theme(
                  data: ThemeData.dark(),
                  child: Container(
                      color: ThemeData.dark().dividerColor,
                      alignment: Alignment.center,
                      height: 20,
                      child: const Text('위젯')))),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Theme(
                  data: ThemeData.dark(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        direction: Axis.horizontal,
                        children: [
                          ...boardIcons.entries.map(
                            (e) => Column(
                              children: [
                                IconButton(
                                    iconSize: 40,
                                    onPressed: () async {
                                      homeRepo.addRightMenuState(
                                          '${homeRepo.selectedBoardId}#${e.key}');
                                    },
                                    icon: e.value),
                                Text(convertWidget(e.key))
                              ],
                            ),
                          ) // e.value)))
                        ]),
                  )),
            ),
          )
        ],
      );
    }
  }
}
