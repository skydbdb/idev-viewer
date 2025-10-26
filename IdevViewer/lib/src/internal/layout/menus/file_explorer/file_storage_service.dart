import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:idev_viewer/src/internal/core/auth/auth_service.dart';
import 'package:idev_viewer/src/internal/core/config/env.dart';

class FileStorageService {
  final Dio _dio = Dio();

  FileStorageService() {
    // 요청/응답 상세 로그 추가
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('Dio: $obj'),
    ));
  }

  /// 환경 변수에서 API 호스트 가져오기
  String get _baseUrl =>
      '${AppConfig.instance.apiHostAws}/idev/v1/master/storage';

  String? _tenantId;

  void setCredentials(String tenantId, String userId) {
    _tenantId = tenantId;
    // userId는 더 이상 사용하지 않음 (문서 기준)
  }

  Map<String, String> get _headers {
    final headers = <String, String>{};

    // AuthService에서 테넌트 ID 가져오기
    final authTenantId = AuthService.tenantId;
    final finalTenantId = authTenantId ?? _tenantId;

    if (finalTenantId != null && finalTenantId.isNotEmpty) {
      headers['x-tenant-id'] = finalTenantId;
    }

    // 강화된 인증 방식 (문서 기준)
    final token = AuthService.token;
    if (token != null && token.isNotEmpty) {
      // JWT 토큰 필수
      headers['Authorization'] = 'Bearer $token';
      print('FileStorageService: JWT 토큰 사용');
    } else {
      // JWT 토큰이 없으면 에러
      print('FileStorageService: JWT 토큰이 없습니다');
    }

    // 추가 인증 옵션 (선택사항)
    // headers['X-Viewer-Api-Key'] = 'your-api-key';
    // headers['X-Viewer-Token'] = 'your-viewer-token';

    return headers;
  }

  /// 새로운 리소스 API용 헤더 (X-Tenant-Id 포함)
  Map<String, String> _getResourceHeaders() {
    final headers = <String, String>{};

    // 테넌트 ID 헤더 추가 (서버에서 요구함)
    final tenantId = AuthService.tenantId ?? _tenantId;
    if (tenantId != null && tenantId.isNotEmpty) {
      headers['X-Tenant-Id'] = tenantId;
    }

    // 강화된 인증 방식 (JWT 토큰 사용)
    final token = AuthService.token;
    if (token != null && token.isNotEmpty) {
      // 토큰 형식 검증
      if (!token.startsWith('Bearer ')) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        headers['Authorization'] = token;
      }

      // 토큰 만료 확인
      if (_isTokenExpired(token)) {
        print('ResourceService: JWT 토큰이 만료되었습니다');
      } else {
        print('ResourceService: JWT 토큰 사용 (유효함)');
      }
    } else {
      print('ResourceService: JWT 토큰이 없습니다');
    }

    return headers;
  }

  /// JWT 토큰 만료 확인
  bool _isTokenExpired(String token) {
    try {
      final cleanToken = token.replaceFirst('Bearer ', '');
      final parts = cleanToken.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      // Base64 URL 디코딩
      final normalizedPayload =
          payload.replaceAll('-', '+').replaceAll('_', '/');
      final paddedPayload = normalizedPayload.padRight(
        normalizedPayload.length + (4 - normalizedPayload.length % 4) % 4,
        '=',
      );

      final decodedPayload = utf8.decode(base64.decode(paddedPayload));
      final payloadJson = json.decode(decodedPayload);

      final exp = payloadJson['exp'] as int?;
      if (exp == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isExpired = now >= exp;

      if (isExpired) {
        print('토큰 만료시간: ${DateTime.fromMillisecondsSinceEpoch(exp * 1000)}');
        print('현재 시간: ${DateTime.now()}');
      }

      return isExpired;
    } catch (e) {
      print('토큰 파싱 오류: $e');
      return true;
    }
  }

  /// API 에러 처리
  Never _handleApiError(dynamic error, String operation) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final code = responseData['code'] as String?;
        final message = responseData['message'] as String?;
        final data = responseData['data'] as Map<String, dynamic>?;

        throw FileStorageException(
          message ?? '$operation: ${error.message}',
          code: code,
          data: data,
        );
      }
    }
    throw FileStorageException('$operation: $error');
  }

  /// 파일 업로드 (Base64 파일명 인코딩 방식)
  Future<FileUploadResponse> uploadFile(
    PlatformFile file, {
    String? folderPath,
    bool isPublic = false,
  }) async {
    try {
      // 파일 크기 검증 (100MB 제한)
      if (file.size > 100 * 1024 * 1024) {
        throw FileStorageException(
          '파일 크기가 100MB를 초과합니다.',
          code: 'FILE_TOO_LARGE',
        );
      }

      // 빈 파일 검증
      if (file.size == 0) {
        throw FileStorageException(
          '빈 파일은 업로드할 수 없습니다.',
          code: 'EMPTY_FILE',
        );
      }

      print('📤 Base64 파일명 업로드 시작: ${file.name}');
      print('📁 폴더 경로: ${folderPath ?? '루트'}');
      print('🔓 공개 설정: $isPublic');

      // 파일명을 Base64로 인코딩 (다국어 파일명 완벽 지원)
      final encodedFileName = base64Encode(utf8.encode(file.name));
      print('🔐 Base64 인코딩된 파일명: $encodedFileName');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name, // 실제 파일명 (S3 키용)
        ),
        'originalFileName': encodedFileName, // Base64 인코딩된 원본 파일명
        if (folderPath != null && folderPath.isNotEmpty)
          'folderPath': folderPath,
        'isPublic': isPublic.toString(),
      });

      final response = await _dio.post(
        '$_baseUrl/upload-base64', // 새로운 Base64 업로드 API 사용
        data: formData,
        options: Options(
          headers: _headers,
          contentType: 'multipart/form-data',
        ),
      );

      print('✅ Base64 업로드 성공: ${file.name}');
      print('📋 응답 데이터: ${response.data}');

      return FileUploadResponse.fromJson(response.data);
    } catch (e) {
      print('❌ Base64 업로드 실패: ${file.name} - $e');
      _handleApiError(e, '파일 업로드 실패');
    }
  }

  /// 파일 목록 조회 (트리 구조)
  Future<FileListResponse> getFiles({String? prefix, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (prefix != null) queryParams['prefix'] = prefix;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        '$_baseUrl/files',
        queryParameters: queryParams,
        options: Options(headers: _headers),
      );

      return FileListResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '파일 목록 조회 실패');
    }
  }

  /// 파일 검색
  Future<FileSearchResponse> searchFiles(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {'query': query},
        options: Options(headers: _headers),
      );

      return FileSearchResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '파일 검색 실패');
    }
  }

  /// 파일 다운로드 URL 생성
  /// 파일 직접 다운로드 (Lambda 스트리밍)
  Future<Response> downloadFile(String fileKey) async {
    try {
      // 파일 키를 URL 안전하게 인코딩 (와일드카드 라우트 지원)
      final encodedFileKey = Uri.encodeComponent(fileKey);

      final response = await _dio.get(
        '$_baseUrl/files/$encodedFileKey/download',
        options: Options(
          headers: _headers,
          responseType: ResponseType.bytes,
        ),
      );

      return response;
    } catch (e) {
      _handleApiError(e, '파일 다운로드 실패');
    }
  }

  /// 파일 다운로드 URL 생성 (Lambda 다운로드 URL)
  Future<FileUrlResponse> getDownloadUrl(String fileKey,
      {int? expiresIn}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (expiresIn != null) queryParams['expiresIn'] = expiresIn;

      // 파일 키를 URL 안전하게 인코딩 (와일드카드 라우트 지원)
      final encodedFileKey = Uri.encodeComponent(fileKey);

      final response = await _dio.get(
        '$_baseUrl/files/$encodedFileKey/url',
        queryParameters: queryParams,
        options: Options(headers: _headers),
      );

      return FileUrlResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '다운로드 URL 생성 실패');
    }
  }

  /// 공개 파일 다운로드 URL 생성 (인증 불필요)
  /// 공개 파일 URL 생성 (개선된 버전)
  String getPublicFileUrl(String fileKey) {
    try {
      // 파일 키에서 테넌트 ID와 파일 경로 추출
      // 예: "tenant-id/uploads/document.pdf" -> "tenant-id", "uploads/document.pdf"
      final parts = fileKey.split('/');
      if (parts.length < 2) {
        throw FileStorageException(
          '잘못된 파일 키 형식: $fileKey',
          code: 'INVALID_FILE_KEY',
        );
      }

      final tenantId = parts[0];
      final filePath = parts.sublist(1).join('/');

      // 공개 파일 다운로드 URL 생성 (/idev/v1 접두어 사용)
      final publicUrl =
          '${AppConfig.instance.apiHostAws}/idev/v1/master/storage/public/$tenantId/$filePath';

      print('🔗 공개 파일 URL 생성:');
      print('   파일 키: $fileKey');
      print('   테넌트 ID: $tenantId');
      print('   파일 경로: $filePath');
      print('   생성된 URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ 공개 파일 URL 생성 실패: $e');
      rethrow;
    }
  }

  /// 폴더 생성
  Future<FolderCreateResponse> createFolder(String folderPath) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/folders',
        data: {
          'folderPath': folderPath,
        },
        options: Options(headers: _headers),
      );

      return FolderCreateResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '폴더 생성 실패');
    }
  }

  /// 폴더 삭제
  Future<FolderDeleteResponse> deleteFolder(String folderPath) async {
    try {
      // 폴더 경로를 URL 안전하게 인코딩 (와일드카드 라우트 지원)
      final encodedFolderPath = Uri.encodeComponent(folderPath);

      final response = await _dio.delete(
        '$_baseUrl/folders/$encodedFolderPath',
        options: Options(headers: _headers),
      );

      return FolderDeleteResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '폴더 삭제 실패');
    }
  }

  /// 폴더 목록 조회
  Future<FolderListResponse> getFolders() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/folders',
        options: Options(headers: _headers),
      );

      return FolderListResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '폴더 목록 조회 실패');
    }
  }

  /// 파일 삭제 (와일드카드 라우트 지원)
  Future<FileDeleteResponse> deleteFile(String fileKey) async {
    try {
      // 파일 키를 URL 안전하게 인코딩 (와일드카드 라우트 지원)
      final encodedFileKey = Uri.encodeComponent(fileKey);

      final response = await _dio.delete(
        '$_baseUrl/files/$encodedFileKey',
        options: Options(headers: _headers),
      );

      return FileDeleteResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '파일 삭제 실패');
    }
  }

  /// 파일 접근 권한 설정 (와일드카드 라우트 지원)
  Future<FileAccessResponse> setFileAccess(
      String fileKey, FileAccessRequest request) async {
    try {
      // 파일 키를 URL 안전하게 인코딩 (와일드카드 라우트 지원)
      final encodedFileKey = Uri.encodeComponent(fileKey);

      final response = await _dio.post(
        '$_baseUrl/files/$encodedFileKey/access',
        data: request.toJson(),
        options: Options(headers: _headers),
      );

      return FileAccessResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '파일 접근 권한 설정 실패');
    }
  }

  /// 파일 공개 상태 조회
  Future<FileAccessStatusResponse> getFileAccessStatus(String fileKey) async {
    try {
      // 파일 키를 URL 안전하게 인코딩 (와일드카드 라우트 지원)
      final encodedFileKey = Uri.encodeComponent(fileKey);

      final response = await _dio.get(
        '$_baseUrl/files/$encodedFileKey/access',
        options: Options(headers: _headers),
      );

      return FileAccessStatusResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '파일 공개 상태 조회 실패');
    }
  }

  /// 통합 리소스 현황 조회 (새로운 API 우선, 레거시 fallback)
  Future<ResourceStatusResponse> getResourceStatus() async {
    try {
      final tenantId = AuthService.tenantId ?? _tenantId;
      if (tenantId == null || tenantId.isEmpty) {
        throw FileStorageException(
          '테넌트 ID가 필요합니다.',
          code: 'MISSING_TENANT_ID',
        );
      }

      // 1차: 새로운 통합 리소스 API 시도
      try {
        final apiUrl =
            '${AppConfig.instance.getApiHost('/idev/v1/resources')}/idev/v1/resources/status/$tenantId';
        final headers = _getResourceHeaders();

        print('새로운 통합 리소스 API 시도: $apiUrl');
        print('요청 헤더: $headers');

        final response = await _dio.get(
          apiUrl,
          options: Options(
            headers: headers,
            validateStatus: (status) => status! < 500, // 4xx 에러도 처리
          ),
        );

        print('새로운 API 응답 상태: ${response.statusCode}');
        print('새로운 API 응답 데이터: ${response.data}');

        if (response.statusCode == 200) {
          return ResourceStatusResponse.fromJson(response.data);
        } else {
          throw FileStorageException(
            '새로운 리소스 API 응답 오류: ${response.statusCode} - ${response.data}',
            code: 'API_RESPONSE_ERROR',
          );
        }
      } catch (newApiError) {
        print('새로운 통합 리소스 API 실패, 레거시 API로 fallback: $newApiError');

        // 2차: 레거시 호환성 API로 fallback
        final storageStats = await getStorageStats();

        // 통합 리소스 정보 생성
        final resourceData =
            _createResourceStatusFromStorageStats(storageStats.data, tenantId);

        return ResourceStatusResponse(
          success: true,
          message: '레거시 API를 활용한 통합 리소스 정보를 생성했습니다.',
          data: resourceData,
        );
      }
    } catch (e) {
      print('모든 리소스 API 실패, 기본값 제공: $e');

      // 모든 API가 실패한 경우 기본 통합 리소스 정보 제공
      final tenantId = AuthService.tenantId ?? _tenantId ?? 'unknown';
      final defaultResourceData = _createDefaultResourceStatus(tenantId);

      return ResourceStatusResponse(
        success: true,
        message: '모든 API가 실패하여 기본 리소스 정보를 제공합니다.',
        data: defaultResourceData,
      );
    }
  }

  /// 기본 통합 리소스 정보 생성
  ResourceStatusData _createDefaultResourceStatus(String tenantId) {
    return ResourceStatusData(
      tenantId: tenantId,
      license: 'Community',
      resources: ResourceInfo(
        dbStorage: DbStorageInfo(
          allocated: ResourceValue(value: 100, unit: 'KB', display: '100 KB'),
          used: ResourceValue(value: 1, unit: 'KB', display: '1 KB'),
          remaining: ResourceValue(value: 99, unit: 'KB', display: '99 KB'),
          usagePercentage: 1.0,
          status: 'normal',
        ),
        fileStorage: FileStorageInfo(
          allocated: ResourceValue(value: 1024, unit: 'MB', display: '1 GB'),
          used: ResourceValue(value: 0, unit: 'MB', display: '알 수 없음'),
          remaining: ResourceValue(value: 1024, unit: 'MB', display: '알 수 없음'),
          usagePercentage: 0.0,
          status: 'unknown',
          planBased: true,
        ),
        traffic: TrafficInfo(
          monthlyLimit:
              ResourceValue(value: 1024, unit: 'MB', display: '1 GB/월'),
          currentUsed: ResourceValue(value: 0, unit: 'KB', display: '알 수 없음'),
          usagePercentage: 0.0,
          status: 'unknown',
          planBased: true,
        ),
      ),
      planComparison: PlanComparison(
        current: 'Community',
        upgradeOptions: _getUpgradeOptions('Community'),
      ),
    );
  }

  /// 기존 스토리지 통계를 통합 리소스 정보로 변환
  ResourceStatusData _createResourceStatusFromStorageStats(
      StorageStatsData stats, String tenantId) {
    return ResourceStatusData(
      tenantId: tenantId,
      license: stats.planType,
      resources: ResourceInfo(
        dbStorage: DbStorageInfo(
          allocated: ResourceValue(
              value: stats.total, unit: 'KB', display: '${stats.total} KB'),
          used: ResourceValue(
              value: stats.used, unit: 'KB', display: '${stats.used} KB'),
          remaining: ResourceValue(
              value: stats.total - stats.used,
              unit: 'KB',
              display: '${stats.total - stats.used} KB'),
          usagePercentage: stats.percentage,
          status: stats.isQuotaExceeded
              ? 'critical'
              : (stats.percentage > 80 ? 'warning' : 'normal'),
        ),
        fileStorage: FileStorageInfo(
          allocated: ResourceValue(value: 1024, unit: 'MB', display: '1 GB'),
          used: ResourceValue(value: 0, unit: 'MB', display: '알 수 없음'),
          remaining: ResourceValue(value: 1024, unit: 'MB', display: '알 수 없음'),
          usagePercentage: 0.0,
          status: 'unknown',
          planBased: true,
        ),
        traffic: TrafficInfo(
          monthlyLimit:
              ResourceValue(value: 1024, unit: 'MB', display: '1 GB/월'),
          currentUsed: ResourceValue(value: 0, unit: 'KB', display: '알 수 없음'),
          usagePercentage: 0.0,
          status: 'unknown',
          planBased: true,
        ),
      ),
      planComparison: PlanComparison(
        current: stats.planType,
        upgradeOptions: _getUpgradeOptions(stats.planType),
      ),
    );
  }

  /// 플랜별 업그레이드 옵션 생성 (기본값)
  List<UpgradeOption> _getUpgradeOptions(String currentPlan) {
    switch (currentPlan.toLowerCase()) {
      case 'community':
        return [
          UpgradeOption(
            plan: 'Starter',
            benefits: [
              'DB 스토리지: 100KB → 1MB',
              '파일 스토리지: 1GB → 10GB',
              '트래픽: 1GB/월 → 10GB/월',
              'API 호출: 1,000/일 → 10,000/일',
              '우선 지원',
            ],
          ),
          UpgradeOption(
            plan: 'Professional',
            benefits: [
              '무제한 DB 스토리지',
              '무제한 파일 스토리지',
              '무제한 트래픽',
              '무제한 API 호출',
              '24/7 지원',
              '모든 고급 기능',
            ],
          ),
        ];
      case 'starter':
        return [
          UpgradeOption(
            plan: 'Professional',
            benefits: [
              '무제한 DB 스토리지',
              '무제한 파일 스토리지',
              '무제한 트래픽',
              '무제한 API 호출',
              '24/7 지원',
              '모든 고급 기능',
            ],
          ),
        ];
      default:
        return [];
    }
  }

  /// 리소스 상태 체크 (새로운 API 우선, 레거시 fallback)
  Future<ResourceCheckResponse> getResourceCheck() async {
    try {
      final tenantId = AuthService.tenantId ?? _tenantId;
      if (tenantId == null || tenantId.isEmpty) {
        throw FileStorageException(
          '테넌트 ID가 필요합니다.',
          code: 'MISSING_TENANT_ID',
        );
      }

      // 1차: 새로운 리소스 체크 API 시도
      try {
        final apiUrl =
            '${AppConfig.instance.getApiHost('/idev/v1/resources')}/idev/v1/resources/check/$tenantId';
        final headers = _getResourceHeaders();

        print('새로운 리소스 체크 API 시도: $apiUrl');
        print('요청 헤더: $headers');

        final response = await _dio.get(
          apiUrl,
          options: Options(
            headers: headers,
            validateStatus: (status) => status! < 500, // 4xx 에러도 처리
          ),
        );

        print('새로운 체크 API 응답 상태: ${response.statusCode}');
        print('새로운 체크 API 응답 데이터: ${response.data}');

        if (response.statusCode == 200) {
          return ResourceCheckResponse.fromJson(response.data);
        } else {
          throw FileStorageException(
            '새로운 리소스 체크 API 응답 오류: ${response.statusCode} - ${response.data}',
            code: 'API_RESPONSE_ERROR',
          );
        }
      } catch (newApiError) {
        print('새로운 리소스 체크 API 실패, 레거시 API로 fallback: $newApiError');

        // 2차: 레거시 호환성 API로 fallback
        final storageStats = await getStorageStats();

        // 상태 체크 정보 생성
        final checkData =
            _createResourceCheckFromStorageStats(storageStats.data);

        return ResourceCheckResponse(
          success: true,
          message: '레거시 API를 활용한 리소스 상태를 체크했습니다.',
          data: checkData,
        );
      }
    } catch (e) {
      print('모든 리소스 체크 API 실패, 기본값 제공: $e');

      // 모든 API가 실패한 경우 기본 체크 정보 제공
      final defaultCheckData = _createDefaultResourceCheck();

      return ResourceCheckResponse(
        success: true,
        message: '모든 API가 실패하여 기본 리소스 상태를 제공합니다.',
        data: defaultCheckData,
      );
    }
  }

  /// 기본 리소스 체크 정보 생성
  ResourceCheckData _createDefaultResourceCheck() {
    return ResourceCheckData(
      overallStatus: 'normal',
      warnings: <String>[],
      criticalIssues: <String>[],
      checkedAt: DateTime.now(),
    );
  }

  /// 기존 스토리지 통계를 리소스 체크 정보로 변환
  ResourceCheckData _createResourceCheckFromStorageStats(
      StorageStatsData stats) {
    final warnings = <String>[];
    final criticalIssues = <String>[];
    String overallStatus = 'normal';

    // 사용률에 따른 상태 체크
    if (stats.isQuotaExceeded) {
      criticalIssues.add('스토리지 용량이 초과되었습니다.');
      overallStatus = 'critical';
    } else if (stats.percentage > 95) {
      criticalIssues.add('스토리지 사용률이 95%를 초과했습니다.');
      overallStatus = 'critical';
    } else if (stats.percentage > 80) {
      warnings.add('스토리지 사용률이 80%를 초과했습니다.');
      overallStatus = 'warning';
    }

    return ResourceCheckData(
      overallStatus: overallStatus,
      warnings: warnings,
      criticalIssues: criticalIssues,
      checkedAt: DateTime.now(),
    );
  }

  /// 스토리지 통계 조회 (기본값 제공)
  Future<StorageStatsResponse> getStorageStats() async {
    try {
      print('레거시 호환성 API 시도: /resources/legacy/storage-check');

      final response = await _dio.get(
        '${AppConfig.instance.getApiHost('/idev/v1/resources')}/idev/v1/resources/legacy/storage-check',
        options: Options(headers: _headers),
      );

      print('레거시 API 응답 상태: ${response.statusCode}');
      print('레거시 API 응답 데이터: ${response.data}');

      return StorageStatsResponse.fromJson(response.data);
    } catch (e) {
      print('레거시 호환성 API 실패, 기본값 제공: $e');

      // 기본 스토리지 통계 정보 제공
      return StorageStatsResponse(
        success: true,
        data: StorageStatsData(
          used: 1, // 1KB 사용
          total: 100, // 100KB 할당
          percentage: 1.0, // 1% 사용률
          planType: 'Community',
          isQuotaExceeded: false,
        ),
      );
    }
  }

  /// 라이센스별 한도 정보 조회
  Future<Map<String, dynamic>> getResourceLimits(String license) async {
    try {
      print('라이센스별 한도 정보 API 시도: /resources/limits/$license');

      final response = await _dio.get(
        '${AppConfig.instance.getApiHost('/idev/v1/resources')}/idev/v1/resources/limits/$license',
        options: Options(headers: _headers),
      );

      print('라이센스 한도 API 응답 상태: ${response.statusCode}');
      print('라이센스 한도 API 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw FileStorageException(
          '라이센스 한도 API 응답 오류: ${response.statusCode} - ${response.data}',
          code: 'API_RESPONSE_ERROR',
        );
      }
    } catch (e) {
      print('라이센스 한도 API 실패: $e');
      // 기본값 반환
      return _getDefaultResourceLimits(license);
    }
  }

  /// 플랜 업그레이드 옵션 조회
  Future<List<UpgradeOption>> getUpgradeOptions(String license) async {
    try {
      print('플랜 업그레이드 옵션 API 시도: /resources/upgrade-options/$license');

      final response = await _dio.get(
        '${AppConfig.instance.getApiHost('/idev/v1/resources')}/idev/v1/resources/upgrade-options/$license',
        options: Options(headers: _headers),
      );

      print('업그레이드 옵션 API 응답 상태: ${response.statusCode}');
      print('업그레이드 옵션 API 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> options = response.data['upgradeOptions'] ?? [];
        return options.map((option) => UpgradeOption.fromJson(option)).toList();
      } else {
        throw FileStorageException(
          '업그레이드 옵션 API 응답 오류: ${response.statusCode} - ${response.data}',
          code: 'API_RESPONSE_ERROR',
        );
      }
    } catch (e) {
      print('업그레이드 옵션 API 실패: $e');
      // 기본값 반환
      return _getUpgradeOptions(license);
    }
  }

  /// 기본 라이센스별 한도 정보 생성
  Map<String, dynamic> _getDefaultResourceLimits(String license) {
    switch (license.toLowerCase()) {
      case 'community':
        return {
          'license': 'Community',
          'limits': {
            'dbStorage': {'value': 100, 'unit': 'KB'},
            'fileStorage': {'value': 1, 'unit': 'GB'},
            'traffic': {'value': 1, 'unit': 'GB'},
            'apiCalls': {'value': 1000, 'unit': 'calls/day'},
          },
        };
      case 'starter':
        return {
          'license': 'Starter',
          'limits': {
            'dbStorage': {'value': 1000, 'unit': 'KB'},
            'fileStorage': {'value': 10, 'unit': 'GB'},
            'traffic': {'value': 10, 'unit': 'GB'},
            'apiCalls': {'value': 10000, 'unit': 'calls/day'},
          },
        };
      case 'professional':
        return {
          'license': 'Professional',
          'limits': {
            'dbStorage': {'value': -1, 'unit': 'unlimited'},
            'fileStorage': {'value': -1, 'unit': 'unlimited'},
            'traffic': {'value': -1, 'unit': 'unlimited'},
            'apiCalls': {'value': -1, 'unit': 'unlimited'},
          },
        };
      default:
        return {
          'license': license,
          'limits': {
            'dbStorage': {'value': 100, 'unit': 'KB'},
            'fileStorage': {'value': 1, 'unit': 'GB'},
            'traffic': {'value': 1, 'unit': 'GB'},
            'apiCalls': {'value': 1000, 'unit': 'calls/day'},
          },
        };
    }
  }

  /// 테넌트 스토리지 초기화
  Future<StorageInitResponse> initializeStorage(
      String tenantId, String planType) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/initialize',
        data: {
          'tenantId': tenantId,
          'planType': planType,
        },
      );

      return StorageInitResponse.fromJson(response.data);
    } catch (e) {
      _handleApiError(e, '스토리지 초기화 실패');
    }
  }
}

// 응답 모델들
class FileUploadResponse {
  final bool success;
  final String message;
  final FileUploadData data;

  FileUploadResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      success: json['success'],
      message: json['message'],
      data: FileUploadData.fromJson(json['data']),
    );
  }
}

class FileUploadData {
  final String key;
  final String url;
  final int size;
  final String mimetype;
  final String originalname;
  final String? displayName; // 새로운 필드: 표시용 파일명
  final String? safeFileName; // 새로운 필드: 서버 생성 안전 파일명
  final String? uploadMethod; // 새로운 필드: 업로드 방식
  final bool? isPublic; // 새로운 필드: 공개 여부
  final String? publicUrl; // 새로운 필드: 공개 URL
  final Map<String, dynamic>? metadata; // 새로운 필드: 메타데이터

  FileUploadData({
    required this.key,
    required this.url,
    required this.size,
    required this.mimetype,
    required this.originalname,
    this.displayName,
    this.safeFileName,
    this.uploadMethod,
    this.isPublic,
    this.publicUrl,
    this.metadata,
  });

  factory FileUploadData.fromJson(Map<String, dynamic> json) {
    return FileUploadData(
      key: json['key'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] ?? 0,
      mimetype: json['mimetype'] ?? '',
      originalname: json['originalname'] ?? json['originalName'] ?? '',
      displayName: json['displayName'],
      safeFileName: json['safeFileName'],
      uploadMethod: json['uploadMethod'],
      isPublic: json['isPublic'],
      publicUrl: json['publicUrl'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// 표시용 파일명 반환 (한글 파일명 우선)
  String get displayFileName {
    return displayName ?? originalname;
  }

  /// 공개 파일 여부 확인
  bool get isPublicFile {
    return isPublic == true;
  }
}

class FileListResponse {
  final bool success;
  final List<FileNode> files;

  FileListResponse({
    required this.success,
    required this.files,
  });

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    return FileListResponse(
      success: json['success'],
      files: (json['files'] as List)
          .map((item) => FileNode.fromJson(item))
          .toList(),
    );
  }
}

class FileSearchResponse {
  final bool success;
  final List<FileNode> data;

  FileSearchResponse({
    required this.success,
    required this.data,
  });

  factory FileSearchResponse.fromJson(Map<String, dynamic> json) {
    return FileSearchResponse(
      success: json['success'],
      data: (json['data'] as List)
          .map((item) => FileNode.fromJson(item))
          .toList(),
    );
  }
}

class FileUrlResponse {
  final bool success;
  final FileUrlData data;

  FileUrlResponse({
    required this.success,
    required this.data,
  });

  factory FileUrlResponse.fromJson(Map<String, dynamic> json) {
    return FileUrlResponse(
      success: json['success'],
      data: FileUrlData.fromJson(json['data']),
    );
  }
}

class FileUrlData {
  final String url;
  final String method;
  final String note;
  final DateTime? expiresAt;

  FileUrlData({
    required this.url,
    required this.method,
    required this.note,
    this.expiresAt,
  });

  factory FileUrlData.fromJson(Map<String, dynamic> json) {
    return FileUrlData(
      url: json['url'],
      method: json['method'] ?? 'GET',
      note: json['note'] ?? '',
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}

class FileDeleteResponse {
  final bool success;
  final String message;

  FileDeleteResponse({
    required this.success,
    required this.message,
  });

  factory FileDeleteResponse.fromJson(Map<String, dynamic> json) {
    return FileDeleteResponse(
      success: json['success'],
      message: json['message'],
    );
  }
}

class FileAccessResponse {
  final bool success;
  final String message;
  final FileAccessData data;

  FileAccessResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FileAccessResponse.fromJson(Map<String, dynamic> json) {
    return FileAccessResponse(
      success: json['success'],
      message: json['message'],
      data: FileAccessData.fromJson(json['data']),
    );
  }
}

class FileAccessData {
  final bool isPublic;
  final String fileKey;

  FileAccessData({
    required this.isPublic,
    required this.fileKey,
  });

  factory FileAccessData.fromJson(Map<String, dynamic> json) {
    return FileAccessData(
      isPublic: json['isPublic'] ?? false,
      fileKey: json['fileKey'] ?? '',
    );
  }
}

class FileAccessRequest {
  final bool isPublic;

  FileAccessRequest({
    required this.isPublic,
  });

  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
    };
  }
}

class FileAccessStatusResponse {
  final bool success;
  final FileAccessStatusData data;

  FileAccessStatusResponse({
    required this.success,
    required this.data,
  });

  factory FileAccessStatusResponse.fromJson(Map<String, dynamic> json) {
    return FileAccessStatusResponse(
      success: json['success'],
      data: FileAccessStatusData.fromJson(json['data']),
    );
  }
}

class FileAccessStatusData {
  final bool isPublic;
  final String fileKey;
  final String status;
  final String message;

  FileAccessStatusData({
    required this.isPublic,
    required this.fileKey,
    required this.status,
    required this.message,
  });

  factory FileAccessStatusData.fromJson(Map<String, dynamic> json) {
    return FileAccessStatusData(
      isPublic: json['isPublic'],
      fileKey: json['fileKey'],
      status: json['status'],
      message: json['message'],
    );
  }
}

class StorageStatsResponse {
  final bool success;
  final StorageStatsData data;

  StorageStatsResponse({
    required this.success,
    required this.data,
  });

  factory StorageStatsResponse.fromJson(Map<String, dynamic> json) {
    return StorageStatsResponse(
      success: json['success'],
      data: StorageStatsData.fromJson(json['data']),
    );
  }
}

class StorageStatsData {
  final int used; // KB 단위
  final int total; // KB 단위
  final double percentage;
  final String planType;
  final bool isQuotaExceeded;

  StorageStatsData({
    required this.used,
    required this.total,
    required this.percentage,
    required this.planType,
    required this.isQuotaExceeded,
  });

  factory StorageStatsData.fromJson(Map<String, dynamic> json) {
    return StorageStatsData(
      used: _parseInt(json['used']),
      total: _parseInt(json['total']),
      percentage: _parseDouble(json['percentage']),
      planType: json['planType'] ?? 'COMMUNITY',
      isQuotaExceeded: json['isQuotaExceeded'] ?? false,
    );
  }

  // 안전한 int 파싱 (문자열도 처리)
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // 안전한 double 파싱 (문자열도 처리)
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class StorageInitResponse {
  final bool success;
  final String message;
  final StorageInitData data;

  StorageInitResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory StorageInitResponse.fromJson(Map<String, dynamic> json) {
    return StorageInitResponse(
      success: json['success'],
      message: json['message'],
      data: StorageInitData.fromJson(json['data']),
    );
  }
}

class StorageInitData {
  final int id;
  final String tenantId;
  final String planType;
  final int quotaBytes;
  final int usedBytes;
  final bool isQuotaExceeded;

  StorageInitData({
    required this.id,
    required this.tenantId,
    required this.planType,
    required this.quotaBytes,
    required this.usedBytes,
    required this.isQuotaExceeded,
  });

  factory StorageInitData.fromJson(Map<String, dynamic> json) {
    return StorageInitData(
      id: json['id'],
      tenantId: json['tenantId'],
      planType: json['planType'],
      quotaBytes: json['quotaBytes'],
      usedBytes: json['usedBytes'],
      isQuotaExceeded: json['isQuotaExceeded'],
    );
  }
}

// 파일 노드 모델 (기존 FileNode와 통합)
class FileNode {
  final String key;
  final String name;
  final String type; // 'file' or 'folder'
  final int? size;
  final String? mimeType;
  final DateTime? modifiedAt;
  final String? url;
  final bool? isPublic;
  final bool? hasAccess;
  final List<FileNode> children;

  FileNode({
    required this.key,
    required this.name,
    required this.type,
    this.size,
    this.mimeType,
    this.modifiedAt,
    this.url,
    this.isPublic,
    this.hasAccess,
    this.children = const [],
  });

  factory FileNode.fromJson(Map<String, dynamic> json) {
    return FileNode(
      key: json['key'],
      name: json['name'],
      type: json['type'],
      size: json['size'],
      mimeType: json['mimeType'],
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'])
          : null,
      url: json['url'],
      isPublic: json['isPublic'],
      hasAccess: json['hasAccess'],
      children: (json['children'] as List?)
              ?.map((item) => FileNode.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// 폴더 생성 응답
class FolderCreateResponse {
  final bool success;
  final String message;
  final FolderCreateData data;

  FolderCreateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FolderCreateResponse.fromJson(Map<String, dynamic> json) {
    return FolderCreateResponse(
      success: json['success'],
      message: json['message'],
      data: FolderCreateData.fromJson(json['data']),
    );
  }
}

class FolderCreateData {
  final String folderPath;
  final String folderKey;
  final String createdBy;
  final DateTime createdAt;

  FolderCreateData({
    required this.folderPath,
    required this.folderKey,
    required this.createdBy,
    required this.createdAt,
  });

  factory FolderCreateData.fromJson(Map<String, dynamic> json) {
    return FolderCreateData(
      folderPath: json['folderPath'],
      folderKey: json['folderKey'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// 폴더 삭제 응답
class FolderDeleteResponse {
  final bool success;
  final String message;
  final FolderDeleteData data;

  FolderDeleteResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FolderDeleteResponse.fromJson(Map<String, dynamic> json) {
    return FolderDeleteResponse(
      success: json['success'],
      message: json['message'],
      data: FolderDeleteData.fromJson(json['data']),
    );
  }
}

class FolderDeleteData {
  final String folderPath;
  final int deletedFiles;
  final String deletedBy;
  final DateTime deletedAt;

  FolderDeleteData({
    required this.folderPath,
    required this.deletedFiles,
    required this.deletedBy,
    required this.deletedAt,
  });

  factory FolderDeleteData.fromJson(Map<String, dynamic> json) {
    return FolderDeleteData(
      folderPath: json['folderPath'],
      deletedFiles: json['deletedFiles'],
      deletedBy: json['deletedBy'],
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}

// 폴더 목록 응답
class FolderListResponse {
  final bool success;
  final FolderListData data;

  FolderListResponse({
    required this.success,
    required this.data,
  });

  factory FolderListResponse.fromJson(Map<String, dynamic> json) {
    return FolderListResponse(
      success: json['success'],
      data: FolderListData.fromJson(json['data']),
    );
  }
}

class FolderListData {
  final List<FolderInfo> folders;
  final int totalCount;

  FolderListData({
    required this.folders,
    required this.totalCount,
  });

  factory FolderListData.fromJson(Map<String, dynamic> json) {
    return FolderListData(
      folders: (json['folders'] as List)
          .map((item) => FolderInfo.fromJson(item))
          .toList(),
      totalCount: json['totalCount'],
    );
  }
}

class FolderInfo {
  final String folderPath;
  final String folderKey;
  final String name;
  final String? parentPath;

  FolderInfo({
    required this.folderPath,
    required this.folderKey,
    required this.name,
    this.parentPath,
  });

  factory FolderInfo.fromJson(Map<String, dynamic> json) {
    return FolderInfo(
      folderPath: json['folderPath'],
      folderKey: json['folderKey'],
      name: json['name'],
      parentPath: json['parentPath'],
    );
  }
}

// 예외 클래스
class FileStorageException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? data;

  FileStorageException(this.message, {this.code, this.data});

  @override
  String toString() =>
      'FileStorageException: $message${code != null ? ' (코드: $code)' : ''}';

  /// 인증 관련 에러인지 확인
  bool get isAuthenticationError => code == 'AUTHENTICATION_REQUIRED';

  /// 용량 초과 에러인지 확인 (STORAGE_QUOTA_EXCEEDED 또는 QUOTA_EXCEEDED)
  bool get isQuotaExceededError =>
      code == 'STORAGE_QUOTA_EXCEEDED' || code == 'QUOTA_EXCEEDED';

  /// 테넌트 ID 누락 에러인지 확인
  bool get isMissingTenantIdError => code == 'MISSING_TENANT_ID';

  /// 파일 크기 초과 에러인지 확인
  bool get isFileTooLargeError => code == 'FILE_TOO_LARGE';

  /// 빈 파일 에러인지 확인
  bool get isEmptyFileError => code == 'EMPTY_FILE';

  /// S3 접근 권한 에러인지 확인
  bool get isS3AccessDeniedError => code == 'S3_ACCESS_DENIED';

  /// S3 버킷 없음 에러인지 확인
  bool get isS3BucketNotFoundError => code == 'S3_BUCKET_NOT_FOUND';

  /// Multipart 파싱 에러인지 확인
  bool get isMultipartParseError => code == 'MULTIPART_PARSE_ERROR';

  /// 다운로드 에러인지 확인
  bool get isDownloadError => code == 'DOWNLOAD_ERROR';

  /// 잘못된 공개 플래그 에러인지 확인
  bool get isInvalidPublicFlagError => code == 'INVALID_PUBLIC_FLAG';

  /// 폴더가 이미 존재하는 에러인지 확인
  bool get isFolderExistsError => code == 'FOLDER_EXISTS';

  /// 폴더를 찾을 수 없는 에러인지 확인
  bool get isFolderNotFoundError => code == 'FOLDER_NOT_FOUND';

  /// 폴더 생성 실패 에러인지 확인
  bool get isFolderCreateError => code == 'FOLDER_CREATE_ERROR';

  /// 접근 권한 에러인지 확인
  bool get isAccessDeniedError => code == 'ACCESS_DENIED';

  /// 잘못된 요청 에러인지 확인 (400)
  bool get isBadRequestError => code == 'BAD_REQUEST';

  /// 인증 실패 에러인지 확인 (401)
  bool get isUnauthorizedError => code == 'UNAUTHORIZED';

  /// API 엔드포인트 없음 에러인지 확인 (404)
  bool get isNotFoundError => code == 'NOT_FOUND';

  /// API 응답 오류인지 확인
  bool get isApiResponseError => code == 'API_RESPONSE_ERROR';

  /// API 호출 실패 에러인지 확인
  bool get isApiCallFailedError => code == 'API_CALL_FAILED';
}

// 새로운 통합 리소스 API 응답 모델들

/// 통합 리소스 현황 응답
class ResourceStatusResponse {
  final bool success;
  final String message;
  final ResourceStatusData data;

  ResourceStatusResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ResourceStatusResponse.fromJson(Map<String, dynamic> json) {
    return ResourceStatusResponse(
      success: json['success'],
      message: json['message'],
      data: ResourceStatusData.fromJson(json['data']),
    );
  }
}

/// 통합 리소스 현황 데이터
class ResourceStatusData {
  final String tenantId;
  final String license;
  final ResourceInfo resources;
  final PlanComparison planComparison;

  ResourceStatusData({
    required this.tenantId,
    required this.license,
    required this.resources,
    required this.planComparison,
  });

  factory ResourceStatusData.fromJson(Map<String, dynamic> json) {
    return ResourceStatusData(
      tenantId: json['tenant_id'],
      license: json['license'],
      resources: ResourceInfo.fromJson(json['resources']),
      planComparison: PlanComparison.fromJson(json['plan_comparison']),
    );
  }
}

/// 리소스 정보
class ResourceInfo {
  final DbStorageInfo dbStorage;
  final FileStorageInfo fileStorage;
  final TrafficInfo traffic;

  ResourceInfo({
    required this.dbStorage,
    required this.fileStorage,
    required this.traffic,
  });

  factory ResourceInfo.fromJson(Map<String, dynamic> json) {
    return ResourceInfo(
      dbStorage: DbStorageInfo.fromJson(json['db_storage']),
      fileStorage: FileStorageInfo.fromJson(json['file_storage']),
      traffic: TrafficInfo.fromJson(json['traffic']),
    );
  }
}

/// DB 스토리지 정보
class DbStorageInfo {
  final ResourceValue allocated;
  final ResourceValue used;
  final ResourceValue remaining;
  final double usagePercentage;
  final String status;

  DbStorageInfo({
    required this.allocated,
    required this.used,
    required this.remaining,
    required this.usagePercentage,
    required this.status,
  });

  factory DbStorageInfo.fromJson(Map<String, dynamic> json) {
    return DbStorageInfo(
      allocated: ResourceValue.fromJson(json['allocated']),
      used: ResourceValue.fromJson(json['used']),
      remaining: ResourceValue.fromJson(json['remaining']),
      usagePercentage: json['usage_percentage'].toDouble(),
      status: json['status'],
    );
  }
}

/// 파일 스토리지 정보
class FileStorageInfo {
  final ResourceValue allocated;
  final ResourceValue used;
  final ResourceValue remaining;
  final double usagePercentage;
  final String status;
  final bool planBased;

  FileStorageInfo({
    required this.allocated,
    required this.used,
    required this.remaining,
    required this.usagePercentage,
    required this.status,
    required this.planBased,
  });

  factory FileStorageInfo.fromJson(Map<String, dynamic> json) {
    return FileStorageInfo(
      allocated: ResourceValue.fromJson(json['allocated']),
      used: ResourceValue.fromJson(json['used']),
      remaining: ResourceValue.fromJson(json['remaining']),
      usagePercentage: json['usage_percentage'].toDouble(),
      status: json['status'],
      planBased: json['plan_based'] ?? false,
    );
  }
}

/// 트래픽 정보
class TrafficInfo {
  final ResourceValue monthlyLimit;
  final ResourceValue currentUsed;
  final double usagePercentage;
  final String status;
  final bool planBased;

  TrafficInfo({
    required this.monthlyLimit,
    required this.currentUsed,
    required this.usagePercentage,
    required this.status,
    required this.planBased,
  });

  factory TrafficInfo.fromJson(Map<String, dynamic> json) {
    return TrafficInfo(
      monthlyLimit: ResourceValue.fromJson(json['monthly_limit']),
      currentUsed: ResourceValue.fromJson(json['current_used']),
      usagePercentage: json['usage_percentage'].toDouble(),
      status: json['status'],
      planBased: json['plan_based'] ?? false,
    );
  }
}

/// 리소스 값 (값, 단위, 표시용 문자열)
class ResourceValue {
  final int value;
  final String unit;
  final String display;

  ResourceValue({
    required this.value,
    required this.unit,
    required this.display,
  });

  factory ResourceValue.fromJson(Map<String, dynamic> json) {
    return ResourceValue(
      value: json['value'],
      unit: json['unit'],
      display: json['display'],
    );
  }
}

/// 플랜 비교 정보
class PlanComparison {
  final String current;
  final List<UpgradeOption> upgradeOptions;

  PlanComparison({
    required this.current,
    required this.upgradeOptions,
  });

  factory PlanComparison.fromJson(Map<String, dynamic> json) {
    return PlanComparison(
      current: json['current'],
      upgradeOptions: (json['upgrade_options'] as List?)
              ?.map((item) => UpgradeOption.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 업그레이드 옵션
class UpgradeOption {
  final String plan;
  final List<String> benefits;

  UpgradeOption({
    required this.plan,
    required this.benefits,
  });

  factory UpgradeOption.fromJson(Map<String, dynamic> json) {
    return UpgradeOption(
      plan: json['plan'],
      benefits: (json['benefits'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// 리소스 상태 체크 응답
class ResourceCheckResponse {
  final bool success;
  final String message;
  final ResourceCheckData data;

  ResourceCheckResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ResourceCheckResponse.fromJson(Map<String, dynamic> json) {
    return ResourceCheckResponse(
      success: json['success'],
      message: json['message'],
      data: ResourceCheckData.fromJson(json['data']),
    );
  }
}

/// 리소스 상태 체크 데이터
class ResourceCheckData {
  final String overallStatus;
  final List<String> warnings;
  final List<String> criticalIssues;
  final DateTime checkedAt;

  ResourceCheckData({
    required this.overallStatus,
    required this.warnings,
    required this.criticalIssues,
    required this.checkedAt,
  });

  factory ResourceCheckData.fromJson(Map<String, dynamic> json) {
    return ResourceCheckData(
      overallStatus: json['overall_status'],
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      criticalIssues: (json['critical_issues'] as List?)?.cast<String>() ?? [],
      checkedAt: DateTime.parse(json['checked_at']),
    );
  }
}
