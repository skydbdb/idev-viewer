import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class CsvDownloader {
  static Future<void> downloadTableAsCsv({
    required String tableName,
    required BuildContext context,
    List<String>? selectedColumns,
    String? whereCondition,
    String? orderBy,
    int? limit,
  }) async {
    try {
      // 로딩 표시
      EasyLoading.show(status: 'CSV 다운로드 중...');

      // API 호출 - Dio를 직접 사용하여 CSV 다운로드
      final dio = Dio();
      final response = await dio.get(
        'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com/idev/v1/table/$tableName/export/csv',
        queryParameters: {
          'response_format': 'json',
          if (selectedColumns != null && selectedColumns.isNotEmpty)
            'columns': selectedColumns.join(','),
          if (whereCondition != null && whereCondition.isNotEmpty)
            'where': whereCondition,
          if (orderBy != null && orderBy.isNotEmpty) 'orderBy': orderBy,
          if (limit != null) 'limit': limit.toString(),
        },
        options: Options(
          headers: {
            'X-Tenant-Id': 'skydbdbgmail',
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjQsImVtYWlsIjoic2t5ZGJkYkBnbWFpbC5jb20iLCJnb29nbGVJZCI6IjEwNTAwNjQ2MjE5MDQxNjk0ODcxMiIsImlhdCI6MTc1NzU1ODA5NSwiZXhwIjoxNzU3NjQ0NDk1fQ.9_90pD4iNb2GAnSJnWoWh-33pVMNB0n22_lNWfgOUEg',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 304) {
        // CSV 데이터 추출 - 실제 API는 CSV 문자열을 직접 반환
        String csvContent = response.data?.toString() ?? '';

        if (csvContent.isEmpty) {
          throw Exception('다운로드할 데이터가 없습니다.');
        }

        // CSV 파일 생성 및 저장
        await _saveCsvFile(
          context: context,
          tableName: tableName,
          csvContent: csvContent,
        );

        EasyLoading.dismiss();

        // 성공 메시지
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$tableName.csv 파일이 다운로드되었습니다.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        EasyLoading.dismiss();
        throw Exception('CSV 다운로드에 실패했습니다. 상태코드: ${response.statusCode}');
      }
    } catch (e) {
      EasyLoading.dismiss();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다운로드 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static Future<void> _saveCsvFile({
    required BuildContext context,
    required String tableName,
    required String csvContent,
  }) async {
    try {
      // 파일명 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${tableName}_$timestamp.csv';

      // 플랫폼별 파일 저장
      if (kIsWeb) {
        // 웹에서는 FileSaver 사용
        try {
          await FileSaver.instance.saveAs(
            name: fileName,
            bytes: Uint8List.fromList(utf8.encode(csvContent)),
            ext: 'csv',
            mimeType: MimeType.text,
          );
        } catch (e) {
          // FileSaver 실패 시 대체 방법 사용
          await _downloadCsvAsBlob(fileName, csvContent);
        }
      } else {
        // 모바일/데스크톱에서는 path_provider 사용
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent, encoding: utf8);

        // 파일 저장 완료 메시지
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('파일이 저장되었습니다: ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('파일 저장 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> _downloadCsvAsBlob(
      String fileName, String csvContent) async {
    // 웹에서 Blob을 사용한 대체 다운로드 방법
    try {
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('파일 다운로드에 실패했습니다: $e');
    }
  }

  static Future<void> downloadTableSchemaAsCsv({
    required String tableName,
    required List<ColumnInfo> columns,
    required BuildContext context,
  }) async {
    try {
      EasyLoading.show(status: '스키마 다운로드 중...');

      // 스키마 정보를 CSV 형식으로 변환
      final csvContent = _convertSchemaToCsv(tableName, columns);

      // CSV 파일 생성 및 저장
      await _saveCsvFile(
        context: context,
        tableName: '${tableName}_schema',
        csvContent: csvContent,
      );

      EasyLoading.dismiss();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tableName}_schema.csv 파일이 다운로드되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스키마 다운로드 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static String _convertSchemaToCsv(
      String tableName, List<ColumnInfo> columns) {
    final csvData = <List<String>>[];

    // 헤더 행
    csvData.add([
      'Column Name',
      'Data Type',
      'Is Nullable',
      'Is Primary Key',
      'Is Unique',
      'Description'
    ]);

    // 데이터 행들
    for (final column in columns) {
      csvData.add([
        column.columnName,
        column.dataType,
        column.isNullable ? 'YES' : 'NO',
        column.isPrimaryKey ? 'YES' : 'NO',
        column.isUnique ? 'YES' : 'NO',
        '', // Description은 비어있음
      ]);
    }

    // CSV 문자열로 변환
    return csvData
        .map((row) =>
            row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','))
        .join('\n');
  }
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
