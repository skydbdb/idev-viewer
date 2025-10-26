import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/board/dock_board/board_menu.dart';
import 'package:idev_viewer/src/internal/board/core/item_generator.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import 'package:idev_viewer/src/internal/layout/menus/template/template_menu.dart';
import 'package:idev_viewer/src/internal/pms/model/menu.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pluto_menu_bar/pluto_menu_bar.dart';

import '../../repo/home_repo.dart';
import '../helper/color_dialog.dart';

final _isAndroid = defaultTargetPlatform == TargetPlatform.android;
final _isIOS = defaultTargetPlatform == TargetPlatform.iOS;
final _isFuchsia = defaultTargetPlatform == TargetPlatform.fuchsia;
final _isMobileWeb = kIsWeb && (_isAndroid || _isIOS || _isFuchsia);
final _isMobileApp = !kIsWeb && (_isAndroid || _isIOS || _isFuchsia);
final _isMobile = _isMobileWeb || _isMobileApp;

class TopTab extends StatefulWidget {
  const TopTab({super.key});

  @override
  State<TopTab> createState() => _TopTabState();
}

class _TopTabState extends State<TopTab> {
  List<PlutoMenuItem> menuItems = [];
  String spaceString = '';
  String copyJsonString = '';
  late HomeRepo homeRepo;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    spaceString = calculateSpaces(context);
    initMenuItems();
  }

  void initMenuItems() {
    menuItems.clear();
    menuItems.addAll(
      [
        PlutoMenuItem(
          title: 'Settings',
          children: [
            PlutoMenuItem(
              title: 'IDE Theme',
              onTap: () async {
                await colorDialog(context, '위젯 테마 설정').then((value) {
                  homeRepo.selectedTheme = value;
                });
              },
            ),
          ],
        ),
        PlutoMenuItem(
          title: spaceString,
        ),
        PlutoMenuItem(title: '', icon: Icons.widgets, children: [
          ...boardIcons.entries.map(
            (e) => PlutoMenuItem(
              title: e.key,
              onTap: () async {
                homeRepo.addWidgetState('${homeRepo.selectedBoardId}#${e.key}');
              },
              icon: e.value,
            ),
          )
        ]),
        PlutoMenuItem(
            title: '',
            icon: Icons.delete,
            onTap: () async {
              await BoardMenu(context: context, homeRepo: homeRepo).deleteAll();
            },
            children: [PlutoMenuItem(title: '위젯삭제')]),
        PlutoMenuItem(title: '  '),
        PlutoMenuItem(
            title: '',
            icon: Symbols.add,
            onTap: () {
              homeRepo.addTabItemState(Menu(menuId: 0));
            },
            children: [PlutoMenuItem(title: 'New Tab')]),
        PlutoMenuItem(
            title: '',
            icon: Icons.copy,
            onTap: () async {
              copyJsonString =
                  await BoardMenu(context: context, homeRepo: homeRepo)
                      .getTemplateJson();
              BoardItemGenerator.setStartCopy(copyJsonString);

              // check test
              await showTextInputDialog(
                context: context,
                style: AdaptiveStyle.material,
                textFields: [
                  DialogTextField(initialText: copyJsonString, maxLines: 10),
                ],
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('복사되었습니다.'),
                ),
              );
            },
            children: [PlutoMenuItem(title: '복사')]),
        PlutoMenuItem(
            title: '',
            icon: Icons.paste,
            onTap: () async {
              if (copyJsonString.isNotEmpty) {
                homeRepo.addJsonMenuState({'script': copyJsonString});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('붙여넣기 되었습니다.'),
                  ),
                );
              } else {
                // check test
                final result = await showTextInputDialog(
                  context: context,
                  style: AdaptiveStyle.material,
                  textFields: [
                    DialogTextField(initialText: copyJsonString, maxLines: 10),
                  ],
                );

                debugPrint('result: $result');

                if (result != null) {
                  homeRepo.addJsonMenuState({'script': result.first});
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('복사한 위젯이 없습니다.'),
                  ),
                );
              }
            },
            children: [PlutoMenuItem(title: '붙여넣기')]),
        PlutoMenuItem(
            title: '',
            icon: Icons.remove_red_eye_outlined,
            onTap: () async {
              String jsonString =
                  await BoardMenu(context: context, homeRepo: homeRepo)
                      .getTemplateJson();
              // debugPrint('preview jsonString: $jsonString');

              Future.delayed(const Duration(seconds: 1), () async {
                await launchTemplate(
                  0,
                  templateNm: 'preview',
                  versionId: homeRepo.versionId,
                  script: jsonString,
                  commitInfo: 'preview',
                );
              });
            },
            children: [PlutoMenuItem(title: '미리보기')]),
      ],
    );
  }

  String calculateSpaces(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width - 140 - (24 * 7);

    TextPainter textPainter = TextPainter(
      text: const TextSpan(text: " ", style: TextStyle(fontSize: 15.0)),
      textDirection: TextDirection.ltr,
    )..layout();

    double spaceWidth = textPainter.width;
    int spaceCount = (screenWidth / spaceWidth).floor();

    return ' ' * spaceCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (calculateSpaces(context).length != spaceString.length) {
      setState(() {
        spaceString = calculateSpaces(context);
        initMenuItems();
      });
    }

    return PlutoMenuBar(
      height: 40,
      mode: _isMobile ? PlutoMenuBarMode.tap : PlutoMenuBarMode.hover,
      menus: menuItems,
      menuPadding: const EdgeInsets.all(3),
      backgroundColor: theme.dialogBackgroundColor,
      menuIconColor: theme.primaryColorLight,
      textStyle: TextStyle(
        color: theme.primaryColorLight,
      ),
    );
  }
}
