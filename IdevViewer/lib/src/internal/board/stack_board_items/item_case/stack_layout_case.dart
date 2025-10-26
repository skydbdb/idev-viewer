import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/board/dock_board.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/common/models/menu_config.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/theme/theme_layout.dart';
import 'package:idev_viewer/src/internal/adaptive_scaffold/adaptive_scaffold.dart';
import 'package:idev_viewer/src/internal/board/stack_items.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import '../../helpers/compact_id_generator.dart';

class StackLayoutCase extends StatefulWidget {
  const StackLayoutCase({super.key, required this.item});

  final StackLayoutItem item;

  @override
  State<StackLayoutCase> createState() => _StackLayoutCaseState();
}

class _StackLayoutCaseState extends State<StackLayoutCase> {
  final int _transitionDuration = 1000;
  late int _selectedIndex;
  late String title;
  late String profile;
  late String appBar;
  late String actions;
  late String drawer;
  late String subBody;
  late String leftNavigation;
  late String rightNavigation;
  late String topNavigation;
  late String bottomNavigation;
  late double bodyRatio;
  late Axis bodyOrientation;
  late String subBodyOptions;
  bool isActivedDetail = false;
  List<MenuConfig> reqMenus = [];
  late List<NavigationDestination> destinations;
  late TextDirection textDirection;
  late final StreamSubscription _updateStackItemSub;
  late HomeRepo homeRepo;
  AppStreams? appStreams;
  late String theme;
  late StackLayoutItem currentItem;

  // 스트림 구독을 저장할 변수 추가
  late StreamSubscription _rowResponseSub;

  // 상세 모드 상태 추가
  bool _isDetailMode = false;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
    _initStateSettings();
  }

  @override
  void dispose() {
    _rowResponseSub.cancel();
    // 뷰어 모드에서는 구독이 없을 수 있음
    if (BuildMode.isEditor && appStreams != null) {
      _updateStackItemSub.cancel();
    }
    super.dispose();
  }

  void _initStateSettings() {
    currentItem = widget.item;
    theme = currentItem.theme;
    final LayoutItemContent content = currentItem.content!;

    if (content.reqMenus == null || content.reqMenus!.isEmpty) {
      reqMenus = _initReqMenus();
      currentItem =
          currentItem.copyWith(content: content.copyWith(reqMenus: reqMenus));
      homeRepo.hierarchicalControllers[currentItem.boardId]?.controller
          .updateItem(currentItem);
      homeRepo.addOnTapState(currentItem);
    } else {
      reqMenus = content.reqMenus!;
    }

    // selectedIndex 설정 - 이미 저장된 값이 있으면 우선 사용
    final savedSelectedIndex = content.selectedIndex;
    if (savedSelectedIndex != null && savedSelectedIndex < reqMenus.length) {
      _selectedIndex = savedSelectedIndex;
    } else {
      _selectedIndex = 0;
    }

    // currentItem의 selectedIndex도 동기화
    if (currentItem.content?.selectedIndex != _selectedIndex) {
      currentItem = currentItem.copyWith(
        content: currentItem.content?.copyWith(selectedIndex: _selectedIndex),
      );
    }

    textDirection =
        content.directionLtr == true ? TextDirection.ltr : TextDirection.rtl;
    leftNavigation = content.leftNavigation ?? 'none';
    rightNavigation = content.rightNavigation ?? 'none';
    topNavigation = content.topNavigation ?? 'none';
    bottomNavigation = content.bottomNavigation ?? 'none';
    title = content.title ?? '';
    profile = content.profile ?? '';
    appBar = content.appBar ?? 'none';
    actions = content.actions ?? 'none';
    drawer = content.drawer ?? 'none';
    subBody = content.subBody ?? 'none';
    bodyOrientation = content.bodyOrientation ?? Axis.horizontal;
    subBodyOptions = content.subBodyOptions ?? 'none';
    bodyRatio = content.bodyRatio ?? 0.5;
    _reqMenusDestinations();

    _subscribeRowResponse();
    _subscribeUpdateStackItem();
  }

  void _onMenuSelected(int index) {
    if (index >= 0 && index < reqMenus.length && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
        // currentItem의 selectedIndex도 업데이트하여 위젯 재생성 시에도 올바른 값 유지
        currentItem = currentItem.copyWith(
          content: currentItem.content?.copyWith(selectedIndex: index),
        );

        // homeRepo에 업데이트된 currentItem 저장
        homeRepo.hierarchicalControllers[currentItem.boardId]?.controller
            .updateItem(currentItem);
        homeRepo.addOnTapState(currentItem);
      });
    }
  }

  // 상세 모드 진입 메서드 개선
  void _enterDetailMode(int index) {
    setState(() {
      _selectedIndex = index;
      _isDetailMode = true;
      isActivedDetail = true;
    });
  }

  void _subscribeUpdateStackItem() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _updateStackItemSub = appStreams!.updateStackItemStream.listen((v) {
      if (v?.id == currentItem.id &&
          v is StackLayoutItem &&
          v.boardId == currentItem.boardId) {
        final StackLayoutItem item = v;
        final LayoutItemContent content = item.content!;

        theme = item.theme;
        reqMenus = content.reqMenus ?? _initReqMenus();
        _selectedIndex = content.selectedIndex ?? 0;
        textDirection = content.directionLtr == true
            ? TextDirection.ltr
            : TextDirection.rtl;
        leftNavigation = content.leftNavigation!;
        rightNavigation = content.rightNavigation!;
        topNavigation = content.topNavigation!;
        bottomNavigation = content.bottomNavigation!;
        bodyRatio = content.bodyRatio!;
        title = content.title!;
        profile = content.profile!;
        appBar = content.appBar!;
        actions = content.actions!;
        drawer = content.drawer!;
        subBody = content.subBody!;
        bodyOrientation = content.bodyOrientation!;
        subBodyOptions = content.subBodyOptions!;

        setState(() {
          currentItem = item;
          _reqMenusDestinations();
        });
      }
    });
  }

  void _reqMenusDestinations() {
    destinations = reqMenus
        .map((e) => NavigationDestination(
              icon: iconStringToWidget(e.icon),
              selectedIcon: iconStringToWidget(e.icon),
              label: e.label,
            ))
        .toList();
  }

  List<MenuConfig> _initReqMenus() {
    return [
      MenuConfig.fromJson(
        {
          'menuId': 'home',
          'icon': icons.first['value'],
          'label': icons.first['label']
        },
      )
    ];
  }

  bool isDetailSubBody() {
    if (subBodyOptions == 'detail' && !isActiveBreakpointByName(subBody)) {
      return true;
    }
    return false;
  }

  bool isVerticalSubBody() {
    if (subBodyOptions == 'vertical' && !isActiveBreakpointByName(subBody)) {
      return true;
    }
    return false;
  }

  Breakpoint? getVerticalSubBodyOptions() {
    if (subBodyOptions == 'vertical' && !isActiveBreakpointByName(subBody)) {
      return Breakpoints.smallAndUp;
    }
    return getBreakpointByName(subBody);
  }

  Breakpoint? getDetailSubBodyOptions() {
    if (subBodyOptions == 'detail' && !isActiveBreakpointByName(subBody)) {
      return Breakpoints.smallAndUp;
    }
    return getBreakpointByName(subBody);
  }

  bool isActiveBreakpointByName(String breakpointName) {
    switch (breakpointName) {
      case 'none':
        return false;
      case 'small':
        return Breakpoints.small.isActive(context);
      case 'smallAndUp':
        return Breakpoints.smallAndUp.isActive(context);
      case 'medium':
        return Breakpoints.medium.isActive(context);
      case 'mediumAndUp':
        return Breakpoints.mediumAndUp.isActive(context);
      case 'mediumLarge':
        return Breakpoints.mediumLarge.isActive(context);
      case 'mediumLargeAndUp':
        return Breakpoints.mediumLargeAndUp.isActive(context);
      case 'large':
        return Breakpoints.large.isActive(context);
      case 'largeAndUp':
        return Breakpoints.largeAndUp.isActive(context);
      case 'extraLarge':
        return Breakpoints.extraLarge.isActive(context);
      default:
        return Breakpoints.standard.isActive(context);
    }
  }

  Breakpoint? getBreakpointByName(String breakpointName) {
    switch (breakpointName) {
      case 'none':
        return null;
      case 'small':
        return Breakpoints.small;
      case 'smallAndUp':
        return Breakpoints.smallAndUp;
      case 'medium':
        return Breakpoints.medium;
      case 'mediumAndUp':
        return Breakpoints.mediumAndUp;
      case 'mediumLarge':
        return Breakpoints.mediumLarge;
      case 'mediumLargeAndUp':
        return Breakpoints.mediumLargeAndUp;
      case 'large':
        return Breakpoints.large;
      case 'largeAndUp':
        return Breakpoints.mediumLargeAndUp;
      case 'extraLarge':
        return Breakpoints.extraLarge;
      default:
        return Breakpoints.standard;
    }
  }

  SlotLayout leftRightNavigation({bool isLeft = false}) {
    final layoutConfig = layoutStyle(theme);
    final breakpointName = isLeft ? leftNavigation : rightNavigation;
    final Breakpoint breakpoint = getBreakpointByName(breakpointName)!;

    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig?>{
        breakpoint: SlotLayout.from(
            key: Key('$isLeft $breakpointName Navigation'),
            outAnimation: AdaptiveScaffold.leftInOut,
            builder: (_) {
              final extended =
                  (MediaQuery.sizeOf(context).width > breakpoint.endWidth!);
              if (!mounted || destinations.isEmpty) {
                return const SizedBox.shrink();
              } else {
                return NavigationRailTheme(
                  data: NavigationRailThemeData(
                    backgroundColor: layoutConfig.drawerBackgroundColor,
                    selectedIconTheme: IconThemeData(
                        color: layoutConfig.drawerSelectedIconColor),
                    unselectedIconTheme: IconThemeData(
                        color: layoutConfig.drawerUnselectedIconColor),
                    selectedLabelTextStyle: TextStyle(
                      color: layoutConfig.drawerSelectedLabelColor,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: layoutConfig.drawerUnselectedLabelColor,
                    ),
                  ),
                  child: AdaptiveScaffold.standardNavigationRail(
                    extended: extended,
                    padding: EdgeInsets.zero,
                    width: extended ? 140 : 70,
                    selectedIndex:
                        _selectedIndex.clamp(0, destinations.length - 1),
                    onDestinationSelected: _onMenuSelected,
                    destinations: destinations
                        .map((d) => NavigationRailDestination(
                              icon: d.icon,
                              selectedIcon: d.selectedIcon,
                              label: Text(d.label),
                            ))
                        .toList(),
                  ),
                );
              }
            })
      },
    );
  }

  SlotLayout topBottomNavigation({bool isTop = false}) {
    final layoutConfig = layoutStyle(theme);
    String breakpointName = isTop ? topNavigation : bottomNavigation;
    final breakpoint = getBreakpointByName(breakpointName);

    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig?>{
        breakpoint!: SlotLayout.from(
          key: Key('${isTop}topBottomNavigation'),
          outAnimation: isTop ? null : AdaptiveScaffold.topToBottom,
          builder: (_) {
            if (destinations.isEmpty) {
              return const SizedBox.shrink();
            }
            return NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: layoutConfig.navigationBackgroundColor,
                indicatorColor: layoutConfig.navigationIndicatorColor,
              ),
              child: AdaptiveScaffold.standardBottomNavigationBar(
                currentIndex: _selectedIndex.clamp(0, destinations.length - 1),
                onDestinationSelected: _onMenuSelected,
                destinations: destinations,
              ),
            );
          },
        )
      },
    );
  }

  void _subscribeRowResponse() {
    _rowResponseSub = homeRepo.rowResponseStream.listen((v) {
      if (v != null) {
        if (isDetailSubBody() && !isActivedDetail) {
          isActivedDetail = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _enterDetailMode(_selectedIndex);
            Future.delayed(const Duration(milliseconds: 300), () {
              homeRepo.addRowRequestState(v);
            });
          });
        }
      }
    });
  }

  // body 위젯을 별도 메서드로 분리 - 키 캐시 사용 및 애니메이션 추가
  Widget _buildBodyContent() {
    if (_isDetailMode) {
      // 상세 모드일 때 단일 페이지 표시
      final menu = reqMenus[_selectedIndex];

      // 새로운 ID 시스템 사용
      final bodyBoardId = CompactIdGenerator.generateLayoutBoardId(
          currentItem.id, 'body', menu.menuId);
      final subBodyBoardId = CompactIdGenerator.generateLayoutBoardId(
          currentItem.id, 'subBody', menu.menuId);

      return Row(
        children: [
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: ValueKey('detail_body_${menu.menuId}'),
              child: DockBoard(
                id: bodyBoardId,
                parentId: currentItem.boardId,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: KeyedSubtree(
              key: ValueKey('detail_subBody_${menu.menuId}'),
              child: DockBoard(
                id: subBodyBoardId,
                parentId: currentItem.boardId,
              ),
            ),
          ),
        ],
      );
    } else {
      // 일반 모드일 때 기존 PageView 표시 - 키 캐시 사용
      return IndexedStack(
        index: _selectedIndex,
        children: reqMenus.map((menu) {
          // 새로운 ID 시스템 사용
          final dockBoardId = CompactIdGenerator.generateLayoutBoardId(
              currentItem.id, 'body', menu.menuId);

          return KeyedSubtree(
            key: ValueKey('body_${currentItem.id}_${menu.menuId}'),
            child: DockBoard(
              id: dockBoardId,
              parentId: currentItem.boardId, // 최상위 보드 ID를 parentId로 전달
            ),
          );
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutConfig = layoutStyle(theme);

    // currentItem에서 직접 selectedIndex 가져오기 (위젯 재생성 시에도 올바른 값 유지)
    final currentSelectedIndex = currentItem.content?.selectedIndex ?? 0;
    if (currentSelectedIndex != _selectedIndex) {
      _selectedIndex = currentSelectedIndex;
    }

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: layoutConfig.scaffoldBackgroundColor,
        appBar: isActiveBreakpointByName(appBar)
            ? AppBar(
                backgroundColor: layoutConfig.appBarBackgroundColor,
                foregroundColor: layoutConfig.appBarForegroundColor,
                elevation: layoutConfig.appBarElevation,
                shadowColor: layoutConfig.appBarShadowColor,
                title: title.isNotEmpty ? Text(title) : null,
                toolbarHeight: 40,
                actions: isActiveBreakpointByName(actions)
                    ? destinations
                        .map((d) => Tooltip(
                              message: d.label,
                              child: IconButton(
                                onPressed: () {
                                  final index = destinations.indexOf(d);
                                  _onMenuSelected(index);
                                },
                                icon: d.icon,
                                color: layoutConfig.appBarForegroundColor,
                              ),
                            ))
                        .toList()
                    : null,
              )
            : null,
        drawer: isActiveBreakpointByName(drawer)
            ? Drawer(
                backgroundColor: layoutConfig.drawerBackgroundColor,
                child: destinations.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/idev.jpeg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  profile,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          Expanded(
                              child: NavigationRailTheme(
                            data: NavigationRailThemeData(
                              backgroundColor:
                                  layoutConfig.drawerBackgroundColor,
                              selectedIconTheme: IconThemeData(
                                  color: layoutConfig.drawerSelectedIconColor),
                              unselectedIconTheme: IconThemeData(
                                  color:
                                      layoutConfig.drawerUnselectedIconColor),
                              selectedLabelTextStyle: TextStyle(
                                color: layoutConfig.drawerSelectedLabelColor,
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelTextStyle: TextStyle(
                                color: layoutConfig.drawerUnselectedLabelColor,
                              ),
                            ),
                            child: AdaptiveScaffold.standardNavigationRail(
                              extended: true,
                              padding: EdgeInsets.zero,
                              selectedIndex: _selectedIndex.clamp(
                                  0, destinations.length - 1),
                              onDestinationSelected: _onMenuSelected,
                              destinations: destinations
                                  .map((d) => NavigationRailDestination(
                                        icon: d.icon,
                                        selectedIcon: d.selectedIcon,
                                        label: Text(d.label),
                                      ))
                                  .toList(),
                            ),
                          )),
                        ],
                      ),
              )
            : null,
        body: AdaptiveLayout(
          transitionDuration: Duration(milliseconds: _transitionDuration),
          bodyOrientation:
              isVerticalSubBody() ? Axis.vertical : bodyOrientation,
          bodyRatio: bodyRatio,
          body: SlotLayout(
            config: <Breakpoint, SlotLayoutConfig>{
              Breakpoints.smallAndUp: SlotLayout.from(
                key: const Key('body smallAndUp'),
                builder: (_) => _buildBodyContent(),
              ),
            },
          ),
          secondaryBody: subBody != 'none'
              ? SlotLayout(
                  config: <Breakpoint, SlotLayoutConfig>{
                    getVerticalSubBodyOptions()!: SlotLayout.from(
                      key: Key('Sub Body $subBody'),
                      builder: (_) {
                        return IndexedStack(
                          index: _selectedIndex,
                          children: reqMenus.map((menu) {
                            // 새로운 ID 시스템 사용
                            final subBodyBoardId =
                                CompactIdGenerator.generateLayoutBoardId(
                                    currentItem.id, 'subBody', menu.menuId);

                            return KeyedSubtree(
                              key: ValueKey(
                                  'subBody_${currentItem.id}_${menu.menuId}'),
                              child: DockBoard(
                                id: subBodyBoardId,
                                parentId: currentItem
                                    .boardId, // 최상위 보드 ID를 parentId로 전달
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  },
                )
              : null,
          primaryNavigation: leftNavigation != 'none'
              ? leftRightNavigation(isLeft: true)
              : null,
          secondaryNavigation: rightNavigation != 'none'
              ? leftRightNavigation(isLeft: false)
              : null,
          topNavigation:
              topNavigation != 'none' ? topBottomNavigation(isTop: true) : null,
          bottomNavigation: bottomNavigation != 'none'
              ? topBottomNavigation(isTop: false)
              : null,
        ),
      ),
    );
  }
}
