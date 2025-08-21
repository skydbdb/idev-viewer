import 'package:flutter/material.dart';
import 'package:idev_v1/src/theme/themes.dart';

// Chart용 테마 스타일 정의
final Map<String, Map<String, dynamic>> themeChartStyles = {
  // White 테마 (밝은 배경, 어두운 텍스트)
  'White': {
    'chartBackgroundColor': Colors.white,
    'chartBorderColor': Colors.grey[300]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.white,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.grey[200]!,
    'selectionColor': Colors.blue.withOpacity(0.3),
    'appBarBackgroundColor': Colors.blueGrey.shade50,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Dark 테마 (어두운 배경, 흰색 텍스트)
  'Dark': {
    'chartBackgroundColor': Colors.grey[900]!,
    'chartBorderColor': Colors.grey[800]!,
    'titleTextStyle': const TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.white, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.white, fontSize: 12),
    'tooltipBackgroundColor': Colors.grey[800]!,
    'tooltipTextStyle': const TextStyle(color: Colors.white, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.grey[700]!,
    'selectionColor': Colors.blue[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.grey[850]!,
    'appBarTextStyle': const TextStyle(color: Colors.white),
  },

  // Light 테마 (Yellow 계열)
  'Light': {
    'chartBackgroundColor': Colors.yellow[50]!,
    'chartBorderColor': Colors.grey[400]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.yellow[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.yellow[200]!,
    'selectionColor': Colors.orange.withOpacity(0.3),
    'appBarBackgroundColor': Colors.yellow[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Spring 테마 (Pink 계열)
  'Spring': {
    'chartBackgroundColor': Colors.pink[50]!,
    'chartBorderColor': Colors.pink[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.pink[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.pink[200]!,
    'selectionColor': Colors.pink[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.pink[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Summer 테마 (Blue 계열)
  'Summer': {
    'chartBackgroundColor': Colors.lightBlue[50]!,
    'chartBorderColor': Colors.blue[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.lightBlue[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.blue[200]!,
    'selectionColor': Colors.blue[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.lightBlue[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Autumn 테마 (Orange 계열)
  'Autumn': {
    'chartBackgroundColor': Colors.orange[50]!,
    'chartBorderColor': Colors.orange[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.orange[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.orange[200]!,
    'selectionColor': Colors.orange[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.orange[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Winter 테마 (BlueGrey 계열)
  'Winter': {
    'chartBackgroundColor': Colors.blueGrey[50]!,
    'chartBorderColor': Colors.blueGrey[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.blueGrey[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.blueGrey[200]!,
    'selectionColor': Colors.blueGrey[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.blueGrey[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Nature 테마 (Green 계열)
  'Nature': {
    'chartBackgroundColor': Colors.green[50]!,
    'chartBorderColor': Colors.green[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.green[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.green[200]!,
    'selectionColor': Colors.green[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.green[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Sea 테마 (Teal 계열)
  'Sea': {
    'chartBackgroundColor': Colors.teal[50]!,
    'chartBorderColor': Colors.teal[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.teal[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.teal[200]!,
    'selectionColor': Colors.teal[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.teal[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Tree 테마 (Brown 계열)
  'Tree': {
    'chartBackgroundColor': Colors.brown[50]!,
    'chartBorderColor': Colors.brown[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.brown[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.brown[200]!,
    'selectionColor': Colors.brown[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.brown[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },

  // Universe 테마 (DeepPurple 계열)
  'Universe': {
    'chartBackgroundColor': Colors.deepPurple[50]!,
    'chartBorderColor': Colors.deepPurple[200]!,
    'titleTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'axisTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'legendTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'tooltipBackgroundColor': Colors.deepPurple[100]!,
    'tooltipTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'dataLabelTextStyle': const TextStyle(
        color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    'gridLineColor': Colors.deepPurple[200]!,
    'selectionColor': Colors.deepPurple[300]!.withOpacity(0.3),
    'appBarBackgroundColor': Colors.deepPurple[100]!,
    'appBarTextStyle': const TextStyle(color: Colors.black),
  },
};

// null-safe 컬러/더블 변환 유틸리티
Color _color(dynamic v, [Color fallback = Colors.white]) =>
    v is Color ? v : fallback;
double _double(dynamic v, [double fallback = 1.0]) =>
    v is double ? v : fallback;

// Chart용 테마 설정 클래스
class ChartThemeConfig {
  final Color chartBackgroundColor;
  final Color chartBorderColor;
  final TextStyle titleTextStyle;
  final TextStyle axisTextStyle;
  final TextStyle legendTextStyle;
  final Color tooltipBackgroundColor;
  final TextStyle tooltipTextStyle;
  final TextStyle dataLabelTextStyle;
  final Color gridLineColor;
  final Color selectionColor;
  final Color appBarBackgroundColor;
  final TextStyle appBarTextStyle;

  ChartThemeConfig({
    required this.chartBackgroundColor,
    required this.chartBorderColor,
    required this.titleTextStyle,
    required this.axisTextStyle,
    required this.legendTextStyle,
    required this.tooltipBackgroundColor,
    required this.tooltipTextStyle,
    required this.dataLabelTextStyle,
    required this.gridLineColor,
    required this.selectionColor,
    required this.appBarBackgroundColor,
    required this.appBarTextStyle,
  });
}

// Chart용 테마 색상 가져오기
Color chartThemeColor(String theme) {
  return themes[theme] ?? Colors.white;
}

// Chart용 테마 스타일 가져오기
ChartThemeConfig chartStyle(String? theme) {
  // theme 문자열 정제 (null, 공백, 대소문자 등)
  final String safeTheme = (theme ?? 'White').trim();
  const String fallbackTheme = 'White';

  // 우선 themeChartStyles에 있는지 확인, 없으면 fallback
  final Map<String, dynamic>? styleMap = themeChartStyles.containsKey(safeTheme)
      ? themeChartStyles[safeTheme]
      : themeChartStyles[fallbackTheme];

  final Map<String, dynamic> safeStyleMap =
      styleMap ?? themeChartStyles[fallbackTheme]!;

  return ChartThemeConfig(
    chartBackgroundColor:
        _color(safeStyleMap['chartBackgroundColor'], Colors.white),
    chartBorderColor:
        _color(safeStyleMap['chartBorderColor'], Colors.grey[300]!),
    titleTextStyle: safeStyleMap['titleTextStyle'] ??
        const TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    axisTextStyle: safeStyleMap['axisTextStyle'] ??
        const TextStyle(color: Colors.black, fontSize: 12),
    legendTextStyle: safeStyleMap['legendTextStyle'] ??
        const TextStyle(color: Colors.black, fontSize: 12),
    tooltipBackgroundColor:
        _color(safeStyleMap['tooltipBackgroundColor'], Colors.white),
    tooltipTextStyle: safeStyleMap['tooltipTextStyle'] ??
        const TextStyle(color: Colors.black, fontSize: 12),
    dataLabelTextStyle: safeStyleMap['dataLabelTextStyle'] ??
        const TextStyle(
            color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    gridLineColor: _color(safeStyleMap['gridLineColor'], Colors.grey[200]!),
    selectionColor:
        _color(safeStyleMap['selectionColor'], Colors.blue.withOpacity(0.3)),
    appBarBackgroundColor:
        _color(safeStyleMap['appBarBackgroundColor'], Colors.blueGrey.shade50),
    appBarTextStyle:
        safeStyleMap['appBarTextStyle'] ?? const TextStyle(color: Colors.black),
  );
}
