import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:idev_viewer/src/internal/pms/model/api_response.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dio/dio.dart';
import 'package:idev_viewer/src/internal/core/config/env.dart';

class CsvUploader {
  static Future<void> uploadCsvFile({
    required BuildContext context,
    required Function(String tableName) onTableCreated,
  }) async {
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

      // 웹과 모바일/데스크톱 환경 구분
      Uint8List? fileBytes = file.bytes;
      String fileName = file.name;

      // 웹 환경에서는 bytes만 사용, 모바일/데스크톱에서는 path 사용
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

      // 파일 크기 검증 (50MB 제한 - 가이드 문서 기준)
      int fileSize;
      if (fileBytes != null) {
        // 웹 환경
        fileSize = fileBytes.length;
      } else {
        // 모바일/데스크톱 환경
        fileSize = await File(filePath!).length();
      }

      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('파일 크기가 50MB를 초과합니다.');
      }

      // 테이블명 입력 다이얼로그
      final tableName = await _showTableNameDialog(context);
      if (tableName == null || tableName.isEmpty) {
        return; // 사용자가 취소
      }

      // 업로드 진행
      await _uploadFile(
          context, filePath, fileBytes, fileName, tableName, onTableCreated);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('업로드 중 오류가 발생했습니다: $e');

      if (context.mounted) {
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

  static Future<String?> _showTableNameDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D30),
        title: const Text(
          '테이블명 입력',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '생성할 테이블명을 입력하세요:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '예: MY_TABLE',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final tableName = controller.text.trim();
              if (tableName.isNotEmpty) {
                Navigator.of(context).pop(tableName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  static Future<void> _uploadFile(
    BuildContext context,
    String? filePath,
    Uint8List? fileBytes,
    String fileName,
    String tableName,
    Function(String tableName) onTableCreated,
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
        'tableName': tableName,
        'createTable': 'true',
      });

      // 디버깅을 위한 로그 추가
      print('=== CSV 업로드 디버깅 ===');
      print('테이블명: $tableName');
      print('파일명: $fileName');
      print('파일 크기: ${fileBytes?.length ?? 'N/A'} bytes');

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
        final createdTableName = data['tableName'] ?? tableName;
        final rowsImported = data['rowsImported'] ?? 0;
        final columnsCreated = data['columnsCreated'] ?? 0;

        EasyLoading.dismiss();

        if (context.mounted) {
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '테이블 "$createdTableName"이 성공적으로 생성되었습니다.\n'
                '가져온 행: $rowsImported개, 컬럼: $columnsCreated개',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // 콜백 호출
          onTableCreated(createdTableName);
        }
      } else {
        EasyLoading.dismiss();
        throw Exception(apiResponse.reason ?? 'CSV 업로드에 실패했습니다.');
      }
    } catch (e) {
      EasyLoading.dismiss();

      if (context.mounted) {
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

  static Future<void> showUploadProgressDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF2D2D30),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'CSV 파일을 업로드하고 있습니다...',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
