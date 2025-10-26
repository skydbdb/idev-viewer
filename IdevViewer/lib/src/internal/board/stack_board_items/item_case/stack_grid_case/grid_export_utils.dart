import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class GridExportUtils {
  final BuildContext context;
  final TrinaGridStateManager stateManager;
  final String initialTitle;
  final Function(bool, String) onExportStatusUpdate;

  // Export options state
  Map<String, bool> selectedColumns = {};
  bool includeHeaders = true;
  bool ignoreFixedRows = false;
  String csvSeparator = ',';

  // PDF specific options
  String headTitle = '';
  String pdfCreator = '';
  bool pdfLandscape = false;
  Color headerColor = Colors.blue;
  Color textColor = Colors.black;

  static const String formatCsv = 'csv';
  static const String formatJson = 'json';
  static const String formatPdf = 'pdf';

  GridExportUtils({
    required this.context,
    required this.stateManager,
    required this.initialTitle,
    required this.onExportStatusUpdate,
  }) {
    headTitle =
        initialTitle; // Initialize headTitle with the grid's headerTitle
    // Initialize selectedColumns map based on stateManager.columns
    for (var col in stateManager.columns) {
      selectedColumns[col.title] = true; // Default to exporting all columns
    }
  }

  /// Shows the dialog for configuring export options.
  void showExportOptionsDialog(String formatName) {
    // Create text controllers with initial values from the class members
    final titleController = TextEditingController(text: headTitle);
    final creatorController = TextEditingController(text: pdfCreator);

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use dialogContext to avoid context ambiguity
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Export as $formatName'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: const Text('Include headers'),
                        value: includeHeaders,
                        onChanged: (value) {
                          setDialogState(() {
                            includeHeaders = value ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Ignore frozen/fixed rows'),
                        value: ignoreFixedRows,
                        onChanged: (value) {
                          setDialogState(() {
                            ignoreFixedRows = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (formatName == formatCsv) ...[
                        const SizedBox(height: 8),
                        const Text('CSV Separator:'),
                        Row(
                          children: [
                            Radio<String>(
                              value: ',',
                              groupValue: csvSeparator,
                              onChanged: (value) {
                                setDialogState(() {
                                  csvSeparator = value!;
                                });
                              },
                            ),
                            const Text('Comma (,)'),
                            const SizedBox(width: 10),
                            Radio<String>(
                              value: ';',
                              groupValue: csvSeparator,
                              onChanged: (value) {
                                setDialogState(() {
                                  csvSeparator = value!;
                                });
                              },
                            ),
                            const Text('Semicolon (;)'),
                            const SizedBox(width: 10),
                            Radio<String>(
                              value: '	',
                              groupValue: csvSeparator,
                              onChanged: (value) {
                                setDialogState(() {
                                  csvSeparator = value!;
                                });
                              },
                            ),
                            const Text('Tab'),
                          ],
                        ),
                      ],

                      if (formatName == formatPdf) ...[
                        const SizedBox(height: 16),
                        const Text('PDF Options:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          controller: titleController,
                          onChanged: (value) {
                            // No need for setDialogState here, just update the class member
                            headTitle = value;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Creator',
                            border: OutlineInputBorder(),
                          ),
                          controller: creatorController,
                          onChanged: (value) {
                            // No need for setDialogState here, just update the class member
                            pdfCreator = value;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: pdfLandscape,
                              onChanged: (value) {
                                setDialogState(() {
                                  pdfLandscape = value ?? false;
                                });
                              },
                            ),
                            const Text('Landscape orientation'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Theme Options:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Header Color: '),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                final selectedColor = await _pickColor(
                                    context, 'Pick a header color');
                                if (selectedColor != null) {
                                  setDialogState(() {
                                    headerColor = selectedColor;
                                  });
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: headerColor,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Text Color: '),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () async {
                                final selectedColor = await _pickColor(
                                    context, 'Pick a text color');
                                if (selectedColor != null) {
                                  setDialogState(() {
                                    textColor = selectedColor;
                                  });
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: textColor,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Column selection
                      const Text('Select columns to export:'),
                      const SizedBox(height: 8),

                      // Select/Deselect all buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                for (var key in selectedColumns.keys) {
                                  selectedColumns[key] = true;
                                }
                              });
                            },
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                for (var key in selectedColumns.keys) {
                                  selectedColumns[key] = false;
                                }
                              });
                            },
                            child: const Text('Deselect All'),
                          ),
                        ],
                      ),

                      // Column checkboxes
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Use stateManager from the class, not context
                        child: ListView.builder(
                          itemCount: stateManager.columns.length,
                          itemBuilder: (context, index) {
                            final column = stateManager.columns[index];
                            // Use selectedColumns from the class
                            return CheckboxListTile(
                              title: Text(column.title),
                              value: selectedColumns[column.title] ?? false,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedColumns[column.title] =
                                      value ?? false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Use dialogContext
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update headTitle and pdfCreator from controllers before exporting
                    headTitle = titleController.text;
                    pdfCreator = creatorController.text;

                    // Get selected columns based on the map
                    final List<String> columnsToExport = selectedColumns.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();

                    // Close dialog using dialogContext
                    Navigator.of(dialogContext).pop();

                    _exportGrid(formatName, selectedColumns: columnsToExport)
                        .then((v) {
                      print('exportGrid done');
                    });
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper function to show color picker dialog.
  Future<Color?> _pickColor(BuildContext context, String title) async {
    return await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Material(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final colorGroup in [
                  Colors.primaries,
                  [Colors.black, Colors.white, Colors.grey] // Add common colors
                ])
                  Wrap(
                    children: [
                      for (final color in colorGroup)
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(color),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                      color: Colors
                                          .grey.shade400), // Lighter border
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    // Add subtle shadow
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(1, 1),
                                    )
                                  ]),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Performs the actual grid export based on the configured options.
  Future<void> _exportGrid(String formatName,
      {List<String>? selectedColumns}) async {
    onExportStatusUpdate(true, 'Exporting as $formatName...');

    String fileName = headTitle;
    String saveFilePath = '';
    try {
      // For CSV, generate and download the file
      if (formatName == formatCsv) {
        final content = await TrinaGridExportCsv().export(
          stateManager: stateManager,
          columns: selectedColumns,
          includeHeaders: includeHeaders,
          ignoreFixedRows: ignoreFixedRows,
          separator: csvSeparator,
        );

        const utf8Bom = [0xEF, 0xBB, 0xBF];
        final utf8Bytes = utf8.encode(content);
        final bytesWithBom = Uint8List.fromList(utf8Bom + utf8Bytes);

        saveFilePath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytesWithBom,
          ext: formatName,
          mimeType: MimeType.csv,
        );
      } else if (formatName == formatJson) {
        final content = await TrinaGridExportJson().export(
          stateManager: stateManager,
          columns: selectedColumns,
          ignoreFixedRows: ignoreFixedRows,
        );

        final utf8Bytes = utf8.encode(content);

        saveFilePath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: utf8Bytes,
          ext: formatName,
          mimeType: MimeType.json,
        );
      } else if (formatName == formatPdf) {
        final format =
            pdfLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

        PdfColor flutterToPdfColor(Color color) {
          // ignore: deprecated_member_use
          return PdfColor.fromInt(color.value);
        }

        pw.Font? baseFont;
        pw.Font? boldFont;
        try {
          // Ensure fonts are included in pubspec.yaml and the path is correct
          final fontData = await rootBundle
              .load("fonts/noto_sans_kr/NotoSansKR-VariableFont_Regular.ttf");
          baseFont = pw.Font.ttf(fontData);
          final boldFontData = await rootBundle
              .load("fonts/noto_sans_kr/NotoSansKR-VariableFont_Bold.ttf");
          boldFont = pw.Font.ttf(boldFontData);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Error loading font for PDF generation: $e")));
          }
          onExportStatusUpdate(false, 'Export failed: Font loading error');
          return; // Stop PDF generation
        }

        final themeData = pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ).copyWith(
          tableHeader: pw.TextStyle(
            color: flutterToPdfColor(
                Colors.white), // Use white for contrast on colored header
            fontWeight: pw.FontWeight.bold,
          ),
          defaultTextStyle: pw.TextStyle(
            color: flutterToPdfColor(textColor),
            fontSize: 10, // Adjust font size for potentially large tables
          ),
        );

        final content = await TrinaGridExportPdf().export(
            stateManager: stateManager,
            columns: selectedColumns,
            includeHeaders: includeHeaders,
            ignoreFixedRows: ignoreFixedRows,
            title: headTitle,
            creator: pdfCreator,
            pdfSettings: TrinaGridExportPdfSettings(
              theme: themeData,
              pageTheme: pw.PageTheme(
                pageFormat: format,
                theme: themeData,
                margin: const pw.EdgeInsets.all(20), // Add some margin
              ),
              cellStyle: pw.TextStyle(
                color: flutterToPdfColor(textColor),
                fontSize: 9, // Smaller font for cell content
              ),
              cellDecoration: (index, data, rowNum) {
                return pw.BoxDecoration(
                  color: index % 2 == 0
                      ? PdfColors.grey100
                      : PdfColors.white, // Alternate row colors
                  border: pw.Border.all(
                    color: PdfColors.grey400, // Lighter border
                    width: 0.5,
                  ),
                );
              },
              headerCellDecoration: pw.BoxDecoration(
                // Apply header color here
                color: flutterToPdfColor(headerColor),
                border: pw.Border.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
              ),
              headerStyle: pw.TextStyle(
                // Style for header text
                color:
                    flutterToPdfColor(Colors.white), // Ensure text is visible
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              // headerDecoration is deprecated, use headerCellDecoration
            ));

        saveFilePath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: content,
          ext: formatName,
          mimeType: MimeType.pdf,
        );
      } else {
        throw Exception('Unsupported format: $formatName');
      }

      onExportStatusUpdate(false, 'Successfully exported as $formatName');

      if (context.mounted && saveFilePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to $saveFilePath'),
          ),
        );
      }
    } catch (e) {
      final errorMessage = 'Export failed: $e';
      onExportStatusUpdate(false, errorMessage);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
