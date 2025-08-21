import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item.dart';
import 'package:idev_v1/src/board/stack_items.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Map<String, dynamic> boardIcons = {
  'Text': const Icon(Symbols.text_fields),
  'Image': const Icon(Symbols.image),
  'Search': const Icon(Symbols.search),
  'Button': const Icon(Symbols.smart_button),
  'Grid': const Icon(Symbols.grid_on),
  'Detail': const Icon(Symbols.newsmode),
  'Chart': const Icon(Symbols.bar_chart),
  // 'SideMenu': const Icon(Symbols.toolbar),
  'Template': const Icon(Symbols.dataset_linked),
  'Layout': const Icon(Symbols.view_quilt),
  'Frame': const Icon(Symbols.tab),
  // 'Json': const Icon(Symbols.database_upload),
  // 'Generate': const Icon(Symbols.desktop_landscape_add),
  // 'Delete': const Icon(Symbols.delete),
};

String convertWidget(String key) {
  return switch (key) {
    'Text' => '텍스트',
    'Image' => '이미지',
    'Grid' => '그리드',
    'Frame' => '프레임',
    'Search' => '조회',
    'Button' => '버튼',
    'Detail' => '상세',
    'Layout' => '레이아웃',
    'Chart' => '차트',
    'Template' => '템플릿뷰',
    // 'Json' => '내보내기',
    // 'Delete' => '삭제',
    _ => key
  };
}

String convertType(StackItem item, {bool isEnglish = false}) {
  return switch (item.runtimeType) {
    StackTextItem => isEnglish ? 'StackTextItem' : '텍스트',
    StackImageItem => isEnglish ? 'StackImageItem' : '이미지',
    StackGridItem => isEnglish ? 'StackGridItem' : '그리드',
    StackFrameItem => isEnglish ? 'StackFrameItem' : '프레임',
    StackSearchItem => isEnglish ? 'StackSearchItem' : '조회',
    StackButtonItem => isEnglish ? 'StackButtonItem' : '버튼',
    StackDetailItem => isEnglish ? 'StackDetailItem' : '상세',
    StackLayoutItem => isEnglish ? 'StackLayoutItem' : '레이아웃',
    StackChartItem => isEnglish ? 'StackChartItem' : '차트',
    StackTemplateItem => isEnglish ? 'StackTemplateItem' : '템플릿뷰',
    _ => isEnglish ? 'Unknown' : '기타'
  };
}

bool isStackItemType(StackItem item, String type) {
  return (item.runtimeType is StackTextItem && type == 'StackTextItem') ||
      (item.runtimeType is StackImageItem && type == 'StackImageItem') ||
      (item.runtimeType is StackGridItem && type == 'StackGridItem') ||
      (item.runtimeType is StackFrameItem && type == 'StackFrameItem') ||
      (item.runtimeType is StackSearchItem && type == 'StackSearchItem') ||
      (item.runtimeType is StackButtonItem && type == 'StackButtonItem') ||
      (item.runtimeType is StackDetailItem && type == 'StackDetailItem') ||
      (item.runtimeType is StackLayoutItem && type == 'StackLayoutItem') ||
      (item.runtimeType is StackChartItem && type == 'StackChartItem') ||
      (item.runtimeType is StackTemplateItem && type == 'StackTemplateItem');
}

String convertContentKey(String key) {
  return switch (key) {
    'buttonName' => '버튼명',
    'url' => 'URL',
    'options' => '옵션',
    'chartType' => '차트 타입',
    'dataSource' => '데이터 소스',
    'apiId' => '응답 API ID',
    'reqApis' => '요청 API 설정',
    'xValueMapper' => 'X 값 매핑',
    'yValueMapper' => 'Y 값 매핑',
    'title' => '제목',
    'showLegend' => '범례 표시',
    'showTooltip' => '툴팁 표시',
    'enableZoom' => '확대 가능',
    'enablePan' => '패닝 가능',
    'showDataLabels' => '데이터 레이블 표시',
    'primaryXAxisType' => 'X 축 타입',
    'xAxisLabelFormat' => 'X 축 레이블 포맷',
    'primaryYAxisType' => 'Y 축 타입',
    'yAxisLabelFormat' => 'Y 축 레이블 포맷',
    'selectionType' => '선택 타입',
    'autoScrollingMode' => '자동 스크롤 모드',
    'autoScrollingDelta' => '자동 스크롤 델타',
    'columnGap' => '열 간격',
    'rowGap' => '행 간격',
    'areas' => '영역',
    'columnSizes' => '열 크기',
    'rowSizes' => '행 크기',
    'resApis' => '응답 API 설정',
    'tabsVisible' => '탭 표시',
    'dividerThickness' => '구분선 두께',
    'tabsTitle' => '탭 제목 설정',
    'lastStringify' => '프레임 배열',
    'headerTitle' => '헤더 제목',
    'saveApiId' => '저장 API ID',
    'saveApiParams' => '저장 API 파라미터',
    'colGroups' => '열 그룹',
    'columnAggregate' => '열 집계',
    'groupByColumns' => '그룹 열',
    'columns' => '열',
    'rows' => '행',
    'rowHeight' => '행 높이',
    'mode' => '모드',
    'showRowNum' => '행 번호 표시',
    'enableRowChecked' => '행 체크 가능',
    'showColumn' => '열 표시',
    'enableColumnFilter' => '열 필터 가능',
    'enableColumnAggregate' => '열 집계 가능',
    'showFooter' => '푸터 표시',
    'assetName' => '애셋 이름',
    'color' => '색상',
    'colorBlendMode' => '색상 블렌드 모드',
    'fit' => '이미지 크기 조절',
    'repeat' => '이미지 반복',
    'directionLtr' => '좌우 방향 정렬',
    'bodyOrientation' => '메인 바디 방향',
    'subBodyOptions' => '보조 바디 옵션',
    'profile' => '프로필',
    'appBar' => '앱바',
    'actions' => '앱바 메뉴',
    'drawer' => '드로워',
    'subBody' => '보조 바디',
    'topNavigation' => '상단 네비게이션',
    'leftNavigation' => '왼쪽 네비게이션',
    'rightNavigation' => '오른쪽 네비게이션',
    'bottomNavigation' => '하단 네비게이션',
    'bodyRatio' => '메인 바디 비율',
    'reqMenus' => '요청 메뉴',
    'selectedIndex' => '선택 인덱스',
    'data' => '데이터',
    _ => key
  };
}

List<dynamic> icons = [
  {'value': 'Icons.home', 'label': '홈', 'icon': const Icon(Icons.home)},
  {'value': 'Icons.search', 'label': '검색', 'icon': const Icon(Icons.search)},
  {'value': 'Icons.check', 'label': '확인', 'icon': const Icon(Icons.check)},
  {'value': 'Icons.close', 'label': '닫기', 'icon': const Icon(Icons.close)},
  {
    'value': 'Icons.settings',
    'label': '설정',
    'icon': const Icon(Icons.settings)
  },
  {'value': 'Icons.add', 'label': '추가', 'icon': const Icon(Icons.add)},
  {'value': 'Icons.remove', 'label': '제거', 'icon': const Icon(Icons.remove)},
  {'value': 'Icons.delete', 'label': '삭제', 'icon': const Icon(Icons.delete)},
  {'value': 'Icons.save', 'label': '저장', 'icon': const Icon(Icons.save)},
  {'value': 'Icons.sync', 'label': '동기화', 'icon': const Icon(Icons.sync)},
  {'value': 'Icons.copy', 'label': '복사', 'icon': const Icon(Icons.copy)},
  {'value': 'Icons.paste', 'label': '붙여넣기', 'icon': const Icon(Icons.paste)},
  {'value': 'Icons.upload', 'label': '업로드', 'icon': const Icon(Icons.upload)},
  {
    'value': 'Icons.download',
    'label': '다운로드',
    'icon': const Icon(Icons.download)
  },
  {
    'value': 'Icons.first_page',
    'label': '처음으로',
    'icon': const Icon(Icons.first_page)
  },
  {
    'value': 'Icons.chevron_left',
    'label': '이전',
    'icon': const Icon(Icons.chevron_left)
  },
  {
    'value': 'Icons.chevron_right',
    'label': '다음',
    'icon': const Icon(Icons.chevron_right)
  },
  {
    'value': 'Icons.last_page',
    'label': '끝으로',
    'icon': const Icon(Icons.last_page)
  },
  {'value': 'Icons.person', 'label': '프로필', 'icon': const Icon(Icons.person)},
  {
    'value': 'Icons.dashboard',
    'label': '대시보드',
    'icon': const Icon(Icons.dashboard)
  },
  {'value': 'Icons.list', 'label': '목록', 'icon': const Icon(Icons.list)},
  {'value': 'Icons.menu', 'label': '메뉴', 'icon': const Icon(Icons.menu)},
  {
    'value': 'Icons.help_outline',
    'label': '도움말',
    'icon': const Icon(Icons.help_outline)
  },
];

Icon iconStringToWidget(String? iconStr) {
  try {
    return icons.firstWhere((icon) => icon['value'] == iconStr)['icon'];
  } catch (e) {
    print('icons error-->$e');
  }
  return icons.last['icon'];
}

List<String> breakPoints = [
  'none',
  'small',
  'smallAndUp',
  'medium',
  'mediumAndUp',
  'mediumLarge',
  'mediumLargeAndUp',
  'large',
  'largeAndUp',
  'extraLarge'
];
