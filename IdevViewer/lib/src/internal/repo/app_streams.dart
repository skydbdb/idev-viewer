import 'package:rxdart/rxdart.dart';
import 'package:idev_viewer/src/internal/pms/model/menu.dart'; // For Menu
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart'; // For StackItem
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart'; // For StackItemContent

class AppStreams {
  // final _tabItem = BehaviorSubject<Menu?>.seeded(null);
  // Stream<Menu?> get tabItemStream => _tabItem.stream;
  // Menu? get currentTabItemValue => _tabItem.value;
  // void addTabItemState(Menu? state) => _tabItem.add(state);

  final _selectDockBoard = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get selectDockBoardStream => _selectDockBoard.stream;
  String? get currentSelectDockBoardValue => _selectDockBoard.value;
  void selectDockBoardState(String? state) {
    if (currentSelectDockBoardValue == state) {
      return;
    }
    _selectDockBoard.add(state);
  }

  final _topMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get topMenuStream => _topMenu.stream;
  Map<String, dynamic>? get currentTopMenuValue => _topMenu.value;
  void addTopMenuState(Map<String, dynamic>? state) => _topMenu.add(state);

  final _widget = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get widgetStream => _widget.stream;
  String? get currentRightMenuValue => _widget.value;
  void addWidgetState(String? state) => _widget.add(state);

  final _onTap = BehaviorSubject<StackItem<StackItemContent>?>.seeded(null);
  Stream<StackItem<StackItemContent>?> get onTapStream => _onTap.stream;
  StackItem<StackItemContent>? get currentOnTapValue => _onTap.value;
  void addOnTapState(StackItem<StackItemContent>? state) => _onTap.add(state);

  final _updateStackItem =
      BehaviorSubject<StackItem<StackItemContent>?>.seeded(null);
  Stream<StackItem<StackItemContent>?> get updateStackItemStream =>
      _updateStackItem.stream;
  StackItem<StackItemContent>? get currentUpdateStackItemValue =>
      _updateStackItem.value;
  void updateStackItemState(StackItem<StackItemContent>? state) =>
      _updateStackItem.add(state);

  final _selectRect =
      BehaviorSubject<(double, double, double, double)?>.seeded(null);
  Stream<(double, double, double, double)?> get selectRectStream =>
      _selectRect.stream;
  (double, double, double, double)? get currentSelectRectValue =>
      _selectRect.value;
  void selectRectState((double, double, double, double)? state) =>
      _selectRect.add(state);

  final _changeTab = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get changeTabStream => _changeTab.stream;
  String? get currentChangeTabValue => _changeTab.value;
  void changeTabState(String? state) => _changeTab.add(state);

  final _gridColumnMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get gridColumnMenuStream =>
      _gridColumnMenu.stream;
  Map<String, dynamic>? get currentGridColumnMenuValue => _gridColumnMenu.value;
  void addGridColumnMenuState(Map<String, dynamic>? state) =>
      _gridColumnMenu.add(state);

  void dispose() {
    //_tabItem.close();
    _selectDockBoard.close();
    _topMenu.close();
    _widget.close();
    _onTap.close();
    _updateStackItem.close();
    _selectRect.close();
    _changeTab.close();
    _gridColumnMenu.close();
  }
}
