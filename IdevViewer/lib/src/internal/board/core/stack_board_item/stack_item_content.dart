/// * More info of StackItem

abstract class StackItemContent {
  const StackItemContent();

  /// * to json
  Map<String, dynamic> toJson();

  /// * from json factory method
  static StackItemContent? fromJson(Map<String, dynamic> json) {
    // 기본 구현: 템플릿 데이터를 기반으로 적절한 StackItemContent 생성
    // 실제 구현에서는 json의 타입에 따라 분기해야 함
    return null;
  }
}
