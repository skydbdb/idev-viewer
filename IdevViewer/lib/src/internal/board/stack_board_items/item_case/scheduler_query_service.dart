// import 'package:idev_viewer/src/internal/board/stack_board_items/items/stack_scheduler_item.dart';

// /// 스케줄러 쿼리 서비스
// /// 일별, 월별, 주별 일정 정보 쿼리 기능 제공
// class SchedulerQueryService {
//   /// 일별 일정 조회
//   /// 특정 날짜의 모든 일정을 반환
//   static List<ScheduleData> getDailySchedules(
//     List<ScheduleData> allSchedules,
//     DateTime date,
//   ) {
//     return allSchedules.where((schedule) {
//       return _isSameDay(schedule.date, date);
//     }).toList();
//   }

//   /// 월별 일정 조회
//   /// 특정 월의 모든 일정을 반환
//   static List<ScheduleData> getMonthlySchedules(
//     List<ScheduleData> allSchedules,
//     DateTime month,
//   ) {
//     return allSchedules.where((schedule) {
//       return schedule.date.year == month.year &&
//           schedule.date.month == month.month;
//     }).toList();
//   }

//   /// 주별 일정 조회
//   /// 특정 주의 모든 일정을 반환
//   static List<ScheduleData> getWeeklySchedules(
//     List<ScheduleData> allSchedules,
//     DateTime weekStart,
//   ) {
//     final weekEnd = weekStart.add(const Duration(days: 6));
//     return allSchedules.where((schedule) {
//       return schedule.date
//               .isAfter(weekStart.subtract(const Duration(days: 1))) &&
//           schedule.date.isBefore(weekEnd.add(const Duration(days: 1)));
//     }).toList();
//   }

//   /// 기간별 일정 조회
//   /// 시작일과 종료일 사이의 모든 일정을 반환
//   static List<ScheduleData> getSchedulesByDateRange(
//     List<ScheduleData> allSchedules,
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     return allSchedules.where((schedule) {
//       return schedule.date
//               .isAfter(startDate.subtract(const Duration(days: 1))) &&
//           schedule.date.isBefore(endDate.add(const Duration(days: 1)));
//     }).toList();
//   }

//   /// 사용자별 일정 조회
//   /// 특정 사용자의 모든 일정을 반환
//   static List<ScheduleData> getSchedulesByUser(
//     List<ScheduleData> allSchedules,
//     String userId,
//   ) {
//     return allSchedules.where((schedule) {
//       return schedule.userId == userId;
//     }).toList();
//   }

//   /// 상태별 일정 조회
//   /// 특정 상태의 모든 일정을 반환
//   static List<ScheduleData> getSchedulesByStatus(
//     List<ScheduleData> allSchedules,
//     String status,
//   ) {
//     return allSchedules.where((schedule) {
//       return schedule.status == status;
//     }).toList();
//   }

//   /// 일정 통계 조회
//   /// 기간별 일정 통계 정보를 반환
//   static ScheduleStatistics getScheduleStatistics(
//     List<ScheduleData> schedules,
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     final filteredSchedules =
//         getSchedulesByDateRange(schedules, startDate, endDate);

//     final totalSchedules = filteredSchedules.length;
//     final confirmedSchedules =
//         filteredSchedules.where((s) => s.status == '확정').length;
//     final pendingSchedules =
//         filteredSchedules.where((s) => s.status == '예정').length;
//     final completedSchedules =
//         filteredSchedules.where((s) => s.status == '완료').length;
//     final cancelledSchedules =
//         filteredSchedules.where((s) => s.status == '취소').length;

//     // 일정이 있는 날짜 수 계산
//     final uniqueDates =
//         filteredSchedules.map((s) => _getDateOnly(s.date)).toSet();
//     final scheduledDays = uniqueDates.length;

//     // 총 기간 계산
//     final totalDays = endDate.difference(startDate).inDays + 1;

//     return ScheduleStatistics(
//       totalSchedules: totalSchedules,
//       confirmedSchedules: confirmedSchedules,
//       pendingSchedules: pendingSchedules,
//       completedSchedules: completedSchedules,
//       cancelledSchedules: cancelledSchedules,
//       scheduledDays: scheduledDays,
//       totalDays: totalDays,
//       scheduleRate: totalDays > 0 ? (scheduledDays / totalDays * 100) : 0.0,
//     );
//   }

//   /// 월별 일정 요약 조회
//   /// 특정 월의 일정 요약 정보를 반환
//   static MonthlyScheduleSummary getMonthlySummary(
//     List<ScheduleData> allSchedules,
//     DateTime month,
//   ) {
//     final monthlySchedules = getMonthlySchedules(allSchedules, month);

//     // 일별 일정 수 계산
//     final dailyCounts = <int, int>{};
//     for (final schedule in monthlySchedules) {
//       final day = schedule.date.day;
//       dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
//     }

//     // 상태별 통계
//     final statusCounts = <String, int>{};
//     for (final schedule in monthlySchedules) {
//       final status = schedule.status ?? '예정';
//       statusCounts[status] = (statusCounts[status] ?? 0) + 1;
//     }

//     return MonthlyScheduleSummary(
//       month: month,
//       totalSchedules: monthlySchedules.length,
//       dailyCounts: dailyCounts,
//       statusCounts: statusCounts,
//       schedules: monthlySchedules,
//     );
//   }

//   /// 주별 일정 요약 조회
//   /// 특정 주의 일정 요약 정보를 반환
//   static WeeklyScheduleSummary getWeeklySummary(
//     List<ScheduleData> allSchedules,
//     DateTime weekStart,
//   ) {
//     final weeklySchedules = getWeeklySchedules(allSchedules, weekStart);

//     // 요일별 일정 수 계산
//     final weekdayCounts = <int, int>{};
//     for (final schedule in weeklySchedules) {
//       final weekday = schedule.date.weekday;
//       weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
//     }

//     // 상태별 통계
//     final statusCounts = <String, int>{};
//     for (final schedule in weeklySchedules) {
//       final status = schedule.status ?? '예정';
//       statusCounts[status] = (statusCounts[status] ?? 0) + 1;
//     }

//     return WeeklyScheduleSummary(
//       weekStart: weekStart,
//       totalSchedules: weeklySchedules.length,
//       weekdayCounts: weekdayCounts,
//       statusCounts: statusCounts,
//       schedules: weeklySchedules,
//     );
//   }

//   /// 일정 검색
//   /// 제목, 설명에서 키워드 검색
//   static List<ScheduleData> searchSchedules(
//     List<ScheduleData> allSchedules,
//     String keyword,
//   ) {
//     if (keyword.isEmpty) return allSchedules;

//     final lowerKeyword = keyword.toLowerCase();
//     return allSchedules.where((schedule) {
//       return schedule.title.toLowerCase().contains(lowerKeyword) ||
//           (schedule.description?.toLowerCase().contains(lowerKeyword) ?? false);
//     }).toList();
//   }

//   /// 일정 정렬
//   /// 날짜, 제목, 상태별로 정렬
//   static List<ScheduleData> sortSchedules(
//       List<ScheduleData> schedules, ScheduleSortType sortType,
//       {bool ascending = true}) {
//     final sortedSchedules = List<ScheduleData>.from(schedules);

//     switch (sortType) {
//       case ScheduleSortType.date:
//         sortedSchedules.sort((a, b) =>
//             ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
//         break;
//       case ScheduleSortType.title:
//         sortedSchedules.sort((a, b) => ascending
//             ? a.title.compareTo(b.title)
//             : b.title.compareTo(a.title));
//         break;
//       case ScheduleSortType.status:
//         sortedSchedules.sort((a, b) => ascending
//             ? (a.status ?? '').compareTo(b.status ?? '')
//             : (b.status ?? '').compareTo(a.status ?? ''));
//         break;
//       case ScheduleSortType.startTime:
//         sortedSchedules.sort((a, b) {
//           final aTime = a.startTime ?? '00:00:00';
//           final bTime = b.startTime ?? '00:00:00';
//           return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
//         });
//         break;
//     }

//     return sortedSchedules;
//   }

//   /// 헬퍼 메서드: 같은 날인지 확인
//   static bool _isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }

//   /// 헬퍼 메서드: 날짜만 추출 (시간 제거)
//   static DateTime _getDateOnly(DateTime date) {
//     return DateTime(date.year, date.month, date.day);
//   }
// }

// /// 일정 정렬 타입
// enum ScheduleSortType {
//   date,
//   title,
//   status,
//   startTime,
// }

// /// 일정 통계 정보
// class ScheduleStatistics {
//   const ScheduleStatistics({
//     required this.totalSchedules,
//     required this.confirmedSchedules,
//     required this.pendingSchedules,
//     required this.completedSchedules,
//     required this.cancelledSchedules,
//     required this.scheduledDays,
//     required this.totalDays,
//     required this.scheduleRate,
//   });

//   final int totalSchedules;
//   final int confirmedSchedules;
//   final int pendingSchedules;
//   final int completedSchedules;
//   final int cancelledSchedules;
//   final int scheduledDays;
//   final int totalDays;
//   final double scheduleRate; // 일정이 있는 날의 비율 (%)
// }

// /// 월별 일정 요약
// class MonthlyScheduleSummary {
//   const MonthlyScheduleSummary({
//     required this.month,
//     required this.totalSchedules,
//     required this.dailyCounts,
//     required this.statusCounts,
//     required this.schedules,
//   });

//   final DateTime month;
//   final int totalSchedules;
//   final Map<int, int> dailyCounts; // 일별 일정 수
//   final Map<String, int> statusCounts; // 상태별 일정 수
//   final List<ScheduleData> schedules;
// }

// /// 주별 일정 요약
// class WeeklyScheduleSummary {
//   const WeeklyScheduleSummary({
//     required this.weekStart,
//     required this.totalSchedules,
//     required this.weekdayCounts,
//     required this.statusCounts,
//     required this.schedules,
//   });

//   final DateTime weekStart;
//   final int totalSchedules;
//   final Map<int, int> weekdayCounts; // 요일별 일정 수 (1=월요일, 7=일요일)
//   final Map<String, int> statusCounts; // 상태별 일정 수
//   final List<ScheduleData> schedules;
// }
