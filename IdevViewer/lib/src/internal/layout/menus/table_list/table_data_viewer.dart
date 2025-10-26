import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:idev_viewer/src/internal/core/api/api_service.dart';
import 'package:idev_viewer/src/internal/pms/model/behavior.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/pms/model/api_response.dart';
import 'package:idev_viewer/src/internal/layout/menus/table_list/table_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dio/dio.dart';
import 'package:idev_viewer/src/internal/core/config/env.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/core/api/api_endpoint_ide.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class TableDataViewer extends StatefulWidget {
  final String tableName;
  final List<ColumnInfo> columns;

  const TableDataViewer({
    super.key,
    required this.tableName,
    required this.columns,
  });

  @override
  State<TableDataViewer> createState() => _TableDataViewerState();
}

class _TableDataViewerState extends State<TableDataViewer> {
  late PlutoGridStateManager stateManager;
  late ApiService apiService;
  List<PlutoRow> rows = [];
  List<String> actualColumns = []; // 실제 데이터의 컬럼명
  bool isLoading = true;
  String? errorMessage;
  int totalCount = 0;
  int currentPage = 1;
  int pageSize = 100;

  @override
  void initState() {
    super.initState();
    apiService = sl<ApiService>();
    _loadTableData();
  }

  Future<void> _loadTableData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // JSON 형식으로 데이터 요청
      final response = await apiService.requestApi(
        uri: '/idev/v1/table/${widget.tableName}/data',
        method: Method.get,
        headers: {'X-Tenant-Id': 'skydbdbgmail'},
        data: {
          'limit': pageSize,
          'offset': (currentPage - 1) * pageSize,
        },
      );

      if (response.result == 0 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rowsData = data['rows'] as List<dynamic>? ?? [];
        final totalCountData = data['totalCount'] as int? ?? rowsData.length;

        // 디버깅을 위한 로그 추가
        print('=== 테이블 데이터 디버깅 ===');
        print('테이블명: ${widget.tableName}');
        print('컬럼 정보: ${widget.columns.map((c) => c.columnName).toList()}');
        print('응답 데이터: $data');
        print('rowsData 길이: ${rowsData.length}');
        if (rowsData.isNotEmpty) {
          print('첫 번째 행 데이터: ${rowsData.first}');
          print(
              '첫 번째 행의 키들: ${(rowsData.first as Map<String, dynamic>).keys.toList()}');
          print(
              '첫 번째 행의 값들: ${(rowsData.first as Map<String, dynamic>).values.toList()}');
        } else {
          print('⚠️ rowsData가 비어있습니다!');
        }

        // 실제 데이터에서 컬럼명 추출
        if (rowsData.isNotEmpty) {
          actualColumns =
              (rowsData.first as Map<String, dynamic>).keys.toList();
          print('실제 데이터의 컬럼명: $actualColumns');
        }

        setState(() {
          totalCount = totalCountData;
          rows = rowsData.map((rowData) {
            final rowMap = rowData as Map<String, dynamic>;

            // 실제 컬럼명을 기반으로 PlutoRow 생성
            final cells = <String, PlutoCell>{};
            for (final columnName in actualColumns) {
              final cellValue = rowMap[columnName]?.toString() ?? '';
              cells[columnName] = PlutoCell(value: cellValue);
              print('컬럼 $columnName: $cellValue');
            }

            return PlutoRow(cells: cells);
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.reason ?? '데이터를 불러올 수 없습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '오류가 발생했습니다: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D30),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.table_chart,
                  color: Colors.blue.shade400,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.tableName} 데이터',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // API 자동 생성 버튼
                IconButton(
                  onPressed: () => _showApiGenerationDialog(),
                  icon: const Icon(Icons.api, color: Colors.blue),
                  tooltip: 'API 자동 생성',
                ),
                // CSV 업로드 버튼
                IconButton(
                  onPressed: () => _uploadCsvToExistingTable(),
                  icon: const Icon(Icons.upload_file, color: Colors.green),
                  tooltip: 'CSV 파일 업로드',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 통계 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E42),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildStatItem('총 행 수', totalCount.toString()),
                  const SizedBox(width: 24),
                  _buildStatItem('컬럼 수', widget.columns.length.toString()),
                  const SizedBox(width: 24),
                  _buildStatItem('현재 페이지',
                      '$currentPage / ${(totalCount / pageSize).ceil()}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 데이터 그리드
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTableData,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        )
                      : _buildDataGrid(),
            ),

            // 페이지네이션
            if (!isLoading && errorMessage == null && totalCount > pageSize)
              _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFCCCCCC),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDataGrid() {
    if (rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_rows,
              size: 48,
              color: Color(0xFF6A6A6A),
            ),
            SizedBox(height: 16),
            Text(
              '데이터가 없습니다.',
              style: TextStyle(
                color: Color(0xFF6A6A6A),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return PlutoGrid(
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBackgroundColor: const Color(0xFF2D2D30),
          rowColor: const Color(0xFF2D2D30),
          evenRowColor: const Color(0xFF3E3E42),
          columnTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          cellTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          borderColor: const Color(0xFF6A6A6A),
          activatedBorderColor: Colors.blue.shade400,
          inactivatedBorderColor: const Color(0xFF6A6A6A),
          gridBorderColor: const Color(0xFF6A6A6A),
          activatedColor: const Color(0xFF094771),
          iconColor: Colors.white,
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.scale,
        ),
        scrollbar: const PlutoGridScrollbarConfig(),
      ),
      columns: actualColumns.map((columnName) {
        return PlutoColumn(
          title: columnName,
          field: columnName,
          type: PlutoColumnType.text(), // 기본적으로 텍스트 타입으로 설정
          width: _getColumnWidth(columnName),
          enableContextMenu: false,
          enableDropToResize: true,
          enableSorting: true,
          titleSpan: TextSpan(
            children: [
              TextSpan(text: columnName),
            ],
          ),
        );
      }).toList(),
      rows: rows,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        stateManager = event.stateManager;
      },
    );
  }

  Widget _buildPagination() {
    final totalPages = (totalCount / pageSize).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? _previousPage : null,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            '페이지 $currentPage / $totalPages',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: currentPage < totalPages ? _nextPage : null,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _loadTableData();
    }
  }

  void _nextPage() {
    final totalPages = (totalCount / pageSize).ceil();
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _loadTableData();
    }
  }

  double _getColumnWidth(String columnName) {
    // 컬럼명 길이에 따라 동적 너비 설정
    final baseWidth = columnName.length * 8.0 + 40;
    return baseWidth.clamp(100.0, 300.0);
  }

  // 기존 테이블에 CSV 업로드
  Future<void> _uploadCsvToExistingTable() async {
    try {
      // 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // 사용자가 취소
      }

      final file = result.files.first;
      final fileName = file.name;

      // 웹과 모바일/데스크톱 환경 구분
      Uint8List? fileBytes = file.bytes;
      String? filePath;

      if (fileBytes == null) {
        // 모바일/데스크톱 환경에서만 path 접근
        filePath = file.path;
        if (filePath == null) {
          throw Exception('파일을 읽을 수 없습니다.');
        }
      }

      if (fileBytes == null && filePath == null) {
        throw Exception('파일을 읽을 수 없습니다.');
      }

      // 파일 크기 검증 (50MB 제한)
      int fileSize;
      if (fileBytes != null) {
        fileSize = fileBytes.length;
      } else {
        fileSize = await File(filePath!).length();
      }

      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('파일 크기가 50MB를 초과합니다.');
      }

      // 업로드 진행
      await _uploadCsvFile(filePath, fileBytes, fileName);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('CSV 업로드 중 오류가 발생했습니다: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV 업로드 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // CSV 파일 업로드 실행
  Future<void> _uploadCsvFile(
    String? filePath,
    Uint8List? fileBytes,
    String fileName,
  ) async {
    try {
      EasyLoading.show(status: 'CSV 파일 업로드 중...');

      // FormData 생성 - 플랫폼별 처리
      MultipartFile multipartFile;
      if (fileBytes != null) {
        // 웹 환경: bytes 사용
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      } else {
        // 모바일/데스크톱 환경: file path 사용
        multipartFile = await MultipartFile.fromFile(
          filePath!,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'csv': multipartFile,
        'tableName': widget.tableName, // 현재 테이블명 사용
        'createTable': 'false', // 기존 테이블에 데이터 추가
      });

      // 디버깅을 위한 로그 추가
      print('=== 기존 테이블 CSV 업로드 디버깅 ===');
      print('테이블명: ${widget.tableName}');
      print('파일명: $fileName');
      print('파일 크기: ${fileBytes?.length ?? 'N/A'} bytes');
      print('createTable: false (기존 테이블 사용)');

      // Dio를 직접 사용하여 FormData 전송
      final dio = Dio();
      final apiHost = AppConfig.instance.getApiHost('/csv-upload');
      final response = await dio.post(
        '$apiHost/idev/v1/csv-upload',
        data: formData,
        options: Options(
          headers: {'X-Tenant-Id': 'skydbdbgmail'},
        ),
      );

      print('업로드 응답: ${response.data}');

      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse.result == 0 && apiResponse.data != null) {
        final data = apiResponse.data as Map<String, dynamic>;
        final rowsImported = data['rowsImported'] ?? 0;

        EasyLoading.dismiss();

        if (mounted) {
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'CSV 파일이 성공적으로 업로드되었습니다.\n'
                '추가된 행: $rowsImported개',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // 데이터 새로고침
          _loadTableData();
        }
      } else {
        EasyLoading.dismiss();
        throw Exception(apiResponse.reason ?? 'CSV 업로드에 실패했습니다.');
      }
    } catch (e) {
      EasyLoading.dismiss();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // API 자동 생성 다이얼로그 표시
  void _showApiGenerationDialog() {
    // HomeRepo 인스턴스 가져오기
    final homeRepo = context.read<HomeRepo>();

    showDialog(
      context: context,
      builder: (context) => _ApiGenerationDialog(
        tableName: widget.tableName,
        homeRepo: homeRepo,
        columns: widget.columns,
      ),
    );
  }
}

// API 자동 생성 다이얼로그 위젯
class _ApiGenerationDialog extends StatefulWidget {
  final String tableName;
  final HomeRepo homeRepo;
  final List<ColumnInfo> columns;

  const _ApiGenerationDialog({
    required this.tableName,
    required this.homeRepo,
    required this.columns,
  });

  @override
  State<_ApiGenerationDialog> createState() => _ApiGenerationDialogState();
}

class _ApiGenerationDialogState extends State<_ApiGenerationDialog> {
  late TextEditingController _idPrefixController;
  late TextEditingController _nameController;
  late TextEditingController _uriController;

  bool _isSelect = true;
  bool _isInsert = true;
  bool _isUpdate = true;
  bool _isDelete = true;

  @override
  void initState() {
    super.initState();
    _idPrefixController = TextEditingController(text: 'IF-');
    _nameController = TextEditingController(text: widget.tableName);
    _uriController =
        TextEditingController(text: '/${widget.tableName.toLowerCase()}');
  }

  @override
  void dispose() {
    _idPrefixController.dispose();
    _nameController.dispose();
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D30),
      title: Text(
        '${widget.tableName} API 자동 생성',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID Prefix
            _buildTextField(
              controller: _idPrefixController,
              label: 'ID Prefix',
              hint: 'IF-',
            ),
            const SizedBox(height: 16),

            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              hint: widget.tableName,
            ),
            const SizedBox(height: 16),

            // Method 선택
            const Text(
              'Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Method 체크박스들을 2x2로 배치
            Row(
              children: [
                Expanded(
                  child: _buildMethodCheckbox('조회 (GET)', _isSelect, (value) {
                    setState(() {
                      _isSelect = value ?? false;
                    });
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMethodCheckbox('추가 (POST)', _isInsert, (value) {
                    setState(() {
                      _isInsert = value ?? false;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMethodCheckbox('수정 (PUT)', _isUpdate, (value) {
                    setState(() {
                      _isUpdate = value ?? false;
                    });
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child:
                      _buildMethodCheckbox('삭제 (DELETE)', _isDelete, (value) {
                    setState(() {
                      _isDelete = value ?? false;
                    });
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Uri
            _buildTextField(
              controller: _uriController,
              label: 'Uri',
              hint: '/${widget.tableName.toLowerCase()}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '닫기',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _generateApi,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF3C3C3C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCheckbox(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.blue,
    );
  }

  void _generateApi() {
    // 선택된 메서드들 수집
    List<String> selectedMethods = [];
    if (_isSelect) selectedMethods.add('GET');
    if (_isInsert) selectedMethods.add('POST');
    if (_isUpdate) selectedMethods.add('PUT');
    if (_isDelete) selectedMethods.add('DELETE');

    if (selectedMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 하나의 메서드를 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 유효성 검증 수행
    _validateApiGeneration(selectedMethods);
  }

  // API 생성 전 유효성 검증
  void _validateApiGeneration(List<String> methods) {
    List<String> conflicts = [];

    print('=== API 유효성 검증 시작 ===');
    print('선택된 메서드: $methods');
    print('기존 API 수: ${widget.homeRepo.apis.length}');

    // 각 메서드별로 생성될 API ID와 URI 확인
    for (String method in methods) {
      String crudType = _getCrudType(method);
      String apiId =
          '${_idPrefixController.text}${widget.tableName.toUpperCase()}-$crudType';
      String uri = _uriController.text;

      print('메서드: $method, CRUD 타입: $crudType');
      print('생성될 API ID: $apiId');
      print('생성될 URI: $uri');

      // 기존 API ID 중복 체크
      if (widget.homeRepo.apis.containsKey(apiId)) {
        conflicts.add('API ID "$apiId"가 이미 존재합니다.');
        print('❌ API ID 중복 발견: $apiId');
      } else {
        print('✅ API ID 사용 가능: $apiId');
      }

      // 기존 URI 중복 체크 (같은 메서드와 URI 조합)
      bool uriConflict = widget.homeRepo.apis.values.any((api) {
        return api['method']?.toString().toUpperCase() ==
                method.toUpperCase() &&
            api['uri']?.toString() == uri;
      });

      if (uriConflict) {
        conflicts.add('URI "$uri"와 메서드 "$method" 조합이 이미 존재합니다.');
        print('❌ URI+메서드 조합 중복 발견: $uri + $method');
      } else {
        print('✅ URI+메서드 조합 사용 가능: $uri + $method');
      }
    }

    print('발견된 충돌 수: ${conflicts.length}');
    if (conflicts.isNotEmpty) {
      print('충돌 내용: $conflicts');
    }
    print('========================');

    if (conflicts.isNotEmpty) {
      // 중복 발견 시 확인창 표시
      _showValidationDialog(conflicts, methods);
    } else {
      // 중복이 없으면 바로 API 생성
      _createApis(methods);
    }
  }

  // 유효성 검증 실패 시 확인창 표시
  void _showValidationDialog(List<String> conflicts, List<String> methods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D30),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade400),
            const SizedBox(width: 8),
            const Text(
              'API 생성 불가',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '다음과 같은 이유로 API를 생성할 수 없습니다:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3E42),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: conflicts
                      .map((conflict) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade400,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    conflict,
                                    style: TextStyle(
                                      color: Colors.red.shade300,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '다음 중 하나를 선택해주세요:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• ID Prefix나 URI를 변경하여 다시 시도\n• 기존 API를 수정하거나 삭제 후 재시도',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 강제로 생성하도록 옵션 제공 (향후 구현 가능)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('설정 수정'),
          ),
        ],
      ),
    );
  }

  void _createApis(List<String> methods) async {
    try {
      EasyLoading.show(status: 'API 생성 중...');

      int successCount = 0;
      List<String> createdApis = [];

      // 각 메서드별로 API 생성
      for (String method in methods) {
        try {
          String crudType = _getCrudType(method);
          String apiId =
              '${_idPrefixController.text}${widget.tableName.toUpperCase()}-$crudType';

          // SQL 쿼리에서 파라미터 추출
          String sqlQuery = _generateSqlQuery(method, crudType);
          List<Map<String, dynamic>> parameters =
              _extractParametersFromSql(sqlQuery, method);

          // API 생성 요청 body 데이터 (api_popup_dialog.dart와 동일한 형식)
          Map<String, dynamic> bodyData = {
            'api_id': apiId,
            'api_nm': '${_nameController.text} $crudType',
            'description': '[$apiId] ${_nameController.text} $crudType API',
            'method': method.toUpperCase(),
            'uri': _uriController.text,
            'sql_query': sqlQuery,
            'parameters': jsonEncode(parameters),
            'request': '{}',
            'response': '{}',
          };

          // 디버깅을 위한 로그 출력
          print('=== API 생성 요청 데이터 ===');
          print('API ID: $apiId');
          print('Method: $method');
          print('URI: ${_uriController.text}');
          print('SQL Query: $sqlQuery');
          print('Parameters: $parameters');
          print('Body Data: $bodyData');
          print('========================');

          // ApiService를 직접 사용하여 API 생성 요청 (HomeRepo의 reqIdeApi 문제 회피)
          final apiService = sl<ApiService>();
          final response = await apiService.requestApi(
            uri: ApiEndpointIDE.apis,
            method: Method.post,
            data: bodyData,
            headers: {'X-Tenant-Id': 'skydbdbgmail'},
          );

          if (response.result == 0) {
            print('API 생성 성공: $apiId');
          } else {
            print('API 생성 실패: ${response.reason}');
          }

          createdApis.add(apiId);
          successCount++;

          print('API 생성 요청 완료: $apiId - $method');
        } catch (e) {
          print(
              'API 생성 실패: ${_idPrefixController.text}${widget.tableName.toUpperCase()}-${_getCrudType(method)} - $e');
        }
      }

      // API 목록 새로고침을 위한 지연
      await Future.delayed(const Duration(milliseconds: 1500));

      EasyLoading.dismiss();

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'API 생성 완료!\n'
              '생성된 API: $successCount개\n'
              'Methods: ${methods.join(', ')}\n'
              'API IDs: ${createdApis.join(', ')}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API 생성에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      EasyLoading.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API 생성 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _getCrudType(String method) {
    switch (method) {
      case 'GET':
        return 'R'; // Read
      case 'POST':
        return 'C'; // Create
      case 'PUT':
        return 'U'; // Update
      case 'DELETE':
        return 'D'; // Delete
      default:
        return 'R';
    }
  }

  String _generateSqlQuery(String method, String crudType) {
    String tableName = widget.tableName;

    // TableDataViewer에서 받은 컬럼 정보 사용
    final columns = widget.columns;

    print('=== SQL 쿼리 생성 디버깅 ===');
    print('테이블명: $tableName (대소문자 유지)');
    print('메서드: $method');
    print('컬럼 수: ${columns.length}');
    print(
        '컬럼 목록: ${columns.map((c) => '${c.columnName}(${c.dataType})').toList()}');

    if (columns.isEmpty) {
      print('⚠️ 컬럼 정보가 없어 기본값 사용');
      // 컬럼 정보가 없는 경우 기본값 사용
      switch (method) {
        case 'GET':
          return 'SELECT * FROM $tableName WHERE id = :id';
        case 'POST':
          return 'INSERT INTO $tableName (name, email) VALUES (:name, :email)';
        case 'PUT':
          return 'UPDATE $tableName SET name = :name, email = :email WHERE id = :id';
        case 'DELETE':
          return 'DELETE FROM $tableName WHERE id = :id';
        default:
          return 'SELECT * FROM $tableName WHERE id = :id';
      }
    }

    String sqlQuery;
    switch (method) {
      case 'GET':
        sqlQuery = 'SELECT * FROM $tableName WHERE id = :id';
        break;
      case 'POST':
        // INSERT 쿼리 생성 - 실제 테이블 컬럼 사용
        final insertColumns = columns
            .where((col) => col.columnName.toLowerCase() != 'id') // ID는 제외
            .map((col) => col.columnName)
            .toList();
        final insertValues = insertColumns.map((col) => ':$col').toList();
        sqlQuery =
            'INSERT INTO $tableName (${insertColumns.join(', ')}) VALUES (${insertValues.join(', ')})';
        print('INSERT 컬럼: $insertColumns');
        break;
      case 'PUT':
        // UPDATE 쿼리 생성 - 실제 테이블 컬럼 사용
        final updateColumns = columns
            .where((col) => col.columnName.toLowerCase() != 'id') // ID는 제외
            .map((col) => '${col.columnName} = :${col.columnName}')
            .toList();
        sqlQuery =
            'UPDATE $tableName SET ${updateColumns.join(', ')} WHERE id = :id';
        print(
            'UPDATE 컬럼: ${updateColumns.map((c) => c.split(' = ')[0]).toList()}');
        break;
      case 'DELETE':
        sqlQuery = 'DELETE FROM $tableName WHERE id = :id';
        break;
      default:
        sqlQuery = 'SELECT * FROM $tableName WHERE id = :id';
    }

    print('생성된 SQL: $sqlQuery');
    print('========================');
    return sqlQuery;
  }

  // SQL 쿼리에서 파라미터 추출 (api_popup_dialog.dart의 _validateApi 메서드 참고)
  List<Map<String, dynamic>> _extractParametersFromSql(
      String sqlQuery, String method) {
    List<Map<String, dynamic>> parameters = [];

    // {:컬럼명} 패턴을 찾는 정규식
    final regex = RegExp(r':(\w+)');
    final paramKeys =
        regex.allMatches(sqlQuery).map((e) => e.group(1)).toSet().toList();

    // TableDataViewer에서 받은 컬럼 정보 사용
    final columns = widget.columns;

    print('=== 파라미터 추출 디버깅 ===');
    print('SQL 쿼리: $sqlQuery');
    print('메서드: $method');
    print('추출된 파라미터 키: $paramKeys');
    print('테이블 컬럼 수: ${columns.length}');

    // GET, DELETE는 query 파라미터, POST, PUT은 body 파라미터
    final inParams = ['get', 'delete'].contains(method.toLowerCase())
        ? {'in': 'query'}
        : {'in': 'body'};

    for (final paramKey in paramKeys) {
      if (paramKey == null) continue; // null 체크

      // 실제 테이블 컬럼 정보에서 해당 컬럼 찾기
      final columnInfo = columns.firstWhere(
        (col) => col.columnName.toLowerCase() == paramKey.toLowerCase(),
        orElse: () => ColumnInfo(
          columnName: paramKey,
          dataType: 'VARCHAR',
          isNullable: true,
          isPrimaryKey: false,
          isUnique: false,
        ),
      );

      // 데이터 타입에 따른 파라미터 타입 결정
      String paramType = 'string';
      if (columnInfo.dataType.toUpperCase().contains('INT')) {
        paramType = 'integer';
      } else if (columnInfo.dataType.toUpperCase().contains('DECIMAL') ||
          columnInfo.dataType.toUpperCase().contains('FLOAT') ||
          columnInfo.dataType.toUpperCase().contains('DOUBLE')) {
        paramType = 'number';
      } else if (columnInfo.dataType.toUpperCase().contains('DATE') ||
          columnInfo.dataType.toUpperCase().contains('TIME')) {
        paramType = 'string'; // 날짜/시간은 문자열로 처리
      }

      final param = {
        'paramKey': paramKey,
        'type': paramType,
        'isRequired': columnInfo.isNullable ? 'false' : 'true',
        'description': '${columnInfo.columnName} (${columnInfo.dataType})',
        ...inParams
      };

      parameters.add(param);
      print('파라미터 추가: $param');
    }

    print('최종 파라미터 수: ${parameters.length}');
    print('========================');
    return parameters;
  }
}

// ColumnInfo는 table_list.dart에서 import하여 사용
