import 'package:rxdart/rxdart.dart';
import '/src/model/menu.dart'; // For Menu
import '/src/board/core/stack_board_item/stack_item.dart'; // For StackItem
import '/src/board/core/stack_board_item/stack_item_content.dart'; // For StackItemContent

class AppStreams {
  final _tabItem = BehaviorSubject<Menu?>.seeded(null);
  Stream<Menu?> get tabItemStream => _tabItem.stream;
  Menu? get currentTabItemValue => _tabItem.value;
  void addTabItemState(Menu? state) => _tabItem.add(state);

  final _topMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get topMenuStream => _topMenu.stream;
  Map<String, dynamic>? get currentTopMenuValue => _topMenu.value;
  void addTopMenuState(Map<String, dynamic>? state) => _topMenu.add(state);

  final _leftMenu = BehaviorSubject<Menu?>.seeded(null);
  Stream<Menu?> get leftMenuStream => _leftMenu.stream;
  Menu? get currentLeftMenuValue => _leftMenu.value;
  void addLeftMenuState(Menu? state) => _leftMenu.add(state);

  final _rightMenu = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get rightMenuStream => _rightMenu.stream;
  String? get currentRightMenuValue => _rightMenu.value;
  void addRightMenuState(String? state) => _rightMenu.add(state);

  final _jsonMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get jsonMenuStream => _jsonMenu.stream;
  Map<String, dynamic>? get currentJsonMenuValue => _jsonMenu.value;
  void addJsonMenuState(Map<String, dynamic>? state) => _jsonMenu.add(state);

  final _searchApis = BehaviorSubject<List<String>?>.seeded(null);
  Stream<List<String>?> get searchApisStream => _searchApis.stream;
  List<String>? get currentSearchApisValue => _searchApis.value;
  void addSearchApisState(List<String>? state) => _searchApis.add(state);

  final _apiMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get apiMenuStream => _apiMenu.stream;
  Map<String, dynamic>? get currentApiMenuValue => _apiMenu.value;
  void addApiMenuState(Map<String, dynamic>? state) => _apiMenu.add(state);

  final _onTap = BehaviorSubject<StackItem<StackItemContent>?>.seeded(null);
  Stream<StackItem<StackItemContent>?> get onTapStream => _onTap.stream;
  StackItem<StackItemContent>? get currentOnTapValue => _onTap.value;
  void addOnTapState(StackItem<StackItemContent>? state) {
    _onTap.add(state);
  }

  final _onEdit = BehaviorSubject<StackItem<StackItemContent>?>.seeded(null);
  Stream<StackItem<StackItemContent>?> get onEditStream => _onEdit.stream;
  StackItem<StackItemContent>? get currentOnEditValue => _onEdit.value;
  void addOnEditState(StackItem<StackItemContent>? state) {
    _onEdit.add(state);
  }

  final _updateStackItem =
      BehaviorSubject<StackItem<StackItemContent>?>.seeded(null);
  Stream<StackItem<StackItemContent>?> get updateStackItemStream =>
      _updateStackItem.stream;
  StackItem<StackItemContent>? get currentUpdateStackItemValue =>
      _updateStackItem.value;
  void updateStackItemState(StackItem<StackItemContent>? state) {
    _updateStackItem.add(state);
  }

  final _selectRect =
      BehaviorSubject<(double, double, double, double)?>.seeded(null);
  Stream<(double, double, double, double)?> get selectRectStream =>
      _selectRect.stream;
  (double, double, double, double)? get currentSelectRectValue =>
      _selectRect.value;
  void selectRectState((double, double, double, double)? state) {
    _selectRect.add(state);
  }

  final _selectDockBoard = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get selectDockBoardStream => _selectDockBoard.stream;
  String? get currentSelectDockBoardValue => _selectDockBoard.value;
  void selectDockBoardState(String? state) {
    if (currentSelectDockBoardValue == state) {
      return;
    }
    _selectDockBoard.add(state);
  }

  final _changeTab = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get changeTabStream => _changeTab.stream;
  String? get currentChangeTabValue => _changeTab.value;
  void changeTabState(String? state) {
    _changeTab.add(state);
  }

  final _dockStackItem =
      BehaviorSubject<StackItem<StackItemContent>?>.seeded(null);
  Stream<StackItem<StackItemContent>?> get dockStackItemStream =>
      _dockStackItem.stream;
  StackItem<StackItemContent>? get currentDockStackItemValue =>
      _dockStackItem.value;
  void dockStackItemState(StackItem<StackItemContent>? state) =>
      _dockStackItem.add(state);

  final _gridColumnMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get gridColumnMenuStream =>
      _gridColumnMenu.stream;
  Map<String, dynamic>? get currentGridColumnMenuValue => _gridColumnMenu.value;
  void addGridColumnMenuState(Map<String, dynamic>? state) =>
      _gridColumnMenu.add(state);

  void dispose() {
    _tabItem.close();
    _leftMenu.close();
    _rightMenu.close();
    _jsonMenu.close();
    _searchApis.close();
    _apiMenu.close();
    _onTap.close();
    _onEdit.close();
    _updateStackItem.close();
    _selectRect.close();
    _selectDockBoard.close();
    _changeTab.close();
    _dockStackItem.close();
    _gridColumnMenu.close();
  }
}
