# 위젯 트리 패널 (Widget Tree Panel)

## 개요

위젯 트리 패널은 DockBoard와 위젯들의 계층 구조를 시각적으로 표시하는 컴포넌트입니다. 이 패널을 통해 사용자는 복잡한 위젯 구조를 쉽게 탐색하고 관리할 수 있습니다.

## 주요 기능

### 1. 계층 구조 표시
- **최상위 보드**: `new_1`, `new_2` 등의 이름으로 시작하는 DockBoard
- **하위 위젯**: 각 보드 내부의 위젯들 (Text, Image, Button, Grid, Layout, Frame 등)
- **중첩 구조**: Layout과 Frame 위젯 내부의 하위 보드들

### 2. 위젯 타입별 아이콘
- 📝 **Text**: 텍스트 위젯
- 🖼️ **Image**: 이미지 위젯
- 🔘 **Button**: 버튼 위젯
- 🔍 **Search**: 검색 위젯
- 📊 **Grid**: 그리드 위젯
- 📋 **Layout**: 레이아웃 위젯
- 🖼️ **Frame**: 프레임 위젯
- 📈 **Chart**: 차트 위젯
- 📄 **Detail**: 상세 위젯
- 📋 **Template**: 템플릿 위젯

### 3. 상호작용 기능
- **아이템 선택**: 위젯을 클릭하면 해당 보드로 이동하고 아이템이 선택됨
- **하위 보드 보기**: Layout/Frame 아이템의 하위 보드들을 팝업으로 표시
- **편집 모드**: 아이템을 더블클릭하여 편집 모드로 전환

## 사용법

### 기본 사용법

```dart
import 'package:idev_v1/src/layout/widget_tree/widget_tree_panel.dart';

// 위젯 트리 패널 사용
const WidgetTreePanel()
```

### 통합 예제

```dart
import 'package:idev_v1/src/layout/widget_tree/widget_tree_integration.dart';

// 토글 가능한 위젯 트리 패널
const WidgetTreeIntegration()
```

## 파일 구조

```
lib/src/layout/widget_tree/
├── widget_tree_panel.dart      # 메인 위젯 트리 패널
├── widget_tree_example.dart    # 기본 사용 예제
├── widget_tree_integration.dart # 통합 예제
└── README.md                   # 이 파일
```

## 구현 세부사항

### 1. 데이터 소스
- `HomeRepo.hierarchicalControllers`: 계층 구조 컨트롤러들
- `HomeRepo.childParentRelations`: 부모-자식 관계 매핑
- `HomeRepo.parentChildRelations`: 자식-부모 관계 매핑

### 2. 트리 구조 탐색
```dart
// 최상위 보드들 찾기
final rootBoards = homeRepo.hierarchicalControllers.entries
    .where((entry) => entry.key.startsWith('new_'))
    .toList();

// 하위 보드들 찾기
final children = homeRepo.childParentRelations[boardId] ?? [];
```

### 3. 아이템 선택 처리
```dart
void _selectItem(StackItem item) {
  // 해당 보드로 이동
  homeRepo.selectDockBoardState(item.boardId);
  
  // 아이템 선택
  final controller = homeRepo.hierarchicalControllers[item.boardId];
  if (controller != null) {
    controller.controller.selectOne(item.id);
  }
}
```

## 스타일링

### 기본 스타일
- 패널 너비: 300px
- 배경색: 흰색
- 테두리: 오른쪽에 회색 테두리

### 아이템 스타일
- 선택된 아이템: 파란색 배경
- 아이콘: 위젯 타입별 색상
- 텍스트: 12px 폰트 크기

## 확장 가능성

### 1. 필터링 기능
- 특정 타입의 위젯만 표시
- 선택된 보드의 위젯만 표시

### 2. 검색 기능
- 위젯 이름으로 검색
- 위젯 ID로 검색

### 3. 드래그 앤 드롭
- 위젯을 드래그하여 다른 보드로 이동
- 위젯 순서 변경

### 4. 컨텍스트 메뉴
- 우클릭으로 추가 옵션 표시
- 삭제, 복사, 붙여넣기 기능

## 주의사항

1. **성능**: 많은 위젯이 있을 때 성능 최적화 필요
2. **메모리**: 계층 구조가 깊을 때 메모리 사용량 고려
3. **동기화**: 위젯 상태 변경 시 트리 뷰 업데이트 필요

## 향후 개선 사항

1. **가상화**: 대용량 트리 뷰를 위한 가상화 구현
2. **캐싱**: 자주 접근하는 노드들의 캐싱
3. **애니메이션**: 트리 확장/축소 애니메이션
4. **키보드 네비게이션**: 키보드로 트리 탐색 