import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/theme/themes.dart';

// Layout용 테마 스타일 정의
final Map<String, Map<String, dynamic>> themeLayoutStyles = {
  // White 테마 (밝은 배경, 어두운 텍스트)
  'White': {
    'appBarBackgroundColor': Colors.white,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': Colors.black12,
    'drawerBackgroundColor': Colors.white,
    'drawerSelectedIconColor': Colors.blue,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.blue,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.white,
    'navigationIndicatorColor': Colors.blue.withOpacity(0.2),
    'navigationSelectedIconColor': Colors.blue,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.blue,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.grey[50] ?? Colors.white,
    'dividerColor': Colors.grey[300] ?? Colors.grey,
    'cardColor': Colors.white,
    'cardElevation': 1.0,
    'cardShadowColor': Colors.black12,
  },

  // Dark 테마 (어두운 배경, 흰색 텍스트)
  'Dark': {
    'appBarBackgroundColor': Colors.grey[900] ?? Colors.black,
    'appBarForegroundColor': Colors.white,
    'appBarElevation': 4.0,
    'appBarShadowColor': Colors.black26,
    'drawerBackgroundColor': Colors.grey[900] ?? Colors.black,
    'drawerSelectedIconColor': Colors.blue[300] ?? Colors.blue,
    'drawerUnselectedIconColor': Colors.grey[400] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.blue[300] ?? Colors.blue,
    'drawerUnselectedLabelColor': Colors.grey[400] ?? Colors.grey,
    'navigationBackgroundColor': Colors.grey[900] ?? Colors.black,
    'navigationIndicatorColor':
        (Colors.blue[300] ?? Colors.blue).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.blue[300] ?? Colors.blue,
    'navigationUnselectedIconColor': Colors.grey[400] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.blue[300] ?? Colors.blue,
    'navigationUnselectedLabelColor': Colors.grey[400] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.grey[850] ?? Colors.black,
    'dividerColor': Colors.grey[700] ?? Colors.grey,
    'cardColor': Colors.grey[800] ?? Colors.grey,
    'cardElevation': 2.0,
    'cardShadowColor': Colors.black26,
  },

  // Light 테마 (Yellow 계열)
  'Light': {
    'appBarBackgroundColor': Colors.yellow[100] ?? Colors.yellow,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.yellow[700] ?? Colors.yellow).withOpacity(0.3),
    'drawerBackgroundColor': Colors.yellow[50] ?? Colors.yellow,
    'drawerSelectedIconColor': Colors.orange[700] ?? Colors.orange,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.orange[700] ?? Colors.orange,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.yellow[50] ?? Colors.yellow,
    'navigationIndicatorColor':
        (Colors.orange[700] ?? Colors.orange).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.orange[700] ?? Colors.orange,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.orange[700] ?? Colors.orange,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.yellow[100] ?? Colors.yellow,
    'dividerColor': Colors.yellow[200] ?? Colors.yellow,
    'cardColor': Colors.yellow[100] ?? Colors.yellow,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.orange[700] ?? Colors.orange).withOpacity(0.2),
  },

  // Spring 테마 (Pink 계열)
  'Spring': {
    'appBarBackgroundColor': Colors.pink[100] ?? Colors.pink,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.pink[700] ?? Colors.pink).withOpacity(0.3),
    'drawerBackgroundColor': Colors.pink[50] ?? Colors.pink,
    'drawerSelectedIconColor': Colors.pink[700] ?? Colors.pink,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.pink[700] ?? Colors.pink,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.pink[50] ?? Colors.pink,
    'navigationIndicatorColor':
        (Colors.pink[700] ?? Colors.pink).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.pink[700] ?? Colors.pink,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.pink[700] ?? Colors.pink,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.pink[100] ?? Colors.pink,
    'dividerColor': Colors.pink[200] ?? Colors.pink,
    'cardColor': Colors.pink[100] ?? Colors.pink,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.pink[700] ?? Colors.pink).withOpacity(0.2),
  },

  // Summer 테마 (Blue 계열)
  'Summer': {
    'appBarBackgroundColor': Colors.blue[100] ?? Colors.blue,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.blue[700] ?? Colors.blue).withOpacity(0.3),
    'drawerBackgroundColor': Colors.blue[50] ?? Colors.blue,
    'drawerSelectedIconColor': Colors.blue[700] ?? Colors.blue,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.blue[700] ?? Colors.blue,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.blue[50] ?? Colors.blue,
    'navigationIndicatorColor':
        (Colors.blue[700] ?? Colors.blue).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.blue[700] ?? Colors.blue,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.blue[700] ?? Colors.blue,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.blue[100] ?? Colors.blue,
    'dividerColor': Colors.blue[200] ?? Colors.blue,
    'cardColor': Colors.blue[100] ?? Colors.blue,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.blue[700] ?? Colors.blue).withOpacity(0.2),
  },

  // Autumn 테마 (Orange 계열)
  'Autumn': {
    'appBarBackgroundColor': Colors.orange[100] ?? Colors.orange,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.orange[700] ?? Colors.orange).withOpacity(0.3),
    'drawerBackgroundColor': Colors.orange[50] ?? Colors.orange,
    'drawerSelectedIconColor': Colors.orange[700] ?? Colors.orange,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.orange[700] ?? Colors.orange,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.orange[50] ?? Colors.orange,
    'navigationIndicatorColor':
        (Colors.orange[700] ?? Colors.orange).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.orange[700] ?? Colors.orange,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.orange[700] ?? Colors.orange,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.orange[100] ?? Colors.orange,
    'dividerColor': Colors.orange[200] ?? Colors.orange,
    'cardColor': Colors.orange[100] ?? Colors.orange,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.orange[700] ?? Colors.orange).withOpacity(0.2),
  },

  // Winter 테마 (BlueGrey 계열)
  'Winter': {
    'appBarBackgroundColor': Colors.blueGrey[100] ?? Colors.blueGrey,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor':
        (Colors.blueGrey[700] ?? Colors.blueGrey).withOpacity(0.3),
    'drawerBackgroundColor': Colors.blueGrey[50] ?? Colors.blueGrey,
    'drawerSelectedIconColor': Colors.blueGrey[700] ?? Colors.blueGrey,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.blueGrey[700] ?? Colors.blueGrey,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.blueGrey[50] ?? Colors.blueGrey,
    'navigationIndicatorColor':
        (Colors.blueGrey[700] ?? Colors.blueGrey).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.blueGrey[700] ?? Colors.blueGrey,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.blueGrey[700] ?? Colors.blueGrey,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.blueGrey[100] ?? Colors.blueGrey,
    'dividerColor': Colors.blueGrey[200] ?? Colors.blueGrey,
    'cardColor': Colors.blueGrey[100] ?? Colors.blueGrey,
    'cardElevation': 1.0,
    'cardShadowColor':
        (Colors.blueGrey[700] ?? Colors.blueGrey).withOpacity(0.2),
  },

  // Nature 테마 (Green 계열)
  'Nature': {
    'appBarBackgroundColor': Colors.green[100] ?? Colors.green,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.green[700] ?? Colors.green).withOpacity(0.3),
    'drawerBackgroundColor': Colors.green[50] ?? Colors.green,
    'drawerSelectedIconColor': Colors.green[700] ?? Colors.green,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.green[700] ?? Colors.green,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.green[50] ?? Colors.green,
    'navigationIndicatorColor':
        (Colors.green[700] ?? Colors.green).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.green[700] ?? Colors.green,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.green[700] ?? Colors.green,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.green[100] ?? Colors.green,
    'dividerColor': Colors.green[200] ?? Colors.green,
    'cardColor': Colors.green[100] ?? Colors.green,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.green[700] ?? Colors.green).withOpacity(0.2),
  },

  // Sea 테마 (Teal 계열)
  'Sea': {
    'appBarBackgroundColor': Colors.teal[100] ?? Colors.teal,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.teal[700] ?? Colors.teal).withOpacity(0.3),
    'drawerBackgroundColor': Colors.teal[50] ?? Colors.teal,
    'drawerSelectedIconColor': Colors.teal[700] ?? Colors.teal,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.teal[700] ?? Colors.teal,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.teal[50] ?? Colors.teal,
    'navigationIndicatorColor':
        (Colors.teal[700] ?? Colors.teal).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.teal[700] ?? Colors.teal,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.teal[700] ?? Colors.teal,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.teal[100] ?? Colors.teal,
    'dividerColor': Colors.teal[200] ?? Colors.teal,
    'cardColor': Colors.teal[100] ?? Colors.teal,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.teal[700] ?? Colors.teal).withOpacity(0.2),
  },

  // Tree 테마 (Brown 계열)
  'Tree': {
    'appBarBackgroundColor': Colors.brown[100] ?? Colors.brown,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor': (Colors.brown[700] ?? Colors.brown).withOpacity(0.3),
    'drawerBackgroundColor': Colors.brown[50] ?? Colors.brown,
    'drawerSelectedIconColor': Colors.brown[700] ?? Colors.brown,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.brown[700] ?? Colors.brown,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.brown[50] ?? Colors.brown,
    'navigationIndicatorColor':
        (Colors.brown[700] ?? Colors.brown).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.brown[700] ?? Colors.brown,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.brown[700] ?? Colors.brown,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.brown[100] ?? Colors.brown,
    'dividerColor': Colors.brown[200] ?? Colors.brown,
    'cardColor': Colors.brown[100] ?? Colors.brown,
    'cardElevation': 1.0,
    'cardShadowColor': (Colors.brown[700] ?? Colors.brown).withOpacity(0.2),
  },

  // Universe 테마 (DeepPurple 계열)
  'Universe': {
    'appBarBackgroundColor': Colors.deepPurple[100] ?? Colors.deepPurple,
    'appBarForegroundColor': Colors.black,
    'appBarElevation': 2.0,
    'appBarShadowColor':
        (Colors.deepPurple[700] ?? Colors.deepPurple).withOpacity(0.3),
    'drawerBackgroundColor': Colors.deepPurple[50] ?? Colors.deepPurple,
    'drawerSelectedIconColor': Colors.deepPurple[700] ?? Colors.deepPurple,
    'drawerUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'drawerSelectedLabelColor': Colors.deepPurple[700] ?? Colors.deepPurple,
    'drawerUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'navigationBackgroundColor': Colors.deepPurple[50] ?? Colors.deepPurple,
    'navigationIndicatorColor':
        (Colors.deepPurple[700] ?? Colors.deepPurple).withOpacity(0.2),
    'navigationSelectedIconColor': Colors.deepPurple[700] ?? Colors.deepPurple,
    'navigationUnselectedIconColor': Colors.grey[600] ?? Colors.grey,
    'navigationSelectedLabelColor': Colors.deepPurple[700] ?? Colors.deepPurple,
    'navigationUnselectedLabelColor': Colors.grey[600] ?? Colors.grey,
    'scaffoldBackgroundColor': Colors.deepPurple[100] ?? Colors.deepPurple,
    'dividerColor': Colors.deepPurple[200] ?? Colors.deepPurple,
    'cardColor': Colors.deepPurple[100] ?? Colors.deepPurple,
    'cardElevation': 1.0,
    'cardShadowColor':
        (Colors.deepPurple[700] ?? Colors.deepPurple).withOpacity(0.2),
  },
};

// null-safe 컬러/더블 변환 유틸리티 (파일 상단에 위치)
Color _color(dynamic v, [Color fallback = Colors.white]) =>
    v is Color ? v : fallback;
double _double(dynamic v, [double fallback = 1.0]) =>
    v is double ? v : fallback;

// Layout용 테마 설정 클래스
class LayoutThemeConfig {
  final Color appBarBackgroundColor;
  final Color appBarForegroundColor;
  final double appBarElevation;
  final Color appBarShadowColor;
  final Color drawerBackgroundColor;
  final Color drawerSelectedIconColor;
  final Color drawerUnselectedIconColor;
  final Color drawerSelectedLabelColor;
  final Color drawerUnselectedLabelColor;
  final Color navigationBackgroundColor;
  final Color navigationIndicatorColor;
  final Color navigationSelectedIconColor;
  final Color navigationUnselectedIconColor;
  final Color navigationSelectedLabelColor;
  final Color navigationUnselectedLabelColor;
  final Color scaffoldBackgroundColor;
  final Color dividerColor;
  final Color cardColor;
  final double cardElevation;
  final Color cardShadowColor;

  LayoutThemeConfig({
    required this.appBarBackgroundColor,
    required this.appBarForegroundColor,
    required this.appBarElevation,
    required this.appBarShadowColor,
    required this.drawerBackgroundColor,
    required this.drawerSelectedIconColor,
    required this.drawerUnselectedIconColor,
    required this.drawerSelectedLabelColor,
    required this.drawerUnselectedLabelColor,
    required this.navigationBackgroundColor,
    required this.navigationIndicatorColor,
    required this.navigationSelectedIconColor,
    required this.navigationUnselectedIconColor,
    required this.navigationSelectedLabelColor,
    required this.navigationUnselectedLabelColor,
    required this.scaffoldBackgroundColor,
    required this.dividerColor,
    required this.cardColor,
    required this.cardElevation,
    required this.cardShadowColor,
  });
}

// Layout용 테마 색상 가져오기
Color layoutThemeColor(String theme) {
  return themes[theme] ?? Colors.white;
}

// Layout용 테마 스타일 가져오기
LayoutThemeConfig layoutStyle(String? theme) {
  // theme 문자열 정제 (null, 공백, 대소문자 등)
  final String safeTheme = (theme ?? 'White').trim();
  const String fallbackTheme = 'White';

  // 우선 themeLayoutStyles에 있는지 확인, 없으면 fallback
  final Map<String, dynamic>? styleMap =
      themeLayoutStyles.containsKey(safeTheme)
          ? themeLayoutStyles[safeTheme]
          : themeLayoutStyles[fallbackTheme];

  final Map<String, dynamic> safeStyleMap =
      styleMap ?? themeLayoutStyles[fallbackTheme]!;

  return LayoutThemeConfig(
    appBarBackgroundColor:
        _color(safeStyleMap['appBarBackgroundColor'], Colors.white),
    appBarForegroundColor:
        _color(safeStyleMap['appBarForegroundColor'], Colors.black),
    appBarElevation: _double(safeStyleMap['appBarElevation'], 2.0),
    appBarShadowColor:
        _color(safeStyleMap['appBarShadowColor'], Colors.black12),
    drawerBackgroundColor:
        _color(safeStyleMap['drawerBackgroundColor'], Colors.white),
    drawerSelectedIconColor:
        _color(safeStyleMap['drawerSelectedIconColor'], Colors.blue),
    drawerUnselectedIconColor: _color(safeStyleMap['drawerUnselectedIconColor'],
        Colors.grey[600] ?? Colors.grey),
    drawerSelectedLabelColor:
        _color(safeStyleMap['drawerSelectedLabelColor'], Colors.blue),
    drawerUnselectedLabelColor: _color(
        safeStyleMap['drawerUnselectedLabelColor'],
        Colors.grey[600] ?? Colors.grey),
    navigationBackgroundColor:
        _color(safeStyleMap['navigationBackgroundColor'], Colors.white),
    navigationIndicatorColor: _color(
        safeStyleMap['navigationIndicatorColor'], Colors.blue.withOpacity(0.2)),
    navigationSelectedIconColor:
        _color(safeStyleMap['navigationSelectedIconColor'], Colors.blue),
    navigationUnselectedIconColor: _color(
        safeStyleMap['navigationUnselectedIconColor'],
        Colors.grey[600] ?? Colors.grey),
    navigationSelectedLabelColor:
        _color(safeStyleMap['navigationSelectedLabelColor'], Colors.blue),
    navigationUnselectedLabelColor: _color(
        safeStyleMap['navigationUnselectedLabelColor'],
        Colors.grey[600] ?? Colors.grey),
    scaffoldBackgroundColor: _color(safeStyleMap['scaffoldBackgroundColor'],
        Colors.grey[50] ?? Colors.white),
    dividerColor:
        _color(safeStyleMap['dividerColor'], Colors.grey[300] ?? Colors.grey),
    cardColor: _color(safeStyleMap['cardColor'], Colors.white),
    cardElevation: _double(safeStyleMap['cardElevation'], 1.0),
    cardShadowColor: _color(safeStyleMap['cardShadowColor'], Colors.black12),
  );
}
