class CompactIdGenerator {
  static final Map<String, int> _typeCounters = {};
  static final Map<String, String> _idMapping = {};

  /// 부모 ID와 타입을 기반으로 짧은 ID 생성
  static String generateBoardId(String parentId, String type) {
    final key = '${parentId}_$type';
    final counter = _typeCounters[key] ?? 0;
    _typeCounters[key] = counter + 1;

    // 부모 ID의 해시값을 기반으로 짧은 ID 생성
    final parentHash = _hashString(parentId);
    final shortId = _toBase36(parentHash + counter);

    final fullId = '${type}_$shortId';
    _idMapping[fullId] = '$parentId:$type:$counter';

    return fullId;
  }

  /// 아이템 ID 생성
  static String generateItemId(String itemType) {
    final counter = _typeCounters[itemType] ?? 0;
    _typeCounters[itemType] = counter + 1;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = _hashString('$itemType$timestamp');
    final shortId = _toBase36(hash);

    final itemType0 = itemType.replaceAll('Stack', '').replaceAll('Item', '');
    final fullId = '${itemType0}_$shortId';

    return fullId;
  }

  /// Layout 내부 DockBoard ID 생성
  static String generateLayoutBoardId(
      String layoutItemId, String type, String menuId) {
    // type: 'body' 또는 'subBody'
    // menuId: 'home', 'settings' 등
    final shortId = _toBase36(_hashString('$layoutItemId$type$menuId'));
    final fullId = '${type}_$shortId';

    // 매핑 등록 (부모는 layoutItemId)
    _idMapping[fullId] = '$layoutItemId:$type:$menuId';

    return fullId;
  }

  /// Frame 내부 DockBoard ID 생성 (기존 Frame_xxx_tabIndex 규칙 유지)
  static String generateFrameBoardId(String frameItemId, int index) {
    // frameItemId가 이미 Frame_으로 시작하는 경우 중복 방지
    final baseId =
        frameItemId.startsWith('Frame_') ? frameItemId : 'Frame_$frameItemId';

    final fullId = '${baseId}_$index';

    // 매핑 등록 (부모는 frameItemId)
    _idMapping[fullId] = '$frameItemId:frame:$index';

    return fullId;
  }

  /// Frame tab의 고유 식별자 생성
  static String generateFrameTabUniqueId(
      int tabIndex, double weight, int areaIndex) {
    final weightRounded = (weight * 1000000).round();
    final areaIndexStr = areaIndex.toString().padLeft(3, '0');
    final tabIndexStr = tabIndex.toString().padLeft(3, '0');
    return 'tab_${tabIndexStr}_${weightRounded}_$areaIndexStr';
  }

  /// 고유 식별자에서 tabIndex 추출
  static int? extractTabIndexFromUniqueId(String uniqueId) {
    try {
      final parts = uniqueId.split('_');
      if (parts.length >= 2) {
        return int.tryParse(parts[1]);
      }
    } catch (e) {
      // 오류 무시
    }
    return null;
  }

  /// 고유 식별자에서 weight 추출
  static double? extractWeightFromUniqueId(String uniqueId) {
    try {
      final parts = uniqueId.split('_');
      if (parts.length >= 3) {
        final weightRounded = int.tryParse(parts[2]);
        if (weightRounded != null) {
          return weightRounded / 1000000.0;
        }
      }
    } catch (e) {
      // 오류 무시
    }
    return null;
  }

  /// 문자열을 해시값으로 변환
  static int _hashString(String input) {
    return input.codeUnits
        .fold(0, (hash, char) => ((hash << 5) - hash + char) & 0xFFFFFFFF);
  }

  /// 숫자를 base36으로 변환 (0-9, a-z)
  static String _toBase36(int number) {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    if (number == 0) return '0';

    String result = '';
    while (number > 0) {
      result = chars[number % 36] + result;
      number ~/= 36;
    }
    return result;
  }

  /// ID에서 부모 정보 추출
  static String? getParentInfo(String id) {
    return _idMapping[id];
  }

  /// 카운터 초기화 (테스트용)
  static void resetCounters() {
    _typeCounters.clear();
    _idMapping.clear();
  }
}
