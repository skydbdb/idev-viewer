import 'package:flutter/material.dart';

/// 정렬 타입 정의
enum AlignmentType {
  verticalCenter, // 수직 중심선
  horizontalCenter, // 수평 중심선
  leftEdge, // 좌측 외곽선
  rightEdge, // 우측 외곽선
  topEdge, // 상단 외곽선
  bottomEdge, // 하단 외곽선
}

/// 정렬 가이드라인 정보
class AlignmentGuide {
  final AlignmentType type;
  final double position;
  final double distance;

  const AlignmentGuide({
    required this.type,
    required this.position,
    required this.distance,
  });

  @override
  String toString() {
    return 'AlignmentGuide(type: $type, position: $position, distance: $distance)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlignmentGuide &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          position == other.position &&
          distance == other.distance;

  @override
  int get hashCode => Object.hash(type, position, distance);
}
