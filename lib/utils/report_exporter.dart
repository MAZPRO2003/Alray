import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExporter {
  static Future<void> exportToCsv({
    required BuildContext context,
    required String title,
    required List<List<dynamic>> rows,
  }) async {
    try {
      final String csv = _generateCsv(rows);
      final directory = await getTemporaryDirectory();
      // Replace spaces with underscores for safe filename
      final safeTitle = title.replaceAll(' ', '_');
      final path = '${directory.path}/$safeTitle.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Here is the $title.'),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  static String _generateCsv(List<List<dynamic>> rows) {
    return rows
        .map((row) {
          return row
              .map((cell) {
                String s = cell.toString();
                if (s.contains(',') || s.contains('"') || s.contains('\n')) {
                  return '"${s.replaceAll('"', '""')}"';
                }
                return s;
              })
              .join(',');
        })
        .join('\n');
  }

  static Future<void> exportToPdf({
    required BuildContext context,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> data,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: data
                      .map((row) => row.map((e) => e.toString()).toList())
                      .toList(),
                  border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),
                  cellHeight: 30,
                  cellAlignments: {
                    for (int i = 0; i < headers.length; i++)
                      i: i == 0
                          ? pw.Alignment.centerLeft
                          : pw.Alignment.centerRight,
                  },
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final safeTitle = title.replaceAll(' ', '_');
      final path = '${directory.path}/$safeTitle.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Here is the $title.'),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
