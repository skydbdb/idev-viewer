import 'dart:async';
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:idev_viewer/src/internal/core/auth/auth_service.dart';
import 'file_storage_service.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  List<FileNode> _files = [];
  final Map<String, bool> _expandedFolders = {};
  String? _selectedFileKey;
  bool _isLoading = false;
  String _currentPath = '';
  final FileStorageService _storageService = FileStorageService();

  @override
  void initState() {
    super.initState();
    _initializeCredentials();
    _loadFiles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeCredentials() {
    // AuthService에서 테넌트 ID와 사용자 정보 가져오기
    final tenantId = AuthService.tenantId;
    final userInfo = AuthService.userInfo;
    final userId = userInfo?['email'] ?? userInfo?['userId'] ?? 'unknown-user';

    print('FileExplorer: 테넌트 ID = $tenantId');
    print('FileExplorer: 사용자 ID = $userId');

    if (tenantId != null && tenantId.isNotEmpty) {
      _storageService.setCredentials(tenantId, userId);
    } else {
      // 테넌트 ID가 없으면 에러 표시
      print('FileExplorer: 테넌트 ID가 없습니다');
    }
  }

  Future<void> _loadFiles([String? path]) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _storageService.getFiles(prefix: path);
      if (response.success) {
        setState(() {
          _files = response.files;
          _currentPath = path ?? '';
        });
      } else {
        _showErrorSnackBar('파일 목록을 불러오는데 실패했습니다.');
      }
    } catch (e) {
      // API 에러 처리
      print('API 서버 연결 실패: $e');

      if (e is FileStorageException) {
        if (e.isAuthenticationError) {
          _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
        } else if (e.isQuotaExceededError) {
          _showErrorSnackBar('스토리지 용량이 초과되었습니다.');
        } else if (e.isMissingTenantIdError) {
          _showErrorSnackBar('테넌트 ID가 누락되었습니다.');
        } else {
          _showErrorSnackBar('파일 목록 조회 실패: ${e.message}');
        }
      } else {
        _showErrorSnackBar('파일 목록 조회 실패: $e');
      }

      // 에러 시 빈 목록으로 설정
      setState(() {
        _files = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(String fileKey) async {
    // 파일명 추출
    final fileName = _getFileNameFromKey(fileKey);

    final confirmed = await _showConfirmDialog(
      '파일 삭제',
      '정말로 이 파일을 삭제하시겠습니까?\n삭제된 파일은 복구할 수 없습니다.',
      targetName: fileName,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _storageService.deleteFile(fileKey);
      if (response.success) {
        _showSuccessSnackBar('파일이 성공적으로 삭제되었습니다.');

        // 파일 목록 새로고침
        await _loadFiles(_currentPath);
      } else {
        _showErrorSnackBar('파일 삭제에 실패했습니다: ${response.message}');
      }
    } catch (e) {
      // API 에러 처리
      print('파일 삭제 API 연결 실패: $e');
      if (e is FileStorageException) {
        if (e.isAuthenticationError) {
          _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
        } else {
          _showErrorSnackBar('파일 삭제 실패: ${e.message}');
        }
      } else {
        _showErrorSnackBar('파일 삭제 실패: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 파일 직접 다운로드 (Lambda 스트리밍)
  Future<void> _downloadFile(String fileKey, String fileName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _storageService.downloadFile(fileKey);

      // 웹 환경과 모바일 환경 구분
      if (kIsWeb) {
        // 웹 환경: 브라우저 다운로드 사용
        final bytes = response.data;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        _showSuccessSnackBar('파일이 다운로드되었습니다: $fileName');
      } else {
        // 모바일/데스크톱 환경: 로컬 파일 저장
        final bytes = response.data;
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        _showSuccessSnackBar('파일이 다운로드되었습니다: $fileName');
      }
    } catch (e) {
      // API 에러 처리
      print('파일 다운로드 실패: $e');
      if (e is FileStorageException) {
        if (e.isAuthenticationError) {
          _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
        } else if (e.isDownloadError) {
          _showErrorSnackBar('다운로드 중 오류가 발생했습니다.');
        } else if (e.isS3AccessDeniedError) {
          _showErrorSnackBar('S3 접근 권한이 없습니다.');
        } else if (e.isS3BucketNotFoundError) {
          _showErrorSnackBar('S3 버킷을 찾을 수 없습니다.');
        } else {
          _showErrorSnackBar('파일 다운로드 실패: ${e.message}');
        }
      } else {
        _showErrorSnackBar('파일 다운로드 실패: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 브라우저에서 파일 열기 (공개 파일용)
  Future<void> _copyUrl(String fileKey, String fileName) async {
    try {
      // 파일 목록에서 해당 파일의 정보 찾기
      final file = _findFileByKey(fileKey);
      if (file != null) {
        String urlToCopy;

        // 1순위: 파일 목록에서 제공된 URL 사용 (가장 안전)
        if (file.url != null && file.url!.isNotEmpty) {
          urlToCopy = file.url!;
          print('📋 파일 목록 URL 사용: $urlToCopy');
        } else if (file.isPublic == true) {
          // 2순위: 공개 파일인 경우 새로운 공개 엔드포인트 URL 생성
          urlToCopy = _storageService.getPublicFileUrl(fileKey);
          print('🌐 공개 파일 URL 생성: $urlToCopy');
        } else {
          // 3순위: 비공개 파일인 경우 다운로드 URL 생성 API 호출
          print('🔐 비공개 파일 다운로드 URL 생성 시도...');
          final response = await _storageService.getDownloadUrl(fileKey);
          if (response.success) {
            urlToCopy = response.data.url;
            print('✅ 다운로드 URL 생성 성공: $urlToCopy');
          } else {
            _showErrorSnackBar('URL 생성에 실패했습니다.');
            return;
          }
        }

        // URL 유효성 검증
        if (urlToCopy.isEmpty) {
          _showErrorSnackBar('유효하지 않은 URL입니다.');
          return;
        }

        // 브라우저에서 새 탭으로 열기
        await _openUrlInBrowser(urlToCopy);
        _showSuccessSnackBar('브라우저에서 파일을 열었습니다: $fileName');
      } else {
        _showErrorSnackBar('파일을 찾을 수 없습니다.');
      }
    } catch (e) {
      // API 에러 처리
      print('❌ 브라우저에서 파일 열기 실패: $e');
      if (e is FileStorageException) {
        if (e.isAuthenticationError) {
          _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
        } else if (e.code == 'INVALID_FILE_KEY') {
          _showErrorSnackBar('잘못된 파일 키 형식입니다.');
        } else {
          _showErrorSnackBar('브라우저에서 파일 열기 실패: ${e.message}');
        }
      } else {
        _showErrorSnackBar('브라우저에서 파일 열기 실패: $e');
      }
    }
  }

  /// 파일 키로 파일 노드 찾기
  FileNode? _findFileByKey(String fileKey) {
    for (final file in _files) {
      if (file.key == fileKey) {
        return file;
      }
      // 하위 파일들도 검색
      final found = _findFileInChildren(file, fileKey);
      if (found != null) return found;
    }
    return null;
  }

  /// 파일 키에서 파일명 추출 (화면에 표시된 이름 사용)
  String _getFileNameFromKey(String fileKey) {
    try {
      // 먼저 파일 노드에서 실제 표시되는 이름을 찾기
      final file = _findFileByKey(fileKey);
      if (file != null && file.name.isNotEmpty) {
        return file.name;
      }

      // 파일 노드를 찾을 수 없는 경우 키에서 추출
      final parts = fileKey.split('/');
      if (parts.length > 1) {
        final fileName = parts.last;
        return fileName.isNotEmpty ? fileName : '알 수 없는 파일';
      }
      return '알 수 없는 파일';
    } catch (e) {
      return '알 수 없는 파일';
    }
  }

  /// 폴더 키에서 폴더명 추출 (화면에 표시된 이름 사용)
  String _getFolderNameFromKey(String folderKey) {
    try {
      // 먼저 폴더 노드에서 실제 표시되는 이름을 찾기
      final folder = _findFileByKey(folderKey);
      if (folder != null && folder.name.isNotEmpty) {
        return folder.name;
      }

      // 폴더 노드를 찾을 수 없는 경우 키에서 추출
      final parts = folderKey.split('/');
      if (parts.length > 1) {
        // 마지막 슬래시 제거 후 폴더명 추출
        final cleanKey = folderKey.replaceAll(RegExp(r'/$'), '');
        final folderParts = cleanKey.split('/');
        final folderName = folderParts.last;
        return folderName.isNotEmpty ? folderName : '알 수 없는 폴더';
      }
      return '알 수 없는 폴더';
    } catch (e) {
      return '알 수 없는 폴더';
    }
  }

  /// 하위 파일들에서 파일 키로 검색
  FileNode? _findFileInChildren(FileNode parent, String fileKey) {
    for (final child in parent.children) {
      if (child.key == fileKey) {
        return child;
      }
      // 재귀적으로 하위 폴더 검색
      final found = _findFileInChildren(child, fileKey);
      if (found != null) return found;
    }
    return null;
  }

  /// 브라우저에서 URL 열기
  Future<void> _openUrlInBrowser(String url) async {
    if (kIsWeb) {
      // 웹 환경에서 새 탭으로 열기
      html.window.open(url, '_blank');
    } else {
      // 모바일/데스크톱 환경에서 URL 열기
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('URL을 열 수 없습니다: $url');
      }
    }
  }

  Future<void> _showAccessPermissionDialog(String fileKey) async {
    // 파일의 현재 공개 상태 가져오기
    final file = _findFileByKey(fileKey);
    bool isPublic = file?.isPublic ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('파일 공개/비공개 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('공개 파일'),
                subtitle: const Text('모든 사용자가 접근 가능'),
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                isPublic
                    ? '파일이 공개되어 모든 사용자가 접근할 수 있습니다.\n(보안 강화: Lambda 스트리밍을 통한 안전한 접근)'
                    : '파일이 비공개되어 소유자만 접근할 수 있습니다.\n(보안 강화: S3 직접 접근 차단)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final request = FileAccessRequest(isPublic: isPublic);

        final response = await _storageService.setFileAccess(fileKey, request);
        if (response.success) {
          _showSuccessSnackBar(
              isPublic ? '파일이 공개로 설정되었습니다.' : '파일이 비공개로 설정되었습니다.');
          // 파일 목록 새로고침하여 UI 동기화
          await _loadFiles();
        } else {
          _showErrorSnackBar('파일 공개/비공개 설정에 실패했습니다: ${response.message}');
        }
      } catch (e) {
        // API 에러 처리
        print('파일 공개/비공개 설정 API 연결 실패: $e');
        if (e is FileStorageException) {
          if (e.isAuthenticationError) {
            _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
          } else if (e.isInvalidPublicFlagError) {
            _showErrorSnackBar('잘못된 공개 설정입니다.');
          } else {
            _showErrorSnackBar('파일 공개/비공개 설정 실패: ${e.message}');
          }
        } else {
          _showErrorSnackBar('파일 공개/비공개 설정 실패: $e');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 폴더 생성 다이얼로그
  Future<void> _showCreateFolderDialog() async {
    final folderNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: folderNameController,
              decoration: const InputDecoration(
                labelText: '폴더 이름',
                hintText: '예: documents, images',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('생성'),
          ),
        ],
      ),
    );

    if (result == true) {
      final folderName = folderNameController.text.trim();
      if (folderName.isEmpty) {
        _showErrorSnackBar('폴더 이름을 입력해주세요.');
        return;
      }

      try {
        final response = await _storageService.createFolder(
          folderName,
        );

        if (response.success) {
          _showSuccessSnackBar('폴더가 생성되었습니다: $folderName');
          // 파일 목록 새로고침
          await _loadFiles();
        } else {
          _showErrorSnackBar('폴더 생성에 실패했습니다: ${response.message}');
        }
      } catch (e) {
        print('폴더 생성 실패: $e');
        if (e is FileStorageException) {
          if (e.isAuthenticationError) {
            _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
          } else if (e.isFolderExistsError) {
            _showErrorSnackBar('이미 존재하는 폴더입니다: $folderName');
          } else if (e.isFolderCreateError) {
            _showErrorSnackBar('폴더 생성에 실패했습니다. 요청 파라미터를 확인해주세요.');
          } else if (e.isQuotaExceededError) {
            _showErrorSnackBar('스토리지 할당량을 초과했습니다. 파일을 정리하거나 요금제를 업그레이드해주세요.');
          } else {
            _showErrorSnackBar('폴더 생성 실패: ${e.message}');
          }
        } else {
          _showErrorSnackBar('폴더 생성 실패: $e');
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content,
      {String? targetName}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (targetName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        targetName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
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
    return result ?? false;
  }

  /// 하위 폴더 생성 다이얼로그
  Future<void> _showCreateSubfolderDialog(String parentFolderKey) async {
    final folderNameController = TextEditingController();

    // 부모 폴더 경로 추출 (tenant-id 제거, 마지막 슬래시 제거)
    final pathParts = parentFolderKey.split('/').skip(1).toList();
    final parentPath = pathParts.join('/').replaceAll(RegExp(r'/$'), '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('하위 폴더 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '부모 폴더: $parentPath',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: folderNameController,
              decoration: const InputDecoration(
                labelText: '폴더 이름',
                hintText: '예: documents, images',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('생성'),
          ),
        ],
      ),
    );

    if (result == true) {
      final folderName = folderNameController.text.trim();
      if (folderName.isEmpty) {
        _showErrorSnackBar('폴더 이름을 입력해주세요.');
        return;
      }

      try {
        final subfolderPath =
            parentPath.isEmpty ? folderName : '$parentPath/$folderName';

        final response = await _storageService.createFolder(
          subfolderPath,
        );

        if (response.success) {
          _showSuccessSnackBar('하위 폴더가 생성되었습니다: $folderName');
          // 파일 목록 새로고침
          await _loadFiles();
        } else {
          _showErrorSnackBar('하위 폴더 생성에 실패했습니다: ${response.message}');
        }
      } catch (e) {
        print('하위 폴더 생성 실패: $e');
        if (e is FileStorageException) {
          if (e.isAuthenticationError) {
            _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
          } else if (e.isFolderExistsError) {
            _showErrorSnackBar('이미 존재하는 폴더입니다: $folderName');
          } else if (e.isFolderCreateError) {
            _showErrorSnackBar('하위 폴더 생성에 실패했습니다. 요청 파라미터를 확인해주세요.');
          } else if (e.isQuotaExceededError) {
            _showErrorSnackBar('스토리지 할당량을 초과했습니다. 파일을 정리하거나 요금제를 업그레이드해주세요.');
          } else {
            _showErrorSnackBar('하위 폴더 생성 실패: ${e.message}');
          }
        } else {
          _showErrorSnackBar('하위 폴더 생성 실패: $e');
        }
      }
    }
  }

  /// 특정 폴더로 파일 업로드
  Future<void> _uploadFileToFolder(String folderKey) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        setState(() {
          _isLoading = true;
        });

        try {
          // 폴더 경로 추출 (tenant-id 제거, 마지막 슬래시 제거)
          final pathParts = folderKey.split('/').skip(1).toList();
          final folderPath = pathParts.join('/').replaceAll(RegExp(r'/$'), '');

          final response = await _storageService.uploadFile(
            file,
            folderPath: folderPath,
            isPublic: false, // 기본적으로 비공개로 설정
          );

          if (response.success) {
            // 새로운 Base64 응답 구조에서 표시용 파일명 사용
            final displayName = response.data.displayFileName;
            final uploadMethod = response.data.uploadMethod ?? 'unknown';

            String successMessage = '파일이 성공적으로 업로드되었습니다: $displayName';

            // 업로드 방식에 따른 추가 정보 표시
            if (uploadMethod == 'base64-filename') {
              successMessage += '\n(Base64 인코딩으로 다국어 파일명이 완벽하게 처리되었습니다)';
            }

            _showSuccessSnackBar(successMessage);

            // 파일 목록 새로고침
            await _loadFiles();
          } else {
            _showErrorSnackBar('파일 업로드에 실패했습니다: ${response.message}');
          }
        } catch (e) {
          // API 에러 처리
          print('파일 업로드 API 연결 실패: $e');
          if (e is FileStorageException) {
            if (e.isAuthenticationError) {
              _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
            } else if (e.isQuotaExceededError) {
              _showErrorSnackBar('스토리지 용량이 초과되었습니다.');
            } else if (e.isFileTooLargeError) {
              _showErrorSnackBar('파일 크기가 100MB를 초과합니다.');
            } else if (e.isEmptyFileError) {
              _showErrorSnackBar('빈 파일은 업로드할 수 없습니다.');
            } else {
              _showErrorSnackBar('파일 업로드 실패: ${e.message}');
            }
          } else {
            _showErrorSnackBar('파일 업로드 실패: $e');
          }
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('파일 선택 실패: $e');
      _showErrorSnackBar('파일 선택에 실패했습니다: $e');
    }
  }

  /// 폴더 삭제
  Future<void> _deleteFolder(String folderKey) async {
    // 폴더명 추출
    final folderName = _getFolderNameFromKey(folderKey);

    final confirmed = await _showConfirmDialog(
      '폴더 삭제',
      '폴더와 폴더 내 모든 파일이 삭제됩니다. 계속하시겠습니까?',
      targetName: folderName,
    );

    if (confirmed) {
      try {
        // 폴더 경로 추출 (tenant-id 제거, 마지막 슬래시 제거)
        final pathParts = folderKey.split('/').skip(1).toList();
        final folderPath = pathParts.join('/').replaceAll(RegExp(r'/$'), '');

        final response = await _storageService.deleteFolder(folderPath);

        if (response.success) {
          _showSuccessSnackBar(
              '폴더가 삭제되었습니다: ${response.data.deletedFiles}개 파일 포함');
          // 파일 목록 새로고침
          await _loadFiles();
        } else {
          _showErrorSnackBar('폴더 삭제에 실패했습니다: ${response.message}');
        }
      } catch (e) {
        print('폴더 삭제 실패: $e');
        if (e is FileStorageException) {
          if (e.isAuthenticationError) {
            _showErrorSnackBar('인증이 필요합니다. 로그인을 확인해주세요.');
          } else if (e.isFolderNotFoundError) {
            _showErrorSnackBar('삭제할 폴더를 찾을 수 없습니다. 폴더 경로를 확인해주세요.');
          } else if (e.isAccessDeniedError) {
            _showErrorSnackBar('폴더 삭제 권한이 없습니다.');
          } else {
            _showErrorSnackBar('폴더 삭제 실패: ${e.message}');
          }
        } else {
          _showErrorSnackBar('폴더 삭제 실패: $e');
        }
      }
    }
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
                      Text('파일서버'),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _showCreateFolderDialog,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Tooltip(
                              message: '폴더 생성',
                              child: Icon(Icons.add, size: 16),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _initializeCredentials();
                            _loadFiles(_currentPath);
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Tooltip(
                              message: '새로고침',
                              child: Icon(Icons.refresh, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_files.isEmpty) {
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
                      Icons.folder_open,
                      size: 48,
                      color: Color(0xFF6A6A6A),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '표시할 파일이 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '파일을 업로드하거나 폴더를 생성해주세요.',
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
          Expanded(
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return _buildFileNodeWithChildren(file, 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileNode(FileNode file, int level) {
    final isExpanded = _expandedFolders[file.key] ?? false;
    final isSelected = _selectedFileKey == file.key;
    final hasChildren = file.children.isNotEmpty;

    return Column(
      children: [
        Container(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFileKey = file.key;
                });
              },
              child: Container(
                height: 24,
                padding: EdgeInsets.only(
                  left: 8 + (level * 16),
                  right: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF094771) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (file.type == 'folder') ...[
                      InkWell(
                        onTap: hasChildren
                            ? () {
                                setState(() {
                                  _expandedFolders[file.key] = !isExpanded;
                                });
                              }
                            : null,
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 16,
                          color: hasChildren
                              ? Colors.white
                              : const Color(0xFF6A6A6A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.folder,
                        size: 16,
                        color: Colors.blue.shade300,
                      ),
                    ] else ...[
                      const SizedBox(width: 20),
                      Icon(
                        _getFileIcon(file.mimeType ?? ''),
                        size: 16,
                        color: _getFileIconColor(file.mimeType ?? ''),
                      ),
                      // 공개/비공개 상태 아이콘
                      if (file.isPublic != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          file.isPublic! ? Icons.public : Icons.lock,
                          size: 12,
                          color: file.isPublic! ? Colors.green : Colors.orange,
                        ),
                      ],
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (file.type == 'file') ...[
                      Text(
                        _formatFileSize(file.size ?? 0),
                        style: const TextStyle(
                          color: Color(0xFF6A6A6A),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 폴더와 파일 모두에 액션 버튼 추가
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'download_direct':
                            _downloadFile(file.key, file.name);
                            break;
                          case 'copy_url':
                            _copyUrl(file.key, file.name);
                            break;
                          case 'delete':
                            if (file.type == 'folder') {
                              _deleteFolder(file.key);
                            } else {
                              _deleteFile(file.key);
                            }
                            break;
                          case 'permission':
                            _showAccessPermissionDialog(file.key);
                            break;
                          case 'create_subfolder':
                            _showCreateSubfolderDialog(file.key);
                            break;
                          case 'upload_file':
                            _uploadFileToFolder(file.key);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final menuItems = <PopupMenuEntry<String>>[];

                        if (file.type == 'folder') {
                          // 폴더 메뉴
                          menuItems.addAll([
                            const PopupMenuItem(
                              value: 'create_subfolder',
                              child: Row(
                                children: [
                                  Icon(Icons.create_new_folder, size: 16),
                                  SizedBox(width: 8),
                                  Text('하위 폴더 생성'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'upload_file',
                              child: Row(
                                children: [
                                  Icon(Icons.upload_file, size: 16),
                                  SizedBox(width: 8),
                                  Text('파일 업로드'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('폴더 삭제',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ]);
                        } else {
                          // 파일 메뉴
                          menuItems.addAll([
                            const PopupMenuItem(
                              value: 'download_direct',
                              child: Row(
                                children: [
                                  Icon(Icons.download, size: 16),
                                  SizedBox(width: 8),
                                  Text('다운로드'),
                                ],
                              ),
                            ),
                          ]);

                          // 공개 파일인 경우 브라우저에서 열기 옵션 추가
                          if (file.isPublic == true) {
                            menuItems.add(
                              const PopupMenuItem(
                                value: 'copy_url',
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_browser, size: 16),
                                    SizedBox(width: 8),
                                    Text('브라우저에서 열기'),
                                  ],
                                ),
                              ),
                            );
                          }

                          menuItems.addAll([
                            const PopupMenuItem(
                              value: 'permission',
                              child: Row(
                                children: [
                                  Icon(Icons.security, size: 16),
                                  SizedBox(width: 8),
                                  Text('접근 권한'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('삭제',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ]);
                        }

                        return menuItems;
                      },
                      child: const Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      // ],
    );
  }

  /// 파일 노드와 자식 노드들을 함께 렌더링하는 위젯
  Widget _buildFileNodeWithChildren(FileNode file, int level) {
    return Column(
      children: [
        _buildFileNode(file, level),
        if (file.type == 'folder' &&
            (_expandedFolders[file.key] ?? false) &&
            file.children.isNotEmpty)
          ...file.children
              .map((child) => _buildFileNodeWithChildren(child, level + 1)),
      ],
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    } else if (mimeType.contains('powerpoint') ||
        mimeType.contains('presentation')) {
      return Icons.slideshow;
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('archive')) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Colors.green;
    } else if (mimeType.startsWith('video/')) {
      return Colors.purple;
    } else if (mimeType.startsWith('audio/')) {
      return Colors.orange;
    } else if (mimeType.contains('pdf')) {
      return Colors.red;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Colors.blue;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Colors.green;
    } else if (mimeType.contains('powerpoint') ||
        mimeType.contains('presentation')) {
      return Colors.orange;
    } else {
      return const Color(0xFF6A6A6A);
    }
  }

  /// 파일 크기 포맷팅 (바이트 → KB/MB 변환)
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes == 0) return '0 B';

    // 바이트를 KB로 변환
    final sizeInKB = sizeInBytes / 1024;

    // 1000KB 이상이면 MB 단위로 변환
    if (sizeInKB >= 1000) {
      return '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
    }

    // 1000KB 미만이면 KB 단위로 표시
    return '${sizeInKB.toStringAsFixed(0)} KB';
  }
}
