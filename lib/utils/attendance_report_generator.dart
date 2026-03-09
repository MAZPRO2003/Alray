import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/attendance_record.dart';

/// Returns [Monday, Sunday] of the week containing [date].
(DateTime, DateTime) _weekRange(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  final start = DateTime(monday.year, monday.month, monday.day);
  final end = DateTime(sunday.year, sunday.month, sunday.day);
  return (start, end);
}

class AttendanceReportGenerator {
  static const _cols = [
    'Date',
    'mason',
    'Helper',
    'Plumber',
    'Electrician',
    'carpenter',
    'steel worker',
    'grill worker',
    'tile labour',
    'Painter',
    'Custom',
    'others',
    'Total Workers',
    'Total Cost (Rs)',
    'Notes',
  ];

  // ── Full register ─────────────────────────────────────────────────────────

  static Future<void> generateExcelAndShare({
    required BuildContext context,
    required Project project,
    required List<AttendanceRecord> records,
  }) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Attendance';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      final customName = _getUniqueCustomNameFromRecords(records);
      _writeHeaders(sheet, customName: customName);
      final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
      for (var i = 0; i < sorted.length; i++) {
        _writeRow(sheet, i + 1, sorted[i]);
      }
      _applyWidths(sheet);

      await _saveAndShare(
        excel,
        'Attendance_${project.name.replaceAll(' ', '_')}'
            '_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        'Attendance Register - ${project.name}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
    }
  }

  // ── Weekly report ─────────────────────────────────────────────────────────

  static Future<void> generateWeeklyExcelAndShare({
    required BuildContext context,
    required Project project,
    required List<AttendanceRecord> records,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    try {
      final weekRecords =
          records
              .where(
                (r) => !r.date.isBefore(weekStart) && !r.date.isAfter(weekEnd),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      final excel = Excel.createExcel();
      final label = DateFormat('dd MMM').format(weekStart);
      final sheetName = 'Week $label';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      // Project name header
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value = TextCellValue('Project: ${project.name}')
        ..cellStyle = CellStyle(bold: true, fontSize: 13);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        ..value = TextCellValue(
          'Week: ${DateFormat('dd MMM yyyy').format(weekStart)} - '
          '${DateFormat('dd MMM yyyy').format(weekEnd)}',
        )
        ..cellStyle = CellStyle(italic: true);

      final customName = _getUniqueCustomNameFromRecords(weekRecords);
      _writeHeaders(sheet, startRow: 3, customName: customName);
      for (var i = 0; i < weekRecords.length; i++) {
        _writeRow(sheet, 4 + i, weekRecords[i]);
      }

      // Totals row
      final totalRow = 4 + weekRecords.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
        ..value = TextCellValue('TOTALS')
        ..cellStyle = CellStyle(bold: true);

      final totalWorkers = weekRecords.fold(0, (s, r) => s + r.totalWorkers);
      final totalCost = weekRecords.fold(0.0, (s, r) => s + r.totalCost);

      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: totalRow),
        )
        ..value = IntCellValue(totalWorkers)
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: totalRow),
        )
        ..value = DoubleCellValue(totalCost)
        ..cellStyle = CellStyle(bold: true);

      _applyWidths(sheet);

      final weekLabel =
          '${DateFormat('ddMMM').format(weekStart)}_${DateFormat('ddMMM').format(weekEnd)}';
      await _saveAndShare(
        excel,
        'WeeklyAttendance_${project.name.replaceAll(' ', '_')}'
            '_$weekLabel.xlsx',
        'Weekly Attendance - ${project.name} '
            '(${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM').format(weekEnd)})',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export weekly report: $e')),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _writeHeaders(Sheet sheet, {int startRow = 0, String? customName}) {
    final style = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    for (var i = 0; i < _cols.length; i++) {
      var headerText = _cols[i];
      if (headerText == 'Custom' && customName != null) {
        headerText = customName;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
        ..value = TextCellValue(headerText)
        ..cellStyle = style;
    }
  }

  static String? _getUniqueCustomNameFromRecords(List<AttendanceRecord> records) {
    if (records.isEmpty) return null;
    final names =
        records
            .where((r) => r.customEntered > 0 && r.customRoleName.isNotEmpty)
            .map((r) => r.customRoleName)
            .toSet();
    return names.length == 1 ? names.first : null;
  }

  static String _cell(int count, double rate) {
    if (count == 0) return '';
    if (rate == 0) return '$count';
    final rateStr = rate == rate.truncateToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2);
    return '$count- ${rateStr}rs';
  }

  static void _writeRow(Sheet sheet, int rowIdx, AttendanceRecord r) {
    final values = <CellValue>[
      TextCellValue(DateFormat('dd/MM/yyyy').format(r.date)),
      TextCellValue(_cell(r.mason, r.masonRate)),
      TextCellValue(_cell(r.helper, r.helperRate)),
      TextCellValue(_cell(r.plumber, r.plumberRate)),
      TextCellValue(_cell(r.electrician, r.electricianRate)),
      TextCellValue(_cell(r.carpenter, r.carpenterRate)),
      TextCellValue(_cell(r.steelWorker, r.steelWorkerRate)),
      TextCellValue(_cell(r.grillWorker, r.grillWorkerRate)),
      TextCellValue(_cell(r.tileLabour, r.tileLabourRate)),
      TextCellValue(_cell(r.painter, r.painterRate)),
      TextCellValue(
        r.customRoleName.isEmpty
            ? _cell(r.customEntered, r.customEnteredRate)
            : '${r.customRoleName}: ${_cell(r.customEntered, r.customEnteredRate)}',
      ),
      TextCellValue(_cell(r.others, r.othersRate)),
      IntCellValue(r.totalWorkers),
      DoubleCellValue(r.totalCost),
      TextCellValue(r.notes),
    ];
    for (var c = 0; c < values.length; c++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx),
              )
              .value =
          values[c];
    }
  }

  static void _applyWidths(Sheet sheet) {
    sheet.setColumnWidth(0, 14);
    for (var i = 1; i <= 11; i++) {
      sheet.setColumnWidth(i, 14);
    }
    sheet.setColumnWidth(12, 14);
    sheet.setColumnWidth(13, 16);
    sheet.setColumnWidth(14, 22);
  }

  static Future<void> _saveAndShare(
    Excel excel,
    String filename,
    String text,
  ) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$filename';
    final bytes = excel.save();
    if (bytes != null) {
      await File(path).writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: text),
      );
    }
  }

  // ── Public helper ─────────────────────────────────────────────────────────

  /// Group records into weeks (Mon–Sun). Returns sorted list of week starts.
  static Map<DateTime, List<AttendanceRecord>> groupByWeek(
    List<AttendanceRecord> records,
  ) {
    final Map<DateTime, List<AttendanceRecord>> map = {};
    for (final r in records) {
      final (start, _) = _weekRange(r.date);
      map.putIfAbsent(start, () => []).add(r);
    }
    return map;
  }

  static (DateTime, DateTime) weekRangeFor(DateTime date) => _weekRange(date);

  // ── PDF: Full register ────────────────────────────────────────────────────

  static Future<void> generatePdfAndShare({
    required BuildContext context,
    required Project project,
    required List<AttendanceRecord> records,
  }) async {
    try {
      final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
      final totalWorkers = sorted.fold(0, (s, r) => s + r.totalWorkers);
      final totalCost = sorted.fold(0.0, (s, r) => s + r.totalCost);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            _pdfTitle(
              'Attendance Register - ${project.name}',
              'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            ),
            pw.SizedBox(height: 12),
            _buildPdfTable(sorted),
            pw.SizedBox(height: 8),
            _pdfTotalsRow(sorted.length, totalWorkers, totalCost),
          ],
        ),
      );

      final fname =
          'Attendance_${project.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _savePdfAndShare(
        doc,
        fname,
        'Attendance Register - ${project.name}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  // ── PDF: Weekly ───────────────────────────────────────────────────────────

  static Future<void> generateWeeklyPdfAndShare({
    required BuildContext context,
    required Project project,
    required List<AttendanceRecord> records,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    try {
      final weekRecords =
          records
              .where(
                (r) => !r.date.isBefore(weekStart) && !r.date.isAfter(weekEnd),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      final totalWorkers = weekRecords.fold(0, (s, r) => s + r.totalWorkers);
      final totalCost = weekRecords.fold(0.0, (s, r) => s + r.totalCost);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            _pdfTitle(
              'Weekly Attendance - ${project.name}',
              'Week: ${DateFormat('dd MMM yyyy').format(weekStart)} - '
                  '${DateFormat('dd MMM yyyy').format(weekEnd)}',
            ),
            pw.SizedBox(height: 12),
            _buildPdfTable(weekRecords),
            pw.SizedBox(height: 8),
            _pdfTotalsRow(weekRecords.length, totalWorkers, totalCost),
          ],
        ),
      );

      final weekLabel =
          '${DateFormat('ddMMM').format(weekStart)}_${DateFormat('ddMMM').format(weekEnd)}';
      final fname =
          'WeeklyAttendance_${project.name.replaceAll(' ', '_')}_$weekLabel.pdf';
      await _savePdfAndShare(
        doc,
        fname,
        'Weekly Attendance - ${project.name} '
        '(${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM').format(weekEnd)})',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Weekly PDF export failed: $e')));
    }
  }

  // ── PDF helpers ───────────────────────────────────────────────────────────

  static const List<String> _pdfHeaders = [
    'Date',
    'mason',
    'Helper',
    'Plumber',
    'Electrician',
    'carpenter',
    'steel\nworker',
    'grill\nworker',
    'tile\nlabour',
    'Painter',
    'Custom',
    'others',
    'Total\nWorkers',
    'Total\nCost (Rs)',
  ];

  static String _pdfCell(int count, double rate, [String? name]) {
    if (count == 0) return '-';
    final r = rate == rate.truncateToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(0);
    final val = '$count\n${r}rs';
    return (name == null || name.isEmpty) ? val : '$name\n$val';
  }

  static pw.Widget _pdfTitle(String title, String subtitle) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        subtitle,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    ],
  );

  static pw.Widget _buildPdfTable(List<AttendanceRecord> records) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final headerStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = const pw.TextStyle(fontSize: 8);

    final customName = _getUniqueCustomNameFromRecords(records);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(55), // Date
        1: const pw.FlexColumnWidth(),
        2: const pw.FlexColumnWidth(),
        3: const pw.FlexColumnWidth(),
        4: const pw.FlexColumnWidth(),
        5: const pw.FlexColumnWidth(),
        6: const pw.FlexColumnWidth(),
        7: const pw.FlexColumnWidth(),
        8: const pw.FlexColumnWidth(),
        9: const pw.FlexColumnWidth(),
        10: const pw.FlexColumnWidth(),
        11: const pw.FlexColumnWidth(),
        12: const pw.FixedColumnWidth(38),
        13: const pw.FixedColumnWidth(50),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1565C0),
          ),
          children: _pdfHeaders.map((h) {
            var header = h;
            if (header == 'Custom' && customName != null) {
              header = customName;
            }
            return _pdfW(header, headerStyle);
          }).toList(),
        ),
        // Data rows
        ...records.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final bg = i.isOdd ? const PdfColor.fromInt(0xFFF5F5F5) : null;
          return pw.TableRow(
            decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
            children: [
              _pdfW(DateFormat('dd/MM/yy').format(r.date), cellStyle),
              _pdfW(_pdfCell(r.mason, r.masonRate), cellStyle),
              _pdfW(_pdfCell(r.helper, r.helperRate), cellStyle),
              _pdfW(_pdfCell(r.plumber, r.plumberRate), cellStyle),
              _pdfW(_pdfCell(r.electrician, r.electricianRate), cellStyle),
              _pdfW(_pdfCell(r.carpenter, r.carpenterRate), cellStyle),
              _pdfW(_pdfCell(r.steelWorker, r.steelWorkerRate), cellStyle),
              _pdfW(_pdfCell(r.grillWorker, r.grillWorkerRate), cellStyle),
              _pdfW(_pdfCell(r.tileLabour, r.tileLabourRate), cellStyle),
              _pdfW(_pdfCell(r.painter, r.painterRate), cellStyle),
              _pdfW(
                _pdfCell(
                  r.customEntered,
                  r.customEnteredRate,
                  r.customRoleName,
                ),
                cellStyle,
              ),
              _pdfW(_pdfCell(r.others, r.othersRate), cellStyle),
              _pdfW('${r.totalWorkers}', cellStyle),
              _pdfW(
                r.totalCost > 0 ? 'Rs.${fmt.format(r.totalCost)}' : '-',
                cellStyle,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _pdfW(String text, pw.TextStyle style) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
  );

  static pw.Widget _pdfTotalsRow(int days, int totalWorkers, double totalCost) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text('$days day(s)  |  ', style: bold),
        pw.Text('$totalWorkers workers  |  ', style: bold),
        if (totalCost > 0)
          pw.Text('Total: Rs.${fmt.format(totalCost)}', style: bold),
      ],
    );
  }

  static Future<void> _savePdfAndShare(
    pw.Document doc,
    String filename,
    String text,
  ) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$filename';
    final bytes = await doc.save();
    await File(path).writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: text),
    );
  }
}
