import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:alray_app/models/construction_entry.dart';

class ReceiptGenerator {
  static Future<void> generateAndShare({
    required BuildContext context,
    required ConstructionEntry entry,
  }) async {
    try {
      final pdf = pw.Document();

      final dateStr = DateFormat('dd/MM/yyyy').format(entry.date);
      final pDateStr = entry.paymentDate != null
          ? DateFormat('dd/MM/yyyy').format(entry.paymentDate!)
          : dateStr;

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            21.0 * PdfPageFormat.cm,
            16.0 * PdfPageFormat.cm,
            marginAll: 1.0 * PdfPageFormat.cm,
          ),
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey900, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'AL RAY ASSOCIATES',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'ENGINEER & BUILDER',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '1/1245, 1ST FLOOR, AIR INDIA COLONY, KUMUDHAM NAGAR,',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'MUGALIVAKKAM, Chennai-600 125.',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Receipt No & Date
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'No: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: entry.receiptNumber ?? '-'),
                          ],
                        ),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Date : ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(
                              text: dateStr,
                              style: pw.TextStyle(
                                decoration: pw.TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // Content
                  _lineItem(
                    'RECEIVED with thanks from Mr.',
                    entry.receiverName ?? '-',
                  ),
                  pw.SizedBox(height: 10),
                  _lineItem('the sum of Rupees', entry.amountInWords ?? '-'),
                  pw.SizedBox(height: 10),

                  if (entry.bank != null && entry.bank!.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            'Bank: ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    style: pw.BorderStyle.dotted,
                                  ),
                                ),
                              ),
                              child: pw.Text(
                                entry.bank!,
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  pw.Row(
                    children: [
                      pw.Text(
                        'By Cash / Draft / Cheque No: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                style: pw.BorderStyle.dotted,
                              ),
                            ),
                          ),
                          child: pw.Text(
                            entry.referenceData ?? '-',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'Dated: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(style: pw.BorderStyle.dotted),
                          ),
                        ),
                        child: pw.Text(pDateStr),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  pw.Row(
                    children: [
                      pw.Text(
                        'Drawn On: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                style: pw.BorderStyle.dotted,
                              ),
                            ),
                          ),
                          child: pw.Text(
                            entry.bankName ?? '-',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'Branch: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                style: pw.BorderStyle.dotted,
                              ),
                            ),
                          ),
                          child: pw.Text(
                            entry.branchName ?? '-',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  _lineItem('Towards Construction works:', entry.description),
                  pw.SizedBox(height: 40),
                  // Footer (Amount and Signature)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black),
                        ),
                        child: pw.Text(
                          '₹${NumberFormat("#,##,###.00", "en_IN").format(entry.amount)}/-',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'For Al Ray Associates',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 40),
                          pw.Text(
                            'H. Abdul Kader',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/Receipt_${entry.receiptNumber ?? entry.id}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Receipt for ${entry.receiverName}',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate receipt: $e')));
    }
  }

  static pw.Widget _lineItem(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 2),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 1, style: pw.BorderStyle.dotted),
              ),
            ),
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
