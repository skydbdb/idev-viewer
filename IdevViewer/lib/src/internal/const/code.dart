import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/stack_items.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Map<String, IconData> boardIcons = {
  'Text': Symbols.text_fields,
  'Image': Symbols.image,
  'Search': Symbols.search,
  'Button': Symbols.smart_button,
  'Grid': Symbols.grid_on,
  'Detail': Symbols.newsmode,
  'Chart': Symbols.bar_chart,
  'Scheduler': Symbols.calendar_month,
  // 'SideMenu': Symbols.toolbar,
  'Template': Symbols.dataset_linked,
  'Layout': Symbols.view_quilt,
  'Frame': Symbols.tab,
};

// String convertWidget(String key) {
//   return switch (key) {
//     'Text' => '텍스트',
//     'Image' => '이미지',
//     'Grid' => '그리드',
//     'Frame' => '프레임',
//     'Search' => '조회',
//     'Button' => '버튼',
//     'Detail' => '상세',
//     'Layout' => '레이아웃',
//     'Chart' => '차트',
//     'Scheduler' => '스케줄러',
//     'Template' => '템플릿뷰',
//     _ => key
//   };
// }

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
    StackSchedulerItem => isEnglish ? 'StackSchedulerItem' : '스케줄러',
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
      (item.runtimeType is StackSchedulerItem &&
          type == 'StackSchedulerItem') ||
      (item.runtimeType is StackTemplateItem && type == 'StackTemplateItem');
}

String convertContentKey(String key) {
  return switch (key) {
    'buttonName' => '버튼명',
    'url' => 'URL',
    'options' => '옵션',
    'chartType' => '차트 타입',
    'dataSource' => '데이터 소스',
    'apiId' => 'API ID',
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
    'viewType' => '뷰 타입',
    'schedules' => '일정',
    'postApiId' => '생성 API ID',
    'putApiId' => '수정 API ID',
    'deleteApiId' => '삭제 API ID',
    _ => key
  };
}

List<dynamic> icons = [
  // 기본 네비게이션/메뉴 관련
  {'value': 'home', 'label': '홈', 'icon': const Icon(Symbols.home)},
  {'value': 'menu', 'label': '메뉴', 'icon': const Icon(Symbols.menu)},
  {
    'value': 'dashboard',
    'label': '대시보드',
    'icon': const Icon(Symbols.dashboard)
  },

  // 데이터/분석 관련
  {'value': 'analytics', 'label': '분석', 'icon': const Icon(Symbols.analytics)},
  {
    'value': 'chart_data',
    'label': '차트',
    'icon': const Icon(Symbols.chart_data)
  },
  {'value': 'table', 'label': '테이블', 'icon': const Icon(Symbols.table)},

  // 사용자/설정 관련
  {'value': 'person', 'label': '프로필', 'icon': const Icon(Symbols.person)},
  {'value': 'settings', 'label': '설정', 'icon': const Icon(Symbols.settings)},
  {
    'value': 'admin_panel_settings',
    'label': '관리자',
    'icon': const Icon(Symbols.admin_panel_settings)
  },

  // 문서/파일 관련
  {
    'value': 'description',
    'label': '문서',
    'icon': const Icon(Symbols.description)
  },
  {'value': 'folder', 'label': '폴더', 'icon': const Icon(Symbols.folder)},
  {
    'value': 'upload_file',
    'label': '파일업로드',
    'icon': const Icon(Symbols.upload_file)
  },

  // 일정/캘린더 관련
  {
    'value': 'calendar_month',
    'label': '달력',
    'icon': const Icon(Symbols.calendar_month)
  },
  {'value': 'event', 'label': '일정', 'icon': const Icon(Symbols.event)},
  {'value': 'schedule', 'label': '스케줄', 'icon': const Icon(Symbols.schedule)},

  // 커뮤니케이션 관련
  {'value': 'mail', 'label': '메일', 'icon': const Icon(Symbols.mail)},
  {'value': 'chat', 'label': '채팅', 'icon': const Icon(Symbols.chat)},
  {
    'value': 'notifications',
    'label': '알림',
    'icon': const Icon(Symbols.notifications)
  },

  // 기타 유틸리티
  {'value': 'search', 'label': '검색', 'icon': const Icon(Symbols.search)},
  {'value': 'help', 'label': '도움말', 'icon': const Icon(Symbols.help)},

  // 추가 차트/분석 아이콘
  {
    'value': 'bar_chart',
    'label': '막대차트',
    'icon': const Icon(Symbols.bar_chart)
  },
  {
    'value': 'pie_chart',
    'label': '원형차트',
    'icon': const Icon(Symbols.pie_chart)
  },
  {
    'value': 'trending_up',
    'label': '상승추세',
    'icon': const Icon(Symbols.trending_up)
  },
  {
    'value': 'trending_down',
    'label': '하락추세',
    'icon': const Icon(Symbols.trending_down)
  },

  // 추가 사용자 관련 아이콘
  {
    'value': 'account_circle',
    'label': '계정',
    'icon': const Icon(Symbols.account_circle)
  },
  {'value': 'group', 'label': '그룹', 'icon': const Icon(Symbols.group)},
  {
    'value': 'supervisor_account',
    'label': '관리자계정',
    'icon': const Icon(Symbols.supervisor_account)
  },

  // 추가 파일 관련 아이콘
  {'value': 'download', 'label': '다운로드', 'icon': const Icon(Symbols.download)},
  {
    'value': 'attach_file',
    'label': '첨부파일',
    'icon': const Icon(Symbols.attach_file)
  },
  {
    'value': 'picture_as_pdf',
    'label': 'PDF',
    'icon': const Icon(Symbols.picture_as_pdf)
  },
  {
    'value': 'insert_drive_file',
    'label': '파일',
    'icon': const Icon(Symbols.insert_drive_file)
  },

  // 추가 일정 관련 아이콘
  {
    'value': 'event_note',
    'label': '이벤트노트',
    'icon': const Icon(Symbols.event_note)
  },
  {'value': 'today', 'label': '오늘', 'icon': const Icon(Symbols.today)},
  {
    'value': 'date_range',
    'label': '날짜범위',
    'icon': const Icon(Symbols.date_range)
  },

  // 추가 커뮤니케이션 아이콘
  {'value': 'message', 'label': '메시지', 'icon': const Icon(Symbols.message)},
  {'value': 'phone', 'label': '전화', 'icon': const Icon(Symbols.phone)},
  {
    'value': 'video_call',
    'label': '영상통화',
    'icon': const Icon(Symbols.video_call)
  },
  {'value': 'call', 'label': '통화', 'icon': const Icon(Symbols.call)},

  // 상태/피드백 아이콘
  {'value': 'info', 'label': '정보', 'icon': const Icon(Symbols.info)},
  {'value': 'warning', 'label': '경고', 'icon': const Icon(Symbols.warning)},
  {'value': 'error', 'label': '오류', 'icon': const Icon(Symbols.error)},
  {
    'value': 'check_circle',
    'label': '완료',
    'icon': const Icon(Symbols.check_circle)
  },
  {'value': 'cancel', 'label': '취소', 'icon': const Icon(Symbols.cancel)},

  // 편집/작업 아이콘
  {'value': 'edit', 'label': '편집', 'icon': const Icon(Symbols.edit)},
  {'value': 'add', 'label': '추가', 'icon': const Icon(Symbols.add)},
  {'value': 'remove', 'label': '제거', 'icon': const Icon(Symbols.remove)},
  {'value': 'delete', 'label': '삭제', 'icon': const Icon(Symbols.delete)},
  {'value': 'save', 'label': '저장', 'icon': const Icon(Symbols.save)},
  {'value': 'refresh', 'label': '새로고침', 'icon': const Icon(Symbols.refresh)},
  {'value': 'undo', 'label': '실행취소', 'icon': const Icon(Symbols.undo)},
  {'value': 'redo', 'label': '다시실행', 'icon': const Icon(Symbols.redo)},

  // 네비게이션 아이콘
  {
    'value': 'arrow_back',
    'label': '뒤로',
    'icon': const Icon(Symbols.arrow_back)
  },
  {
    'value': 'arrow_forward',
    'label': '앞으로',
    'icon': const Icon(Symbols.arrow_forward)
  },
  {
    'value': 'keyboard_arrow_up',
    'label': '위',
    'icon': const Icon(Symbols.keyboard_arrow_up)
  },
  {
    'value': 'keyboard_arrow_down',
    'label': '아래',
    'icon': const Icon(Symbols.keyboard_arrow_down)
  },
  {
    'value': 'keyboard_arrow_left',
    'label': '왼쪽',
    'icon': const Icon(Symbols.keyboard_arrow_left)
  },
  {
    'value': 'keyboard_arrow_right',
    'label': '오른쪽',
    'icon': const Icon(Symbols.keyboard_arrow_right)
  },
  {
    'value': 'first_page',
    'label': '첫페이지',
    'icon': const Icon(Symbols.first_page)
  },
  {
    'value': 'last_page',
    'label': '마지막페이지',
    'icon': const Icon(Symbols.last_page)
  },

  // 비즈니스 아이콘
  {'value': 'business', 'label': '비즈니스', 'icon': const Icon(Symbols.business)},
  {'value': 'work', 'label': '업무', 'icon': const Icon(Symbols.work)},
  {'value': 'inventory', 'label': '재고', 'icon': const Icon(Symbols.inventory)},
  {
    'value': 'shopping_cart',
    'label': '장바구니',
    'icon': const Icon(Symbols.shopping_cart)
  },
  {'value': 'payment', 'label': '결제', 'icon': const Icon(Symbols.payment)},
  {'value': 'receipt', 'label': '영수증', 'icon': const Icon(Symbols.receipt)},
  {'value': 'store', 'label': '상점', 'icon': const Icon(Symbols.store)},

  // 미디어 아이콘
  {'value': 'image', 'label': '이미지', 'icon': const Icon(Symbols.image)},
  {
    'value': 'video_library',
    'label': '비디오',
    'icon': const Icon(Symbols.video_library)
  },
  {
    'value': 'music_note',
    'label': '음악',
    'icon': const Icon(Symbols.music_note)
  },
  {
    'value': 'play_arrow',
    'label': '재생',
    'icon': const Icon(Symbols.play_arrow)
  },
  {'value': 'pause', 'label': '일시정지', 'icon': const Icon(Symbols.pause)},
  {'value': 'stop', 'label': '정지', 'icon': const Icon(Symbols.stop)},
  {'value': 'volume_up', 'label': '볼륨업', 'icon': const Icon(Symbols.volume_up)},
  {
    'value': 'volume_down',
    'label': '볼륨다운',
    'icon': const Icon(Symbols.volume_down)
  },

  // 위치/지도 아이콘
  {
    'value': 'location_on',
    'label': '위치',
    'icon': const Icon(Symbols.location_on)
  },
  {'value': 'map', 'label': '지도', 'icon': const Icon(Symbols.map)},
  {
    'value': 'directions',
    'label': '길찾기',
    'icon': const Icon(Symbols.directions)
  },
  {
    'value': 'navigation',
    'label': '내비게이션',
    'icon': const Icon(Symbols.navigation)
  },
  {'value': 'place', 'label': '장소', 'icon': const Icon(Symbols.place)},

  // 보안 아이콘
  {'value': 'security', 'label': '보안', 'icon': const Icon(Symbols.security)},
  {'value': 'lock', 'label': '잠금', 'icon': const Icon(Symbols.lock)},
  {
    'value': 'lock_open',
    'label': '잠금해제',
    'icon': const Icon(Symbols.lock_open)
  },
  {'value': 'key', 'label': '키', 'icon': const Icon(Symbols.key)},
  {
    'value': 'fingerprint',
    'label': '지문',
    'icon': const Icon(Symbols.fingerprint)
  },

  // 네트워크 아이콘
  {'value': 'wifi', 'label': 'WiFi', 'icon': const Icon(Symbols.wifi)},
  {
    'value': 'bluetooth',
    'label': '블루투스',
    'icon': const Icon(Symbols.bluetooth)
  },
  {'value': 'cloud', 'label': '클라우드', 'icon': const Icon(Symbols.cloud)},
  {'value': 'sync', 'label': '동기화', 'icon': const Icon(Symbols.sync)},
  {
    'value': 'cloud_upload',
    'label': '클라우드업로드',
    'icon': const Icon(Symbols.cloud_upload)
  },
  {
    'value': 'cloud_download',
    'label': '클라우드다운로드',
    'icon': const Icon(Symbols.cloud_download)
  },

  // 기타 유용한 아이콘
  {'value': 'favorite', 'label': '즐겨찾기', 'icon': const Icon(Symbols.favorite)},
  {'value': 'star', 'label': '별', 'icon': const Icon(Symbols.star)},
  {'value': 'bookmark', 'label': '북마크', 'icon': const Icon(Symbols.bookmark)},
  {'value': 'flag', 'label': '깃발', 'icon': const Icon(Symbols.flag)},
  {'value': 'tag', 'label': '태그', 'icon': const Icon(Symbols.tag)},
  {'value': 'label', 'label': '라벨', 'icon': const Icon(Symbols.label)},
  {'value': 'grade', 'label': '등급', 'icon': const Icon(Symbols.grade)},
  {'value': 'thumb_up', 'label': '좋아요', 'icon': const Icon(Symbols.thumb_up)},
  {
    'value': 'thumb_down',
    'label': '싫어요',
    'icon': const Icon(Symbols.thumb_down)
  },

  // 도구 아이콘
  {'value': 'build', 'label': '도구', 'icon': const Icon(Symbols.build)},
  {'value': 'handyman', 'label': '수공구', 'icon': const Icon(Symbols.handyman)},
  {
    'value': 'construction',
    'label': '건설',
    'icon': const Icon(Symbols.construction)
  },
  {
    'value': 'engineering',
    'label': '엔지니어링',
    'icon': const Icon(Symbols.engineering)
  },

  // 교육/학습 아이콘
  {'value': 'school', 'label': '학교', 'icon': const Icon(Symbols.school)},
  {'value': 'book', 'label': '책', 'icon': const Icon(Symbols.book)},
  {
    'value': 'library_books',
    'label': '도서관',
    'icon': const Icon(Symbols.library_books)
  },
  {'value': 'quiz', 'label': '퀴즈', 'icon': const Icon(Symbols.quiz)},

  // 건강/의료 아이콘
  {
    'value': 'health_and_safety',
    'label': '건강안전',
    'icon': const Icon(Symbols.health_and_safety)
  },
  {
    'value': 'medical_services',
    'label': '의료서비스',
    'icon': const Icon(Symbols.medical_services)
  },
  {
    'value': 'local_hospital',
    'label': '병원',
    'icon': const Icon(Symbols.local_hospital)
  },
  {
    'value': 'medication',
    'label': '약물',
    'icon': const Icon(Symbols.medication)
  },

  // 교통 아이콘
  {
    'value': 'directions_car',
    'label': '자동차',
    'icon': const Icon(Symbols.directions_car)
  },
  {'value': 'train', 'label': '기차', 'icon': const Icon(Symbols.train)},
  {'value': 'flight', 'label': '비행기', 'icon': const Icon(Symbols.flight)},
  {
    'value': 'directions_bus',
    'label': '버스',
    'icon': const Icon(Symbols.directions_bus)
  },

  // 날씨 아이콘
  {'value': 'wb_sunny', 'label': '맑음', 'icon': const Icon(Symbols.wb_sunny)},
  {'value': 'cloud', 'label': '구름', 'icon': const Icon(Symbols.cloud)},
  {'value': 'rainy', 'label': '비', 'icon': const Icon(Symbols.rainy)},
  {'value': 'ac_unit', 'label': '눈/얼음', 'icon': const Icon(Symbols.ac_unit)},
];

Icon iconStringToWidget(String? iconStr) {
  if (iconStr == null || iconStr.isEmpty) {
    return const Icon(Symbols.error);
  }

  // 미리 정의된 아이콘 확인
  try {
    final predefinedIcon = icons.firstWhere((icon) => icon['value'] == iconStr);
    return predefinedIcon['icon'];
  } catch (e) {
    // 사용자 정의 아이콘 처리 (Material Symbols의 다른 아이콘)
    // Material Symbols 패키지에서는 직접 아이콘 이름을 사용할 수 없으므로
    // 미리 정의된 아이콘만 사용하도록 제한
    print('Custom icon not found: $iconStr, using error icon');
    return const Icon(Symbols.error);
  }
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
