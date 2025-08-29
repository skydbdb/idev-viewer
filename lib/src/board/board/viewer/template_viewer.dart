import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/board/viewer/template_viewer_page.dart';

const testTemplate = [
  {
    "boardId": "#TEMPLATE#",
    "id": "Frame_1f2837i",
    "type": "StackFrameItem",
    "angle": 0,
    "size": {"width": 800, "height": 500},
    "offset": {"dx": 0, "dy": 0},
    "padding": {"left": 0, "top": 0, "right": 0, "bottom": 0},
    "status": 6,
    "lockZOrder": false,
    "dock": false,
    "permission": "read",
    "theme": "White",
    "content": {
      "tabsVisible": true,
      "dividerThickness": 6,
      "tabsTitle":
          "[{\"tabIndex\":1,\"title\":\"Tab 1\",\"boardId\":\"Frame_1f2837i_1\"},{\"tabIndex\":2,\"title\":\"Tab 2\",\"boardId\":\"Frame_1f2837i_2\"}]",
      "lastStringify": "V1:3:1(R;0;;;2,3),2(I;1;1;0.5;F),3(I;1;2;0.5;F)"
    }
  },
  {
    "boardId": "Frame_1f2837i_1",
    "id": "Text_9qm8mz",
    "type": "StackTextItem",
    "angle": 0,
    "size": {"width": 120, "height": 50},
    "offset": {"dx": 0, "dy": 0},
    "padding": {"left": 0, "top": 0, "right": 0, "bottom": 0},
    "status": 6,
    "lockZOrder": false,
    "dock": false,
    "permission": "read",
    "theme": "White",
    "content": {"data": "Text"}
  },
  {
    "boardId": "Frame_1f2837i_1",
    "id": "Image_o9whqu",
    "type": "StackImageItem",
    "angle": 0,
    "size": {"width": 311, "height": 304},
    "offset": {"dx": 35, "dy": 95},
    "padding": {"left": 0, "top": 0, "right": 0, "bottom": 0},
    "status": 6,
    "lockZOrder": false,
    "dock": false,
    "permission": "read",
    "theme": "White",
    "content": {
      "url":
          "https://files.flutter-io.cn/images/branding/flutterlogo/flutter-cn-logo.png",
      "assetName": "",
      "color": "transparent",
      "colorBlendMode": "color",
      "fit": "scaleDown",
      "repeat": "repeat"
    }
  },
  {
    "boardId": "Frame_1f2837i_2",
    "id": "Search_86629z",
    "type": "StackSearchItem",
    "angle": 0,
    "size": {"width": 200, "height": 50},
    "offset": {"dx": 70, "dy": 55},
    "padding": {"left": 0, "top": 0, "right": 0, "bottom": 0},
    "status": 6,
    "lockZOrder": false,
    "dock": false,
    "permission": "all",
    "theme": "White",
    "content": {"buttonName": "조회", "reqApis": "[]"}
  }
];

class TemplateViewer extends StatefulWidget {
  const TemplateViewer({
    super.key,
    required this.boardId,
  });

  final String boardId;

  @override
  State<TemplateViewer> createState() => _TemplateViewerState();
}

class _TemplateViewerState extends State<TemplateViewer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const TemplateViewerPage(
      templateId: 0,
      templateNm: 'preview',
      script: null, // jsonEncode(testTemplate),
      commitInfo: 'preview',
    );
  }
}
