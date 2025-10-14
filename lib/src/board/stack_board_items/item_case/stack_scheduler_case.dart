import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/src/di/service_locator.dart';
import '/src/repo/home_repo.dart';
import 'package:table_calendar/table_calendar.dart';
import '/src/board/flutter_stack_board.dart';
import '/src/repo/app_streams.dart';
import '/src/board/stack_board_items/items/stack_scheduler_item.dart';
import '/src/theme/theme_scheduler.dart';
import '/src/board/stack_board_items/item_case/common/api_utils.dart'
    as CommonApiUtils;

class StackSchedulerCase extends StatefulWidget {
  const StackSchedulerCase({
    super.key,
    required this.item,
    this.onScheduleTap,
    this.onScheduleAdd,
    this.onScheduleEdit,
    this.onScheduleDelete,
    this.onDateSelected,
    this.onViewChanged,
  });
  final StackSchedulerItem item;
  final Function(ScheduleData)? onScheduleTap;
  final Function(DateTime)? onScheduleAdd;
  final Function(ScheduleData)? onScheduleEdit;
  final Function(ScheduleData)? onScheduleDelete;
  final Function(DateTime)? onDateSelected;
  final Function(String)? onViewChanged;

  @override
  State<StackSchedulerCase> createState() => _StackSchedulerCaseState();
}

class _StackSchedulerCaseState extends State<StackSchedulerCase> {
  late StackSchedulerItem currentItem;
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late StreamSubscription _updateStackItemSub;
  late StreamSubscription _apiIdResponseSub;
  late StreamSubscription _rowResponseSub;

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late List<ScheduleData> _selectedEvents;
  late bool _isLoadingEvents;
  late bool isAllEvents;
  late Map<String, dynamic> initialValue, previousValue;
  late String theme;
  StackBoardController _controller(BuildContext context) =>
      StackBoardConfig.of(context).controller;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;
    theme = currentItem.theme;
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat =
        _getCalendarFormat(currentItem.content?.viewType ?? 'month');
    _selectedEvents = [];
    _isLoadingEvents = false;
    isAllEvents = true;
    initialValue = {};
    previousValue = {};

    _subscribeUpdateStackItem();
    _subscribeApiIdResponse();
    _subscribeRowResponse();

    // apiId가 있으면 초기화 시 자동 API 요청
    final apiId = currentItem.content?.apiId;
    if (apiId != null && apiId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEventsForDay(_selectedDay);
      });
    }
  }

  @override
  void didUpdateWidget(StackSchedulerCase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      currentItem = widget.item;
      theme = currentItem.theme;
    }
  }

  CalendarFormat _getCalendarFormat(String viewType) {
    switch (viewType) {
      case 'month':
        return CalendarFormat.month;
      case '2weeks':
        return CalendarFormat.twoWeeks;
      case 'week':
        return CalendarFormat.week;
      default:
        return CalendarFormat.month;
    }
  }

  String _getViewTypeFromFormat(CalendarFormat format) {
    switch (format) {
      case CalendarFormat.month:
        return 'month';
      case CalendarFormat.twoWeeks:
        return '2weeks';
      case CalendarFormat.week:
        return 'week';
    }
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackSchedulerItem &&
          v.boardId == widget.item.boardId) {
        final StackSchedulerItem item = v;
        setState(() {
          theme = item.theme;
          currentItem = item.copyWith(
              content: item.content?.copyWith(title: item.content?.title));
          _calendarFormat =
              _getCalendarFormat(currentItem.content?.viewType ?? 'month');
          _selectedEvents = [];

          // 위젯 업데이트 시에는 자동 로드하지 않음
        });

        homeRepo.hierarchicalControllers[widget.item.boardId]
            ?.updateItem(currentItem);
        debugPrint(
            '📝 _subscribeUpdateStackItem currentItem --> ${currentItem.toJson()}');
      }
    });
  }

  // row.json 수신 시 호출
  void _subscribeRowResponse() {
    _rowResponseSub = homeRepo.rowResponseStream.listen((v) {
      if (v != null) {
        debugPrint('StackSchedulerCase: _subscribeRowResponse v = $v');
        setState(() {
          initialValue = {...initialValue, ...v};
          previousValue = initialValue;
          isAllEvents = false;
          _onDaySelected(_selectedDay, _focusedDay);
        });
      }
    });
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub =
        CommonApiUtils.ApiUtils.subscribeApiIdResponse<StackSchedulerItem>(
      widget.item.boardId,
      widget.item.id,
      homeRepo,
      (item, receivedApiId, targetWidgetIds) =>
          _fetchResponseData(item, receivedApiId, targetWidgetIds),
    );
  }

  void _fetchResponseData(StackSchedulerItem item, String receivedApiId,
      List<String> targetWidgetIds) {
    // 기설정된 API ID이거나 강제 주입 요청인지 검사
    if (!targetWidgetIds.contains(item.id)) {
      final response = homeRepo.onApiResponse[receivedApiId];
      if (response != null) {
        debugPrint('📝 _fetchResponseData response = $response');
      } else {
        debugPrint('📝 _fetchResponseData response = null');
      }
      return;
    }

    CommonApiUtils.ApiUtils.fetchResponseData<StackSchedulerItem>(
      item,
      receivedApiId,
      homeRepo,
      widget.item.boardId,
      widget.item.id,
      (currentContent) => widget.item.copyWith(
        content: widget.item.content!.copyWith(
          apiId: receivedApiId,
          apiParameters: CommonApiUtils.ApiUtils.extractParamKeysByApiId(
              homeRepo, receivedApiId),
        ),
      ),
      (updatedItem) => homeRepo.hierarchicalControllers[widget.item.boardId]
          ?.updateItem(updatedItem),
      (updatedItem) => homeRepo.addOnTapState(updatedItem),
      (updatedItem, apiParameters) => CommonApiUtils.ApiUtils
          .updateScriptFromApiParameters<StackSchedulerItem>(
        updatedItem,
        apiParameters,
        homeRepo,
        appStreams,
        (item) => item.copyWith(
            content: item.content?.copyWith(
                script: CommonApiUtils.ApiUtils.generateScript(apiParameters))),
        (updated) => homeRepo.updateStackItemState(updated),
        (updated) => appStreams.addOnTapState(updated),
      ),
    );
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    _apiIdResponseSub.cancel();
    _rowResponseSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulerConfig = schedulerStyle(theme);
    return Column(
      children: [
        if (currentItem.content?.title?.isNotEmpty ?? false)
          _buildTitleHeader(schedulerConfig),
        _buildCalendar(schedulerConfig),
        Expanded(
          child: SingleChildScrollView(child: _buildEventList(schedulerConfig)),
        ),
      ],
    );
  }

  Widget _buildTitleHeader(SchedulerThemeConfig schedulerConfig) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: schedulerConfig.calendarBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        currentItem.content?.title ?? '',
        style: schedulerConfig.headerTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCalendar(SchedulerThemeConfig schedulerConfig) {
    return Container(
      decoration: BoxDecoration(
        color: schedulerConfig.calendarBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar<ScheduleData>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {
          CalendarFormat.month: '월별',
          CalendarFormat.twoWeeks: '2주',
          CalendarFormat.week: '주별',
        },
        eventLoader: (day) {
          // 캐시된 데이터를 표시하지 않음 (무조건 API 요청으로 최신 데이터 로드)
          return [];
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 40,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: schedulerConfig.weekendTextStyle,
          holidayTextStyle: schedulerConfig.weekendTextStyle,
          defaultTextStyle: schedulerConfig.dateTextStyle,
          selectedTextStyle: const TextStyle(
            color: Colors.white,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
          ),
          selectedDecoration: BoxDecoration(
            color: schedulerConfig.selectedDateColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: schedulerConfig.todayColor,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          cellMargin: const EdgeInsets.all(2.0),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: schedulerConfig.selectedDateColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          formatButtonTextStyle: const TextStyle(
            color: Colors.white,
          ),
          titleTextStyle: schedulerConfig.headerTextStyle,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: schedulerConfig.dateTextStyle.color,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: schedulerConfig.dateTextStyle.color,
          ),
          rightChevronVisible: true,
          leftChevronVisible: true,
        ),
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) {
            return Text(
              '${day.year}년 ${day.month}월',
              style: schedulerConfig.headerTextStyle,
            );
          },
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: schedulerConfig.weekdayTextStyle,
          weekendStyle: schedulerConfig.weekendTextStyle,
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: _onFormatChanged,
        onPageChanged: _onPageChanged,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
      ),
    );
  }

  /// 비동기 이벤트 로드 (apiId가 있을 때만 API 요청)
  Future<List<ScheduleData>> _loadEventsForDayAsync(DateTime day) async {
    final apiId = currentItem.content?.apiId;
    if (apiId == null || apiId.isEmpty) {
      return []; // apiId가 없으면 빈 목록 반환
    }
    // apiId가 있을 때만 API 요청 실행하고 해당 날짜 이벤트 반환
    return await _apiRequestForDay(day);
  }

  /// 특정 날짜에 대한 API 요청 및 이벤트 반환
  Future<List<ScheduleData>> _apiRequestForDay(DateTime day) async {
    final apiId = currentItem.content?.apiId;
    if (apiId == null) return [];

    try {
      // 1. 파라미터 준비
      final allParams = {..._prepareApiParameters(), ...initialValue};

      // 2. API 요청 실행
      homeRepo.addApiRequest(apiId, allParams);

      // 3. 응답 대기 (5초 타임아웃) - 방금 요청한 파라미터와 일치하는 응답만 사용
      final apiResponse = await _waitForApiResponse(apiId, allParams);
      if (apiResponse == null) {
        _showErrorSnackBar('API 응답 타임아웃 (5초)');
        return [];
      }

      // 4. 스케줄 데이터 처리 및 해당 날짜 이벤트 반환
      return await _processScheduleDataForDay(apiResponse, day);
    } catch (e) {
      _showErrorSnackBar('API 요청 실패: ${e.toString()}');
      return [];
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    //if (!isSameDay(_selectedDay, selectedDay)) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // 비동기로 이벤트 로드
    _loadEventsForDay(selectedDay);

    // 날짜 선택 시 콜백 호출
    widget.onDateSelected?.call(selectedDay);
    //}
  }

  /// 특정 날짜의 이벤트를 비동기로 로드 (중복 호출 방지)
  Future<void> _loadEventsForDay(DateTime day) async {
    // 이미 로딩 중이면 중복 호출 방지
    if (_isLoadingEvents) {
      return;
    }

    try {
      _isLoadingEvents = true;
      final events = await _loadEventsForDayAsync(day);
      if (mounted) {
        setState(() {
          _selectedEvents = events;
        });
      }
    } catch (e) {
      // 에러 처리
    } finally {
      _isLoadingEvents = false;
    }
  }

  /// API 파라미터 준비
  Map<String, dynamic> _prepareApiParameters() {
    final parameters = CommonApiUtils.ApiUtils.parseApiParameters(
        currentItem.content?.apiParameters);
    final scriptConfig =
        CommonApiUtils.ApiUtils.parseScriptConfig(currentItem.content?.script);

    Map<String, dynamic> allParams = {};
    for (final param in parameters) {
      String key = param['paramKey'];
      String initValue = '';

      // 스크립트 설정에 따른 값 할당
      if (scriptConfig.containsKey(key)) {
        final config = scriptConfig[key];
        initValue =
            CommonApiUtils.ApiUtils.getValueByScript(key, config!, null);
      } else {
        initValue = CommonApiUtils.ApiUtils.getDefaultValue(key, null);
      }

      // 날짜 파라미터에 실제 선택된 날짜 설정
      if (key == 'start_date' || key == 'end_date') {
        initValue = _selectedDay.toIso8601String().split('T')[0];
      }

      allParams[key] = initValue;
    }
    return allParams;
  }

  /// API 응답 대기 (5초 타임아웃)
  /// 동일 apiId 응답 중에서도 방금 요청한 파라미터와 일치하는 응답만 반환
  Future<Map<String, dynamic>?> _waitForApiResponse(
      String apiId, Map<String, dynamic> expectedParams) async {
    int attempts = 0;
    const maxAttempts = 50; // 5초 동안 100ms마다 확인

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;

      final apiResponse = homeRepo.onApiResponse[apiId];
      if (apiResponse != null && apiResponse['data'] != null) {
        // 요청 파라미터 일치 여부 확인
        final reqParams = apiResponse['reqParams'];
        if (reqParams is Map<String, dynamic>) {
          // 핵심 파라미터만 비교 (start_date, end_date, id)
          final expStart = expectedParams['start_date']?.toString();
          final expEnd = expectedParams['end_date']?.toString();
          final expId = expectedParams['id']?.toString() ?? '';

          final gotStart = reqParams['start_date']?.toString();
          final gotEnd = reqParams['end_date']?.toString();
          final gotId = reqParams['id']?.toString() ?? '';

          // 날짜와 ID가 일치하면 성공으로 간주 (빈 문자열과 null을 동일하게 처리)
          final isMatch =
              expStart == gotStart && expEnd == gotEnd && expId == gotId;

          if (isMatch) {
            debugPrint('📝 _waitForApiResponse 매칭 성공: $apiResponse');
            return apiResponse;
          } else {
            debugPrint('📝 _waitForApiResponse 매칭 실패:');
            debugPrint(
                '  expected: start_date=$expStart, end_date=$expEnd, id=$expId');
            debugPrint(
                '  received: start_date=$gotStart, end_date=$gotEnd, id=$gotId');
          }
        }
      }
    }
    debugPrint('📝 _waitForApiResponse 타임아웃: 5초 후 응답 없음');
    return null;
  }

  /// 스케줄 데이터 처리 및 특정 날짜 이벤트 반환
  Future<List<ScheduleData>> _processScheduleDataForDay(
      Map<String, dynamic> apiResponse, DateTime day) async {
    final result = apiResponse['data']['result'];
    if (result is! List) {
      // API 응답이 유효하지 않을 때 기존 캐싱된 데이터 정리
      if (mounted) {
        setState(() {
          _selectedEvents = [];
        });
      }
      return [];
    }

    // 스케줄 데이터 변환
    final List<ScheduleData> newSchedules = result.map((scheduleJson) {
      return ScheduleData(
        id: scheduleJson['id']?.toString() ?? '',
        title: scheduleJson['title']?.toString() ?? '',
        date: DateTime.parse(scheduleJson['date']?.toString() ??
            DateTime.now().toIso8601String()),
        startTime: scheduleJson['start_time']?.toString() ?? '',
        endTime: scheduleJson['end_time']?.toString() ?? '',
        description: scheduleJson['description']?.toString() ?? '',
        status: scheduleJson['status']?.toString() ?? '',
      );
    }).toList();

    // 해당 날짜의 이벤트만 먼저 필터링 (새로운 데이터만 사용)
    final dayEvents = newSchedules.where((schedule) {
      // UTC 시간을 로컬 시간으로 변환하여 비교
      final scheduleDate = schedule.date.toLocal();
      final targetDate = day;

      // 년, 월, 일만 비교 (시간 무시)
      final scheduleYear = scheduleDate.year;
      final scheduleMonth = scheduleDate.month;
      final scheduleDay = scheduleDate.day;

      final targetYear = targetDate.year;
      final targetMonth = targetDate.month;
      final targetDay = targetDate.day;

      return scheduleYear == targetYear &&
          scheduleMonth == targetMonth &&
          scheduleDay == targetDay;
    }).toList();

    // 위젯 상태 업데이트 (새로운 데이터로 완전 교체)
    if (mounted) {
      setState(() {
        // 기존 스케줄 데이터를 완전히 새로운 데이터로 교체
        currentItem = currentItem.copyWith(
          content: currentItem.content?.copyWith(schedules: newSchedules),
        );
        // 선택된 이벤트는 필터링된 결과로 설정 (빈 배열이어도 정상 처리)
        _selectedEvents = dayEvents;
      });

      // HomeRepo에 변경사항 반영
      homeRepo.hierarchicalControllers[widget.item.boardId]
          ?.updateItem(currentItem);
      homeRepo.addOnTapState(currentItem);

      // 빈 결과일 때도 적절한 메시지 표시
      if (dayEvents.isEmpty) {
        _showSuccessSnackBar('해당 날짜에 등록된 스케줄이 없습니다.');
      } else {
        _showSuccessSnackBar('스케줄 데이터 ${dayEvents.length}건을 불러왔습니다.');
      }
    }

    return dayEvents;
  }

  /// 성공 메시지 표시
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
      // 달력 형식 변경 시 위젯 다시 그리기
    });
    final viewType = _getViewTypeFromFormat(format);
    final item = widget.item.setViewType(viewType);
    _controller(context).updateItem(item);
    widget.onViewChanged?.call(viewType);
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;

    // 달력 페이지 변경 시에는 자동 로드하지 않음 (사용자가 일자를 선택할 때만 로드)
  }

  Widget _buildEventList(SchedulerThemeConfig schedulerConfig) {
    return Column(
      children: [
        // 헤더
        Container(
          decoration: BoxDecoration(
            color: schedulerConfig.eventListHeaderColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDay.month}월 ${_selectedDay.day}일 ${isAllEvents ? '전체' : ''} 일정',
                  style: schedulerConfig.headerTextStyle,
                ),
                Row(
                  children: [
                    Text(
                      '${_selectedEvents.length}개',
                      style: TextStyle(
                        fontSize: 14,
                        color: schedulerConfig.dateTextStyle.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _onAddSchedule,
                      tooltip: '일정 추가',
                    ),
                    if (initialValue != {} &&
                        previousValue != {} &&
                        !isAllEvents) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: isAllEvents
                            ? const Icon(Icons.person)
                            : const Icon(Icons.group),
                        onPressed: () {
                          setState(() {
                            isAllEvents = !isAllEvents;
                            initialValue = isAllEvents ? {} : previousValue;
                            _onDaySelected(_selectedDay, _focusedDay);
                          });
                        },
                        tooltip: '전체 일정 보기',
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
        // 일정 목록
        _isLoadingEvents
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : _selectedEvents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '등록된 일정이 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      return _buildEventCard(event, schedulerConfig);
                    },
                  ),
      ],
    );
  }

  Widget _buildEventCard(
      ScheduleData event, SchedulerThemeConfig schedulerConfig) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: schedulerConfig.eventCardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: schedulerConfig.eventCardBorderColor),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: event.color ?? schedulerConfig.selectedDateColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          event.title,
          style: schedulerConfig.headerTextStyle,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.startTime != null && event.endTime != null)
              Text(
                '${event.startTime} - ${event.endTime}',
                style: schedulerConfig.dateTextStyle,
              ),
            if (event.description != null && event.description!.isNotEmpty)
              Text(
                event.description!,
                style: schedulerConfig.dateTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleScheduleAction(value, event),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('수정'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('삭제'),
            ),
          ],
        ),
        onTap: () => _showEditScheduleDialog(event),
      ),
    );
  }

  void _onAddSchedule() {
    widget.onScheduleAdd?.call(_selectedDay);
    showDialog(
      context: context,
      builder: (context) => _ScheduleEditDialog(
        date: _selectedDay,
        onSave: (schedule) {
          _addSchedule(schedule);
        },
      ),
    );
  }

  void _showEditScheduleDialog(ScheduleData schedule) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleEditDialog(
        date: _selectedDay,
        schedule: schedule,
        onSave: (updatedSchedule) {
          _updateSchedule(updatedSchedule);
        },
      ),
    );
  }

  void _handleScheduleAction(String action, ScheduleData schedule) {
    switch (action) {
      case 'edit':
        _showEditScheduleDialog(schedule);
        break;
      case 'delete':
        _showDeleteConfirmDialog(schedule);
        break;
    }
  }

  void _showDeleteConfirmDialog(ScheduleData schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('"${schedule.title}" 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _deleteSchedule(schedule.id);
              Navigator.of(context).pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSchedule(ScheduleData event) async {
    final apiId = currentItem.content?.postApiId;
    if (apiId == null || apiId.isEmpty) {
      _showErrorSnackBar('생성 API가 설정되어 있지 않습니다.');
      return;
    }

    final params = _buildCrudParams(apiId, schedule: event);
    // 요청 실행 (_apiRequestForDay와 동일한 패턴)
    homeRepo.addApiRequest(apiId, params);
    final resp = await _waitForApiResponse(apiId, params);
    if (resp == null) {
      _showErrorSnackBar('일정 추가 응답 타임아웃 (5초)');
      return;
    }
    _showSuccessSnackBar('일정이 추가되었습니다.');
    await _refreshCurrentDayWithRetry();
  }

  Future<void> _updateSchedule(ScheduleData event) async {
    final apiId = currentItem.content?.putApiId;
    if (apiId == null || apiId.isEmpty) {
      _showErrorSnackBar('수정 API가 설정되어 있지 않습니다.');
      return;
    }

    final params = _buildCrudParams(apiId, schedule: event);
    homeRepo.addApiRequest(apiId, params);
    final resp = await _waitForApiResponse(apiId, params);
    if (resp == null) {
      _showErrorSnackBar('일정 수정 응답 타임아웃 (5초)');
      return;
    }
    _showSuccessSnackBar('일정이 수정되었습니다.');
    await _refreshCurrentDayWithRetry();
  }

  Future<void> _deleteSchedule(String eventId) async {
    final apiId = currentItem.content?.deleteApiId;
    if (apiId == null || apiId.isEmpty) {
      _showErrorSnackBar('삭제 API가 설정되어 있지 않습니다.');
      return;
    }

    // 대상 일정 조회(존재하지 않아도 id만으로 진행 가능)
    final schedule = currentItem.content?.schedules?.firstWhere(
      (s) => s.id == eventId,
      orElse: () => ScheduleData(id: eventId, title: '', date: DateTime.now()),
    );

    final params = _buildCrudParams(apiId, schedule: schedule);
    homeRepo.addApiRequest(apiId, params);
    final resp = await _waitForApiResponse(apiId, params);
    if (resp == null) {
      _showErrorSnackBar('일정 삭제 응답 타임아웃 (5초)');
      return;
    }
    _showSuccessSnackBar('일정이 삭제되었습니다.');
    await _refreshCurrentDayWithRetry();
  }

  /// 현재 선택일자 강제 재조회 + 짧은 재시도로 UI 동기화 보강
  Future<void> _refreshCurrentDayWithRetry() async {
    final previous = List<ScheduleData>.from(_selectedEvents);
    const int maxAttempts = 5;
    for (int i = 0; i < maxAttempts; i++) {
      final events = await _loadEventsForDayAsync(_selectedDay);
      if (mounted) {
        setState(() {
          _selectedEvents = events;
        });
      }
      if (_areSchedulesDifferent(previous, events)) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  bool _areSchedulesDifferent(List<ScheduleData> a, List<ScheduleData> b) {
    if (identical(a, b)) return false;
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].title != b[i].title ||
          a[i].startTime != b[i].startTime ||
          a[i].endTime != b[i].endTime ||
          a[i].status != b[i].status ||
          a[i].description != b[i].description) {
        return true;
      }
    }
    return false;
  }

  /// CRUD API 메타의 parameters를 읽어 스케줄에서 값 매핑 (범용, 하드코딩 최소화)
  Map<String, dynamic> _buildCrudParams(String apiId,
      {ScheduleData? schedule}) {
    // initialValue에서 null이나 빈 문자열이 아닌 값만 사용
    final params = <String, dynamic>{};
    initialValue.forEach((key, value) {
      if (value != null && (value is! String || value.isNotEmpty)) {
        params[key] = value;
      }
    });

    final api = homeRepo.apis[apiId];
    if (api == null) return params;

    List<dynamic> paramDefs = [];
    try {
      final raw = api['parameters'];
      if (raw != null && raw.toString().isNotEmpty) {
        paramDefs = raw is String ? jsonDecode(raw) : (raw as List<dynamic>);
      }
    } catch (_) {
      // ignore
    }

    String? toDateStr(DateTime? dt) =>
        dt?.toIso8601String().split('T').first; // YYYY-MM-DD

    String? toTimeStr(String? t) {
      if (t == null || t.isEmpty) return '00:00:00';
      final s = t.trim();
      // HH:mm -> HH:mm:00 보정
      final hhmm = RegExp(r'^\d{2}:\d{2}$');
      if (hhmm.hasMatch(s)) return '$s:00';
      // HHmm -> HH:mm:00 보정
      final hhmmComp = RegExp(r'^(\d{2})(\d{2})$');
      final m = hhmmComp.firstMatch(s);
      if (m != null) return '${m.group(1)}:${m.group(2)}:00';
      // 이미 HH:mm:ss 또는 기타 포맷은 그대로
      return s;
    }

    for (final def in paramDefs) {
      if (def is! Map) continue;
      final key = def['paramKey']?.toString();
      if (key == null || key.isEmpty) continue;

      dynamic value;
      // 스케줄 필드명과 paramKey가 동일/유사할 때 자동 매핑
      switch (key) {
        case 'id':
          // 수정 시에는 schedule의 id를, 생성 시에는 initialValue의 id를 사용
          value = schedule?.id ?? initialValue['id'];
          break;
        case 'title':
          value = schedule?.title;
          break;
        case 'notes':
          // 서버가 notes에서 title|description 분리하는 경우 지원
          final title = schedule?.title ?? '';
          final desc = schedule?.description ?? '';
          value = '$title|$desc';
          break;
        case 'date':
          value = toDateStr(schedule?.date);
          break;
        case 'start_time':
          value = toTimeStr(schedule?.startTime);
          break;
        case 'end_time':
          value = toTimeStr(schedule?.endTime);
          break;
        case 'description':
          value = schedule?.description;
          break;
        case 'status':
          value = schedule?.status;
          break;
        case 'created_by':
        case 'user_id':
          // initialValue에서 user_id를 가져오거나, 없으면 기본값 사용
          value = initialValue['user_id'] ?? initialValue['id'] ?? '1';
          break;
        default:
          // 기본값은 빈 문자열로 채움 (서버에서 선택적 처리)
          value = '';
      }

      value ??= '';
      params[key] = value;
    }

    return params;
  }
}

class _ScheduleEditDialog extends StatefulWidget {
  const _ScheduleEditDialog({
    required this.date,
    this.schedule,
    required this.onSave,
  });
  final DateTime date;
  final ScheduleData? schedule;
  final Function(ScheduleData) onSave;
  @override
  State<_ScheduleEditDialog> createState() => _ScheduleEditDialogState();
}

class _ScheduleEditDialogState extends State<_ScheduleEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  String _status = '예정';
  Color _color = Colors.blue;
  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.schedule?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.schedule?.description ?? '');

    // 시간 기본값: 새 일정 추가 시 현재시간, 현재시간+1h
    String fmtTime(DateTime dt) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final now = DateTime.now();
    final defStart = fmtTime(widget.schedule?.date ?? now);
    final defEnd =
        fmtTime((widget.schedule?.date ?? now).add(const Duration(hours: 1)));

    _startTimeController =
        TextEditingController(text: widget.schedule?.startTime ?? defStart);
    _endTimeController =
        TextEditingController(text: widget.schedule?.endTime ?? defEnd);
    // 상태 초기화: 허용값 이외면 기본값으로 보정
    const allowedStatuses = ['예정', '확정', '완료', '취소'];
    final initStatus = widget.schedule?.status?.trim();
    _status = (initStatus != null && allowedStatuses.contains(initStatus))
        ? initStatus
        : '예정';
    _color = widget.schedule?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule == null ? '일정 추가' : '일정 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _HourStepper(
                  label: '시작 시간',
                  controller: _startTimeController,
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: _HourStepper(
                  label: '종료 시간',
                  controller: _endTimeController,
                )),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: const ['예정', '확정', '완료', '취소'].contains(_status)
                  ? _status
                  : null,
              decoration: const InputDecoration(
                labelText: '상태',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '예정', child: Text('예정')),
                DropdownMenuItem(value: '확정', child: Text('확정')),
                DropdownMenuItem(value: '완료', child: Text('완료')),
                DropdownMenuItem(value: '취소', child: Text('취소')),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value ?? '예정';
                });
              },
              hint: const Text('상태 선택'),
            ),
            const SizedBox(height: 16),
            Text(
              '날짜: ${widget.date.year}년 ${widget.date.month}월 ${widget.date.day}일',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _saveSchedule,
          child: const Text('저장'),
        ),
      ],
    );
  }

  void _saveSchedule() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    // 입력값 정규화 (빈 값이면 기본값 적용)
    String normalizeTime(String v) {
      final s = v.trim();
      if (s.isEmpty) return '00:00';
      return s;
    }

    final schedule = ScheduleData(
      id: widget.schedule?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      date: widget.schedule?.date ?? widget.date,
      startTime: normalizeTime(_startTimeController.text),
      endTime: normalizeTime(_endTimeController.text),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      status: _status,
      color: _color,
      userId: widget.schedule?.userId ?? 'user1',
    );
    widget.onSave(schedule);
    Navigator.of(context).pop();
  }
}

class _HourStepper extends StatefulWidget {
  const _HourStepper({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;
  @override
  State<_HourStepper> createState() => _HourStepperState();
}

class _HourStepperState extends State<_HourStepper> {
  late int hour;

  @override
  void initState() {
    super.initState();
    hour = int.tryParse(widget.controller.text.split(':').first) ?? 0;
    hour = hour.clamp(0, 23);
    _sync();
  }

  void _sync() {
    final hh = hour.toString().padLeft(2, '0');
    widget.controller.text = '$hh:00';
  }

  void _inc() {
    setState(() {
      hour = (hour + 1) % 24;
      _sync();
    });
  }

  void _dec() {
    setState(() {
      hour = (hour - 1) < 0 ? 23 : (hour - 1);
      _sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: _dec, icon: const Icon(Icons.remove)),
        Expanded(
          child: TextField(
            controller: widget.controller,
            readOnly: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(onPressed: _inc, icon: const Icon(Icons.add)),
      ],
    );
  }
}
