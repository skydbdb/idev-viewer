import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';
import '../internal/board/board/stack_board.dart';
import '../internal/board/core/stack_board_controller.dart';
import '../internal/board/core/case_style.dart';
import '../internal/board/stack_board_item.dart';
import '../internal/board/stack_board_items/items/stack_text_item.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';

/// Web 플랫폼 구현 (internal 코드 직접 사용)
///
/// Flutter Web에서 internal 코드를 직접 사용하여 IDev Viewer를 렌더링합니다.
/// iframe 대신 Flutter 위젯으로 직접 렌더링하여 성능과 안정성을 향상시킵니다.
class IDevViewerPlatform extends StatefulWidget {
  final IDevConfig config;
  final VoidCallback? onReady;
  final Function(IDevEvent)? onEvent;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;

  const IDevViewerPlatform({
    super.key,
    required this.config,
    this.onReady,
    this.onEvent,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  State<IDevViewerPlatform> createState() => IDevViewerPlatformState();
}

class IDevViewerPlatformState extends State<IDevViewerPlatform> {
  late StackBoardController _stackBoardController;
  bool _isReady = false;
  String? _error;
  List<StackTextItem> _items = [];

  @override
  void initState() {
    super.initState();
    // 다음 프레임에서 초기화 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewer();
    });
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // config의 template이 변경되었는지 확인
    if (widget.config.template != oldWidget.config.template &&
        widget.config.template != null) {
      _updateTemplate(widget.config.template!);
    }
  }

  /// 뷰어 초기화
  void _initializeViewer() {
    try {
      // 뷰어 모드로 강제 설정 (BuildMode는 컴파일 타임 상수이므로 런타임에 변경 불가)
      // 대신 Service Locator만 뷰어 모드로 초기화
      initViewerServiceLocator();

      // StackBoardController 초기화
      _stackBoardController =
          StackBoardController(boardId: 'idev-viewer-board');

      // 템플릿 데이터 로드
      if (widget.config.template != null) {
        _updateTemplate(widget.config.template!);
      }

      // 준비 완료 상태로 설정
      setState(() {
        _isReady = true;
        _error = null;
      });

      // 준비 완료 콜백 호출
      widget.onReady?.call();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize viewer: $e';
      });
    }
  }

  /// 템플릿 업데이트
  void _updateTemplate(Map<String, dynamic> template) {
    try {
      final items = template['items'] as List<dynamic>? ?? [];
      
      // 기존 아이템들 모두 제거
      _stackBoardController.clear();
      
      // 새로운 아이템들 생성
      _items = items.map((itemData) {
        // 템플릿 데이터를 StackTextItem으로 변환
        return StackTextItem(
          boardId: 'idev-viewer-board',
          id: itemData['id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          offset: Offset(
            (itemData['x'] ?? 0).toDouble(),
            (itemData['y'] ?? 0).toDouble(),
          ),
          size: Size(
            (itemData['width'] ?? 200).toDouble(),
            (itemData['height'] ?? 100).toDouble(),
          ),
          content: TextItemContent(
            data: itemData['text'] ?? '위젯 ${itemData['id'] ?? 'Unknown'}',
          ),
          status: StackItemStatus.idle,
        );
      }).toList();

      // StackBoardController에 새로운 아이템들 추가
      for (final item in _items) {
        _stackBoardController.addItem(item);
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Failed to update template: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    if (!_isReady) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    // internal 코드를 직접 사용하여 StackBoard 렌더링
    return Provider<HomeRepo>(
      create: (_) => HomeRepo(),
      child: StackBoard(
        id: 'idev-viewer-board',
        controller: _stackBoardController,
        customBuilder: _buildItemWidget,
        caseStyle: const CaseStyle(
          frameBorderWidth: 1.0,
          frameBorderColor: Colors.grey,
        ),
        onTap: (item) {
          // 아이템 탭 이벤트 처리
          widget.onEvent?.call(IDevEvent(
            type: 'item_tap',
            data: {'itemId': item.id, 'item': item.toJson()},
          ));
        },
      ),
    );
  }

  /// 아이템 위젯 빌더
  Widget? _buildItemWidget(StackItem<StackItemContent> item) {
    // 아이템 타입에 따라 다른 위젯 반환
    final content = item.content;
    if (content == null) return null;

    // 기본 위젯 반환 (실제 구현에서는 content 타입에 따라 분기)
    return Container(
      width: item.size.width,
      height: item.size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets,
              size: 32,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 8),
            Text(
              '위젯 (${content.runtimeType})',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${item.size.width.toInt()}x${item.size.height.toInt()}',
              style: TextStyle(
                color: Colors.blue[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stackBoardController.dispose();
    super.dispose();
  }
}
