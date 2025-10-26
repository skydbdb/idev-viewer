import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/layout/menus/table_list/table_data_viewer.dart';
import 'package:idev_viewer/src/internal/layout/menus/table_list/csv_downloader.dart';
import 'package:idev_viewer/src/internal/layout/menus/table_list/csv_uploader.dart';
import 'package:idev_viewer/src/internal/core/api/api_service.dart';
import 'package:idev_viewer/src/internal/pms/model/behavior.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TableList extends StatefulWidget {
  const TableList({super.key});

  @override
  State<TableList> createState() => _TableListState();
}

class _TableListState extends State<TableList> {
  bool isLoaded = false;
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late ApiService apiService;
  String? selectedTableName;
  final Map<String, bool> _expandedTables = {};
  List<TableInfo> _tables = [];

  @override
  void initState() {
    isLoaded = true;
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    apiService = sl<ApiService>();
    _loadTableData();
    super.initState();
  }

  Future<void> _loadTableData() async {
    try {
      // 실제 API 호출로 스키마 정보 조회
      final response = await apiService.requestApi(
        uri: '/idev/v1/schema',
        method: Method.get,
        headers: {'X-Tenant-Id': 'skydbdbgmail'},
      );

      if (response.result == 0 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final tablesData = data['tables'] as List<dynamic>? ?? [];

        setState(() {
          _tables = tablesData.map((tableData) {
            final tableMap = tableData as Map<String, dynamic>;
            final columnsData = tableMap['columns'] as List<dynamic>? ?? [];

            return TableInfo(
              tableName: tableMap['tableName'] ?? '',
              columnCount: tableMap['columnCount'] ?? 0,
              columns: columnsData.map((columnData) {
                final columnMap = columnData as Map<String, dynamic>;
                return ColumnInfo(
                  columnName: columnMap['columnName'] ?? '',
                  dataType: columnMap['dataType'] ?? '',
                  isNullable: columnMap['isNullable'] ?? false,
                  isPrimaryKey: columnMap['isPrimaryKey'] ?? false,
                  isUnique: columnMap['isUnique'] ?? false,
                );
              }).toList(),
            );
          }).toList();
        });
      } else {
        // API 실패 시 하드코딩된 데이터 사용
        _loadHardcodedTableData();
      }
    } catch (e) {
      print('테이블 데이터 로드 실패: $e');
      // 에러 시 하드코딩된 데이터 사용
      _loadHardcodedTableData();
    }
  }

  void _loadHardcodedTableData() {
    // README.md의 실제 스키마 정보를 기반으로 테이블 데이터 생성
    setState(() {
      _tables = [
        TableInfo(
          tableName: 'API_BAS',
          columnCount: 10,
          columns: [
            ColumnInfo(
              columnName: 'api_id',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'api_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'api_url',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'method',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'description',
              dataType: 'text',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'created_at',
              dataType: 'timestamp',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'updated_at',
              dataType: 'timestamp',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'is_active',
              dataType: 'boolean',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'version',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'category',
              dataType: 'varchar',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
        TableInfo(
          tableName: 'EMP',
          columnCount: 10,
          columns: [
            ColumnInfo(
              columnName: 'emp_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'emp_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'dept_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'position',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'salary',
              dataType: 'decimal',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'hire_date',
              dataType: 'date',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'email',
              dataType: 'varchar',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'phone',
              dataType: 'varchar',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'address',
              dataType: 'text',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'status',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
        TableInfo(
          tableName: 'EMP_PAY',
          columnCount: 7,
          columns: [
            ColumnInfo(
              columnName: 'pay_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'emp_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'pay_date',
              dataType: 'date',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'basic_salary',
              dataType: 'decimal',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'bonus',
              dataType: 'decimal',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'deduction',
              dataType: 'decimal',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'net_pay',
              dataType: 'decimal',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
        TableInfo(
          tableName: 'EMP_SALES',
          columnCount: 7,
          columns: [
            ColumnInfo(
              columnName: 'sales_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'emp_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'sales_date',
              dataType: 'date',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'product_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'quantity',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'unit_price',
              dataType: 'decimal',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'total_amount',
              dataType: 'decimal',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
        TableInfo(
          tableName: 'MEMBER',
          columnCount: 12,
          columns: [
            ColumnInfo(
              columnName: 'member_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'username',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'email',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'password_hash',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'first_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'last_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'phone',
              dataType: 'varchar',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'address',
              dataType: 'text',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'birth_date',
              dataType: 'date',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'join_date',
              dataType: 'date',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'status',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'last_login',
              dataType: 'timestamp',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
        TableInfo(
          tableName: 'PARAM_BAS',
          columnCount: 9,
          columns: [
            ColumnInfo(
              columnName: 'param_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'param_code',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'param_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'param_value',
              dataType: 'text',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'param_type',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'description',
              dataType: 'text',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'is_active',
              dataType: 'boolean',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'created_at',
              dataType: 'timestamp',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'updated_at',
              dataType: 'timestamp',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
        TableInfo(
          tableName: 'USER_BAS',
          columnCount: 13,
          columns: [
            ColumnInfo(
              columnName: 'user_id',
              dataType: 'int',
              isNullable: false,
              isPrimaryKey: true,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'user_code',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'username',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'email',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
            ),
            ColumnInfo(
              columnName: 'password_hash',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'first_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'last_name',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'phone',
              dataType: 'varchar',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'address',
              dataType: 'text',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'role',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'status',
              dataType: 'varchar',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'created_at',
              dataType: 'timestamp',
              isNullable: false,
              isPrimaryKey: false,
              isUnique: false,
            ),
            ColumnInfo(
              columnName: 'last_login',
              dataType: 'timestamp',
              isNullable: true,
              isPrimaryKey: false,
              isUnique: false,
            ),
          ],
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Theme(
            data: ThemeData.dark(),
            child: Container(
              color: ThemeData.dark().dividerColor,
              height: 20,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('테이블'),
                    ],
                  ),
                  Positioned(
                      right: 0,
                      bottom: 0,
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () {
                                _uploadCsvFile();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Tooltip(
                                    message: 'CSV 파일 업로드',
                                    child: Icon(Icons.add, size: 16)),
                              )),
                          InkWell(
                              onTap: () {
                                _loadTableData();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Tooltip(
                                    message: 'Refresh',
                                    child: Icon(Icons.refresh, size: 16)),
                              )),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildTreeView(),
        ),
      ],
    );
  }

  Widget _buildTreeView() {
    if (_tables.isEmpty) {
      return Container(
        color: const Color(0xFF2D2D30),
        child: const Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart,
                      size: 48,
                      color: Color(0xFF6A6A6A),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '표시할 테이블이 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'CSV 파일을 업로드하거나 데이터베이스 스키마를 확인해주세요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6A6A6A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF2D2D30),
      child: Column(
        children: [
          // 테이블 목록
          Expanded(
            child: ListView.builder(
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];
                return _buildTableNode(table);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableNode(TableInfo table) {
    final isExpanded = _expandedTables[table.tableName] ?? false;
    final isSelected = selectedTableName == table.tableName;
    final hasColumns = table.columns.isNotEmpty;

    return Column(
      children: [
        Container(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTableName = table.tableName;
                });
              },
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF094771) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (hasColumns)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedTables[table.tableName] = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: const Color(0xFFCCCCCC),
                          size: 16,
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    Icon(
                      isExpanded ? Icons.table_chart : Icons.table_view,
                      color: Colors.blue.shade400,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        table.tableName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3E42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${table.columnCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      // 데이터 보기 버튼
                      GestureDetector(
                        onTap: () => _showTableData(table),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.visibility,
                            color: Colors.green.shade400,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // CSV 다운로드 버튼
                      GestureDetector(
                        onTap: () => _downloadTableAsCsv(table),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.download,
                            color: Colors.blue.shade400,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 테이블 삭제 버튼
                      GestureDetector(
                        onTap: () => _deleteTable(table),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.delete,
                            color: Colors.red.shade400,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          ...table.columns.map((column) => _buildColumnNode(column)),
        ],
      ],
    );
  }

  Widget _buildColumnNode(ColumnInfo column) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                _getColumnIcon(column),
                color: _getColumnColor(column),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  column.columnName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getTypeColor(column.dataType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  column.dataType,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (column.isPrimaryKey) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PK',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (column.isUnique && !column.isPrimaryKey) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'UQ',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (column.isNullable) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NULL',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getColumnIcon(ColumnInfo column) {
    if (column.isPrimaryKey) {
      return Icons.vpn_key;
    } else if (column.isUnique) {
      return Icons.fingerprint;
    } else if (column.dataType.contains('int') ||
        column.dataType.contains('decimal')) {
      return Icons.numbers;
    } else if (column.dataType.contains('varchar') ||
        column.dataType.contains('text')) {
      return Icons.text_fields;
    } else if (column.dataType.contains('date') ||
        column.dataType.contains('timestamp')) {
      return Icons.schedule;
    } else if (column.dataType.contains('boolean')) {
      return Icons.toggle_on;
    } else {
      return Icons.data_object;
    }
  }

  Color _getColumnColor(ColumnInfo column) {
    if (column.isPrimaryKey) {
      return Colors.orange.shade400;
    } else if (column.isUnique) {
      return Colors.green.shade400;
    } else {
      return Colors.blue.shade400;
    }
  }

  Color _getTypeColor(String dataType) {
    if (dataType.contains('int') || dataType.contains('decimal')) {
      return Colors.blue.shade700;
    } else if (dataType.contains('varchar') || dataType.contains('text')) {
      return Colors.green.shade700;
    } else if (dataType.contains('date') || dataType.contains('timestamp')) {
      return Colors.purple.shade700;
    } else if (dataType.contains('boolean')) {
      return Colors.orange.shade700;
    } else {
      return Colors.grey.shade700;
    }
  }

  // 테이블 데이터 보기
  void _showTableData(TableInfo table) {
    showDialog(
      context: context,
      builder: (context) => TableDataViewer(
        tableName: table.tableName,
        columns: table.columns,
      ),
    );
  }

  // CSV 다운로드
  Future<void> _downloadTableAsCsv(TableInfo table) async {
    await CsvDownloader.downloadTableAsCsv(
      tableName: table.tableName,
      context: context,
    );
  }

  // CSV 업로드
  Future<void> _uploadCsvFile() async {
    await CsvUploader.uploadCsvFile(
      context: context,
      onTableCreated: (String tableName) {
        // 테이블이 생성되면 목록 새로고침
        _loadTableData();
      },
    );
  }

  // 테이블 삭제
  Future<void> _deleteTable(TableInfo table) async {
    // 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D30),
        title: const Text(
          '테이블 삭제',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '테이블 "${table.tableName}"을(를) 삭제하시겠습니까?\n\n'
          '⚠️ 이 작업은 되돌릴 수 없습니다.\n'
          '테이블과 모든 데이터가 영구적으로 삭제됩니다.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 로딩 표시
      EasyLoading.show(status: '테이블 삭제 중...');

      // API 호출
      final response = await apiService.requestApi(
        uri: '/idev/v1/table/${table.tableName}',
        method: Method.delete,
        headers: {'X-Tenant-Id': 'skydbdbgmail'},
      );

      EasyLoading.dismiss();

      if (response.result == 0) {
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테이블 "${table.tableName}"이 성공적으로 삭제되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // 테이블 목록 새로고침
        _loadTableData();
      } else {
        // 오류 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테이블 삭제 실패: ${response.reason ?? '알 수 없는 오류'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('테이블 삭제 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class TableInfo {
  final String tableName;
  final int columnCount;
  final List<ColumnInfo> columns;

  TableInfo({
    required this.tableName,
    required this.columnCount,
    required this.columns,
  });
}

class ColumnInfo {
  final String columnName;
  final String dataType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isUnique;

  ColumnInfo({
    required this.columnName,
    required this.dataType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.isUnique,
  });
}
