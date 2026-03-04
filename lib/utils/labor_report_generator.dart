import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/labor_payment.dart';
import 'package:alray_app/models/labor_task.dart';
import 'package:alray_app/utils/currency_utils.dart';

class LaborReportGenerator {
  static Future<void> generateExcelAndShare({
    required BuildContext context,
    required Project project,
    required List<LaborPayment> payments,
    required List<LaborTask> tasks,
  }) async {
    try {
      final excel = Excel.createExcel();

      // 1. Tasks Sheet
      const tasksSheetName = 'Tasks';
      excel.rename('Sheet1', tasksSheetName);
      final Sheet tasksSheet = excel[tasksSheetName];

      tasksSheet.appendRow([
        TextCellValue('Task Name'),
        TextCellValue('Laborers'),
        TextCellValue('Role'),
        TextCellValue('Progress'),
        TextCellValue('Start Date'),
        TextCellValue('End Date'),
        TextCellValue('Duration'),
      ]);

      for (final task in tasks) {
        tasksSheet.appendRow([
          TextCellValue(task.name),
          IntCellValue(task.laborerCount),
          TextCellValue(task.role),
          TextCellValue('${(task.completionPercentage * 100).toInt()}%'),
          TextCellValue(DateFormat('dd/MM/yyyy').format(task.startDate)),
          TextCellValue(
            task.endDate != null
                ? DateFormat('dd/MM/yyyy').format(task.endDate!)
                : '-',
          ),
          TextCellValue('${task.durationInDays} Days'),
        ]);
      }

      // 2. Payments Sheet
      const paymentsSheetName = 'Payments';
      final Sheet paymentsSheet = excel[paymentsSheetName];

      paymentsSheet.appendRow([
        TextCellValue('Laborer/Group'),
        TextCellValue('Period Start'),
        TextCellValue('Period End'),
        TextCellValue('Date Paid'),
        TextCellValue('Amount (₹)'),
        TextCellValue('Description'),
      ]);

      for (final p in payments) {
        paymentsSheet.appendRow([
          TextCellValue(p.laborerName),
          TextCellValue(DateFormat('dd/MM/yyyy').format(p.periodStart)),
          TextCellValue(DateFormat('dd/MM/yyyy').format(p.periodEnd)),
          TextCellValue(DateFormat('dd/MM/yyyy').format(p.date)),
          DoubleCellValue(p.amount),
          TextCellValue(p.description),
        ]);
      }

      final total = payments.fold(0.0, (sum, p) => sum + p.amount);
      paymentsSheet.appendRow([]);
      paymentsSheet.appendRow([
        null,
        null,
        null,
        TextCellValue('Total Paid (₹)'),
        DoubleCellValue(total),
      ]);

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/Labor_Report_${project.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);

      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Labor Report (Excel) for ${project.name}',
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate Excel report: $e')),
      );
    }
  }

  static Future<void> generateAndShare({
    required BuildContext context,
    required Project project,
    required List<LaborPayment> payments,
    required List<LaborTask> tasks,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => _buildHeader(project),
          footer: (pw.Context context) => _buildFooter(context),
          build: (pw.Context context) => [
            _buildTasksSection(tasks),
            pw.SizedBox(height: 20),
            _buildPaymentsSection(payments),
          ],
        ),
      );

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/Labor_Report_${project.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Labor Report for ${project.name}',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  static pw.Widget _buildHeader(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AL RAY ASSOCIATES',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  'LABOR MANAGEMENT REPORT',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                ),
                pw.Text(
                  'Project: ${project.name}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blueGrey900),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildTasksSection(List<LaborTask> tasks) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TASK COMPLETION STATUS',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: [
            'Task Name',
            'Laborers',
            'Role',
            'Progress',
            'Started',
            'Ended',
            'Dur',
          ],
          data: tasks
              .map(
                (t) => [
                  t.name,
                  t.laborerCount.toString(),
                  t.role,
                  '${(t.completionPercentage * 100).toInt()}%',
                  DateFormat('dd/MM/yy').format(t.startDate),
                  t.endDate != null
                      ? DateFormat('dd/MM/yy').format(t.endDate!)
                      : '-',
                  '${t.durationInDays}d',
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey800,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentsSection(List<LaborPayment> payments) {
    final total = payments.fold(0.0, (sum, p) => sum + p.amount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'WEEKLY PAYMENT LOG',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Laborer/Group', 'Period', 'Date Paid', 'Amount'],
          data: payments
              .map(
                (p) => [
                  p.laborerName,
                  '${DateFormat('dd/MM').format(p.periodStart)} - ${DateFormat('dd/MM').format(p.periodEnd)}',
                  DateFormat('dd/MM/yyyy').format(p.date),
                  CurrencyUtils.formatInr(p.amount),
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Total Paid: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              CurrencyUtils.formatInr(total),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }
}
