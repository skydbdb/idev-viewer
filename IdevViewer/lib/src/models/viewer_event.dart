/// IDev Viewer 이벤트 클래스
class IDevEvent {
  /// 이벤트 타입
  final String type;

  /// 이벤트 데이터
  final Map<String, dynamic> data;

  /// 이벤트 타임스탬프
  final DateTime timestamp;

  IDevEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// JSON에서 생성
  factory IDevEvent.fromJson(Map<String, dynamic> json) {
    return IDevEvent(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }

  @override
  String toString() => 'IDevEvent(type: $type, data: $data)';
}

