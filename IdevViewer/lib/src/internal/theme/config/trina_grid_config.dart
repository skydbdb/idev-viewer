import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';

// double gridFontSize = 14, gridRowHeight = 35; // 25;

TrinaGridConfiguration trinaGridConfig = const TrinaGridConfiguration(
    localeText: TrinaGridLocaleText.korean(),
    style: TrinaGridStyleConfig(
      // activatedColor: const Color(0xFFDCF5FF),
      // columnHeight: gridRowHeight,
      // rowHeight: gridRowHeight,
      // columnFilterHeight: gridRowHeight,
      columnTextStyle: TextStyle(
        color: Colors.black,
        decoration: TextDecoration.none,
        // fontSize: gridFontSize,
        fontWeight: FontWeight.w600,
      ),
      cellTextStyle: TextStyle(
        color: Colors.black,
        // fontSize: gridFontSize,
      ),
    ));
