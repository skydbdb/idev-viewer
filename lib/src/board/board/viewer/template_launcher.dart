import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'template_viewer_page.dart';

/// Function to launch template in new window
Future<void> launchTemplate(
  int templateId, {
  String? templateNm,
  int? versionId,
  String? script,
  String? commitInfo,
  BuildContext? context,
}) async {
  debugPrint('🔘 [launchTemplate] 함수 호출됨');
  debugPrint('🔘 [launchTemplate] 매개변수 - templateId: $templateId');
  debugPrint('🔘 [launchTemplate] 매개변수 - templateNm: "$templateNm"');
  debugPrint('🔘 [launchTemplate] 매개변수 - versionId: $versionId');
  debugPrint(
      '🔘 [launchTemplate] 매개변수 - script: "${script?.substring(0, script.length > 100 ? 100 : script.length)}${script != null && script.length > 100 ? '...' : ''}"');
  debugPrint('🔘 [launchTemplate] 매개변수 - script 길이: ${script?.length ?? 0}');
  debugPrint('🔘 [launchTemplate] 매개변수 - commitInfo: "$commitInfo"');
  debugPrint(
      '🔘 [launchTemplate] 매개변수 - context: ${context != null ? '제공됨' : 'null'}');
  debugPrint('🔘 [launchTemplate] 매개변수 - kIsWeb: $kIsWeb');

  if (context != null) {
    debugPrint('🔘 [launchTemplate] 다이얼로그 모드로 실행');
    // 현재 창에서 다이얼로그로 표시
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        debugPrint('🔘 [launchTemplate] TemplateViewerPage 생성 시작');
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: TemplateViewerPage(
              templateId: templateId,
              templateNm: templateNm,
              script: script,
              commitInfo: commitInfo,
            ),
          ),
        );
      },
    );
    debugPrint('🔘 [launchTemplate] 다이얼로그 실행 완료');
  } else if (kIsWeb) {
    debugPrint('🔘 [launchTemplate] 웹 모드로 실행');
    // 웹 환경에서는 URL 파라미터로 데이터 전달
    final baseUrl = Uri.base.toString();
    debugPrint('🔘 [launchTemplate] baseUrl: $baseUrl');

    // URL 파라미터로 데이터 전달
    final queryParams = <String, String>{};

    if (templateNm != null && templateNm.isNotEmpty) {
      queryParams['templateNm'] = templateNm;
      debugPrint('🔘 [launchTemplate] templateNm 파라미터 추가: $templateNm');
    } else {
      debugPrint('⚠️ [launchTemplate] templateNm이 null이거나 비어있음');
    }

    if (versionId != null) {
      queryParams['versionId'] = versionId.toString();
      debugPrint('🔘 [launchTemplate] versionId 파라미터 추가: $versionId');
    } else {
      debugPrint('⚠️ [launchTemplate] versionId가 null');
    }

    if (script != null && script.isNotEmpty) {
      // 스크립트가 너무 길면 URL 파라미터로 전달하기 어려우므로
      // base64 인코딩을 사용합니다
      final encodedScript = base64Encode(utf8.encode(script));
      queryParams['script'] = encodedScript;
      debugPrint('🔘 [launchTemplate] script 파라미터 추가 (base64 인코딩됨)');
      debugPrint('🔘 [launchTemplate] 원본 script 길이: ${script.length}');
      debugPrint('🔘 [launchTemplate] 인코딩된 script 길이: ${encodedScript.length}');
    } else {
      debugPrint(
          '❌ [launchTemplate] script가 null이거나 비어있음 - 이것이 "No template data available" 오류의 원인일 수 있음');
    }

    if (commitInfo != null && commitInfo.isNotEmpty) {
      queryParams['commitInfo'] = commitInfo;
      debugPrint('🔘 [launchTemplate] commitInfo 파라미터 추가: $commitInfo');
    } else {
      debugPrint('⚠️ [launchTemplate] commitInfo가 null이거나 비어있음');
    }

    // URL 생성
    final uri = Uri.parse('$baseUrl#/template/$templateId');
    final finalUri = uri.replace(queryParameters: queryParams);

    debugPrint('🔘 [launchTemplate] 생성된 URI: $finalUri');
    debugPrint('🔘 [launchTemplate] 쿼리 파라미터 개수: ${queryParams.length}');

    try {
      debugPrint('🔘 [launchTemplate] URL 실행 가능 여부 확인 중...');
      final canLaunch = await url_launcher.canLaunchUrl(finalUri);
      debugPrint('🔘 [launchTemplate] canLaunchUrl 결과: $canLaunch');

      if (canLaunch) {
        debugPrint('🔘 [launchTemplate] URL 실행 시작');
        await url_launcher.launchUrl(
          finalUri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
        debugPrint('🔘 [launchTemplate] URL 실행 완료');
      } else {
        debugPrint('❌ [launchTemplate] URL을 실행할 수 없음');
      }
    } catch (e) {
      debugPrint('❌ [launchTemplate] url_launcher 오류: $e');
    }
  } else {
    debugPrint('❌ [launchTemplate] context도 없고 kIsWeb도 false - 실행할 수 없음');
  }

  debugPrint('🔘 [launchTemplate] 함수 종료');
}
