import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/theme/themes.dart';

// Scheduler용 테마 스타일 정의
final Map<String, Map<String, dynamic>> themeSchedulerStyles = {
  // White 테마 (밝은 배경, 어두운 텍스트)
  'White': {
    'calendarBackgroundColor': Colors.white,
    'calendarBorderColor': Colors.grey[300]!,
    'headerBackgroundColor': Colors.blue.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.blue,
    'todayColor': Colors.blue,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.white,
    'eventListHeaderColor': Colors.blue.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.white,
    'eventCardBorderColor': Colors.grey[200]!,
  },

  // Dark 테마 (어두운 배경, 흰색 텍스트)
  'Dark': {
    'calendarBackgroundColor': Colors.grey[900]!,
    'calendarBorderColor': Colors.grey[800]!,
    'headerBackgroundColor': Colors.blue[800]!.withValues(alpha: 0.3),
    'headerTextStyle': const TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.white, fontSize: 14),
    'selectedDateColor': Colors.blue[400]!,
    'todayColor': Colors.blue[400]!,
    'weekendTextStyle': TextStyle(color: Colors.red[300]!, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.white, fontSize: 12),
    'eventListBackgroundColor': Colors.grey[900]!,
    'eventListHeaderColor': Colors.blue[800]!.withValues(alpha: 0.3),
    'eventCardBackgroundColor': Colors.grey[800]!,
    'eventCardBorderColor': Colors.grey[700]!,
  },

  // Light 테마 (Yellow 계열)
  'Light': {
    'calendarBackgroundColor': Colors.yellow[50]!,
    'calendarBorderColor': Colors.yellow[200]!,
    'headerBackgroundColor': Colors.orange.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.orange,
    'todayColor': Colors.orange,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.yellow[50]!,
    'eventListHeaderColor': Colors.orange.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.yellow[100]!,
    'eventCardBorderColor': Colors.yellow[200]!,
  },

  // Spring 테마 (Pink 계열)
  'Spring': {
    'calendarBackgroundColor': Colors.pink[50]!,
    'calendarBorderColor': Colors.pink[200]!,
    'headerBackgroundColor': Colors.pink.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.pink,
    'todayColor': Colors.pink,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.pink[50]!,
    'eventListHeaderColor': Colors.pink.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.pink[100]!,
    'eventCardBorderColor': Colors.pink[200]!,
  },

  // Summer 테마 (Blue 계열)
  'Summer': {
    'calendarBackgroundColor': Colors.lightBlue[50]!,
    'calendarBorderColor': Colors.blue[200]!,
    'headerBackgroundColor': Colors.blue.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.blue,
    'todayColor': Colors.blue,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.lightBlue[50]!,
    'eventListHeaderColor': Colors.blue.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.lightBlue[100]!,
    'eventCardBorderColor': Colors.blue[200]!,
  },

  // Autumn 테마 (Orange 계열)
  'Autumn': {
    'calendarBackgroundColor': Colors.orange[50]!,
    'calendarBorderColor': Colors.orange[200]!,
    'headerBackgroundColor': Colors.orange.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.orange,
    'todayColor': Colors.orange,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.orange[50]!,
    'eventListHeaderColor': Colors.orange.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.orange[100]!,
    'eventCardBorderColor': Colors.orange[200]!,
  },

  // Winter 테마 (BlueGrey 계열)
  'Winter': {
    'calendarBackgroundColor': Colors.blueGrey[50]!,
    'calendarBorderColor': Colors.blueGrey[200]!,
    'headerBackgroundColor': Colors.blueGrey.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.blueGrey,
    'todayColor': Colors.blueGrey,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.blueGrey[50]!,
    'eventListHeaderColor': Colors.blueGrey.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.blueGrey[100]!,
    'eventCardBorderColor': Colors.blueGrey[200]!,
  },

  // Nature 테마 (Green 계열)
  'Nature': {
    'calendarBackgroundColor': Colors.green[50]!,
    'calendarBorderColor': Colors.green[200]!,
    'headerBackgroundColor': Colors.green.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.green,
    'todayColor': Colors.green,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.green[50]!,
    'eventListHeaderColor': Colors.green.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.green[100]!,
    'eventCardBorderColor': Colors.green[200]!,
  },

  // Sea 테마 (Teal 계열)
  'Sea': {
    'calendarBackgroundColor': Colors.teal[50]!,
    'calendarBorderColor': Colors.teal[200]!,
    'headerBackgroundColor': Colors.teal.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.teal,
    'todayColor': Colors.teal,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.teal[50]!,
    'eventListHeaderColor': Colors.teal.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.teal[100]!,
    'eventCardBorderColor': Colors.teal[200]!,
  },

  // Tree 테마 (Brown 계열)
  'Tree': {
    'calendarBackgroundColor': Colors.brown[50]!,
    'calendarBorderColor': Colors.brown[200]!,
    'headerBackgroundColor': Colors.brown.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.brown,
    'todayColor': Colors.brown,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.brown[50]!,
    'eventListHeaderColor': Colors.brown.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.brown[100]!,
    'eventCardBorderColor': Colors.brown[200]!,
  },

  // Universe 테마 (DeepPurple 계열)
  'Universe': {
    'calendarBackgroundColor': Colors.deepPurple[50]!,
    'calendarBorderColor': Colors.deepPurple[200]!,
    'headerBackgroundColor': Colors.deepPurple.withValues(alpha: 0.1),
    'headerTextStyle': const TextStyle(
        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    'dateTextStyle': const TextStyle(color: Colors.black, fontSize: 14),
    'selectedDateColor': Colors.deepPurple,
    'todayColor': Colors.deepPurple,
    'weekendTextStyle': const TextStyle(color: Colors.red, fontSize: 14),
    'weekdayTextStyle': const TextStyle(color: Colors.black, fontSize: 12),
    'eventListBackgroundColor': Colors.deepPurple[50]!,
    'eventListHeaderColor': Colors.deepPurple.withValues(alpha: 0.1),
    'eventCardBackgroundColor': Colors.deepPurple[100]!,
    'eventCardBorderColor': Colors.deepPurple[200]!,
  },
};

// null-safe 컬러 변환 유틸리티
Color _color(dynamic v, [Color fallback = Colors.white]) =>
    v is Color ? v : fallback;

// Scheduler용 테마 설정 클래스
class SchedulerThemeConfig {
  final Color calendarBackgroundColor;
  final Color calendarBorderColor;
  final Color headerBackgroundColor;
  final TextStyle headerTextStyle;
  final TextStyle dateTextStyle;
  final Color selectedDateColor;
  final Color todayColor;
  final TextStyle weekendTextStyle;
  final TextStyle weekdayTextStyle;
  final Color eventListBackgroundColor;
  final Color eventListHeaderColor;
  final Color eventCardBackgroundColor;
  final Color eventCardBorderColor;

  SchedulerThemeConfig({
    required this.calendarBackgroundColor,
    required this.calendarBorderColor,
    required this.headerBackgroundColor,
    required this.headerTextStyle,
    required this.dateTextStyle,
    required this.selectedDateColor,
    required this.todayColor,
    required this.weekendTextStyle,
    required this.weekdayTextStyle,
    required this.eventListBackgroundColor,
    required this.eventListHeaderColor,
    required this.eventCardBackgroundColor,
    required this.eventCardBorderColor,
  });
}

// Scheduler용 테마 색상 가져오기
Color schedulerThemeColor(String theme) {
  return themes[theme] ?? Colors.white;
}

// Scheduler용 테마 스타일 가져오기
SchedulerThemeConfig schedulerStyle(String? theme) {
  // theme 문자열 정제 (null, 공백, 대소문자 등)
  final String safeTheme = (theme ?? 'White').trim();
  const String fallbackTheme = 'White';

  // 우선 themeSchedulerStyles에 있는지 확인, 없으면 fallback
  final Map<String, dynamic>? styleMap =
      themeSchedulerStyles.containsKey(safeTheme)
          ? themeSchedulerStyles[safeTheme]
          : themeSchedulerStyles[fallbackTheme];

  final Map<String, dynamic> safeStyleMap =
      styleMap ?? themeSchedulerStyles[fallbackTheme]!;

  return SchedulerThemeConfig(
    calendarBackgroundColor:
        _color(safeStyleMap['calendarBackgroundColor'], Colors.white),
    calendarBorderColor:
        _color(safeStyleMap['calendarBorderColor'], Colors.grey[300]!),
    headerBackgroundColor: _color(safeStyleMap['headerBackgroundColor'],
        Colors.blue.withValues(alpha: 0.1)),
    headerTextStyle: safeStyleMap['headerTextStyle'] ??
        const TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
    dateTextStyle: safeStyleMap['dateTextStyle'] ??
        const TextStyle(color: Colors.black, fontSize: 14),
    selectedDateColor: _color(safeStyleMap['selectedDateColor'], Colors.blue),
    todayColor: _color(safeStyleMap['todayColor'], Colors.blue),
    weekendTextStyle: safeStyleMap['weekendTextStyle'] ??
        const TextStyle(color: Colors.red, fontSize: 14),
    weekdayTextStyle: safeStyleMap['weekdayTextStyle'] ??
        const TextStyle(color: Colors.black, fontSize: 12),
    eventListBackgroundColor:
        _color(safeStyleMap['eventListBackgroundColor'], Colors.white),
    eventListHeaderColor: _color(safeStyleMap['eventListHeaderColor'],
        Colors.blue.withValues(alpha: 0.1)),
    eventCardBackgroundColor:
        _color(safeStyleMap['eventCardBackgroundColor'], Colors.white),
    eventCardBorderColor:
        _color(safeStyleMap['eventCardBorderColor'], Colors.grey[200]!),
  );
}
