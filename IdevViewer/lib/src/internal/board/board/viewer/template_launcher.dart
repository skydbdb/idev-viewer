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
  if (context != null) {
    // 현재 창에서 다이얼로그로 표시
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
  } else if (kIsWeb) {
    // 웹 환경에서는 URL 파라미터로 데이터 전달
    final baseUrl = Uri.base.toString();

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
    } else {
      debugPrint(
          '❌ [launchTemplate] script가 null이거나 비어있음 - 이것이 "No template data available" 오류의 원인일 수 있음');
    }

    if (commitInfo != null && commitInfo.isNotEmpty) {
      queryParams['commitInfo'] = commitInfo;
    } else {
      debugPrint('⚠️ [launchTemplate] commitInfo가 null이거나 비어있음');
    }

    // URL 생성
    final uri = Uri.parse('$baseUrl#/template/$templateId');
    final finalUri = uri.replace(queryParameters: queryParams);

    try {
      final canLaunch = await url_launcher.canLaunchUrl(finalUri);

      if (canLaunch) {
        await url_launcher.launchUrl(
          finalUri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } else {
        debugPrint('❌ [launchTemplate] URL을 실행할 수 없음');
      }
    } catch (e) {
      debugPrint('❌ [launchTemplate] url_launcher 오류: $e');
    }
  } else {
    debugPrint('❌ [launchTemplate] context도 없고 kIsWeb도 false - 실행할 수 없음');
  }
}
