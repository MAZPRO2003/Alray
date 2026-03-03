import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:alray_app/utils/report_exporter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReportCategory { material, labour, specialized, all }

enum ReportStatus { paid, pending, both }

class ProjectReportGenerator {
  static Future<void> generate({
    required BuildContext context,
    required Project project,
    required ReportCategory category,
    required ReportStatus status,
    required bool isPdf,
  }) async {
    final title = _getReportTitle(project.name, category, status);
    final headers = [
      'Date',
      'Description',
      'Category',
      'Ref/Vendor',
      'Status', // New Column
      'Amount (Rs.)',
    ];
    final data = _getReportData(project, category, status);

    if (isPdf) {
      await ReportExporter.exportToPdf(
        context: context,
        title: title,
        headers: headers,
        data: data,
      );
    } else {
      await ReportExporter.exportToCsv(
        context: context,
        title: title,
        rows: [headers, ...data],
      );
    }
  }

  static String _getReportTitle(
    String projectName,
    ReportCategory category,
    ReportStatus status,
  ) {
    String catStr = '';
    switch (category) {
      case ReportCategory.material:
        catStr = 'Material';
        break;
      case ReportCategory.labour:
        catStr = 'Labour';
        break;
      case ReportCategory.specialized:
        catStr = 'Specialized';
        break;
      case ReportCategory.all:
        catStr = 'Overall';
        break;
    }

    String statStr = '';
    switch (status) {
      case ReportStatus.paid:
        statStr = 'Paid';
        break;
      case ReportStatus.pending:
        statStr = 'Pending';
        break;
      case ReportStatus.both:
        statStr = 'Full';
        break;
    }

    return '$projectName - $catStr $statStr Report';
  }

  static List<List<dynamic>> _getReportData(
    Project project,
    ReportCategory category,
    ReportStatus status,
  ) {
    final List<List<dynamic>> rows = [];
    double totalPaid = 0;
    double totalPending = 0;

    String safeCurrency(double amount) {
      return CurrencyUtils.formatInrSafe(amount);
    }

    // Add Paid items if applicable
    if (status == ReportStatus.paid || status == ReportStatus.both) {
      final paidEntries = project.entries.where((e) {
        if (e.transactionType != TransactionType.expense) return false;
        return _isInCategory(e.categoryId, category);
      }).toList()..sort((a, b) => b.date.compareTo(a.date));

      for (var e in paidEntries) {
        final displayDesc = e.description
            .replaceFirst('Payment towards: ', '')
            .replaceFirst('payment towards: ', '');

        rows.add([
          DateFormat.yMMMd().format(e.date),
          displayDesc,
          _getCategoryLabel(e.categoryId),
          e.referenceData ?? '-',
          'PAID',
          safeCurrency(e.amount),
        ]);
        totalPaid += e.amount;
      }
    }

    // Add Pending items if applicable
    if (status == ReportStatus.pending || status == ReportStatus.both) {
      final relevantPayables = project.payables.where((p) {
        return _isInCategory(p.categoryId, category);
      }).toList();

      for (var p in relevantPayables) {
        final paidForPayable = project.entries
            .where((e) => e.payableId == p.id)
            .fold(0.0, (s, e) => s + e.amount);
        final remaining = p.totalAmount - paidForPayable;

        if (remaining > 0) {
          rows.add([
            DateFormat.yMMMd().format(p.dueDate),
            p.description,
            _getCategoryLabel(p.categoryId),
            p.vendorName,
            'PENDING',
            safeCurrency(remaining),
          ]);
          totalPending += remaining;
        }
      }
    }

    // Add Summary Row
    if (rows.isNotEmpty) {
      rows.add(['', '', '', '', '', '']); // Spacer
      if (status == ReportStatus.both || status == ReportStatus.paid) {
        rows.add(['', 'TOTAL PAID', '', '', '', safeCurrency(totalPaid)]);
      }
      if (status == ReportStatus.both || status == ReportStatus.pending) {
        rows.add(['', 'TOTAL PENDING', '', '', '', safeCurrency(totalPending)]);
      }
      if (status == ReportStatus.both) {
        rows.add([
          '',
          'GRAND TOTAL',
          '',
          '',
          '',
          safeCurrency(totalPaid + totalPending),
        ]);
      }
    }

    return rows;
  }

  static bool _isInCategory(String categoryId, ReportCategory category) {
    if (category == ReportCategory.all) return true;

    if (category == ReportCategory.material) {
      return categoryId.endsWith('-M') ||
          categoryId == EntryCategory.otherMiscMaterials;
    }
    if (category == ReportCategory.labour) {
      return categoryId.endsWith('-L');
    }
    if (category == ReportCategory.specialized) {
      return categoryId == EntryCategory.planApproval ||
          categoryId == EntryCategory.additionalWorks ||
          categoryId == EntryCategory.miscExp;
    }
    return false;
  }

  static String _getCategoryLabel(String categoryId) {
    const labels = {
      EntryCategory.paymentReceived: 'Payment Received',
      EntryCategory.cementM: 'Cement',
      EntryCategory.sandM: 'Sand',
      EntryCategory.aggregateM: 'Aggregate',
      EntryCategory.bricksM: 'Bricks',
      EntryCategory.steelM: 'Steel',
      EntryCategory.electricalM: 'Electrical (M)',
      EntryCategory.plumbingM: 'Plumbing (M)',
      EntryCategory.carpentryM: 'Carpentry (M)',
      EntryCategory.grillM: 'Grill',
      EntryCategory.tileM: 'Tile (M)',
      EntryCategory.paintM: 'Paint (M)',
      EntryCategory.rmcM: 'RMC',
      EntryCategory.masonL: 'Mason',
      EntryCategory.electricalL: 'Electrical (L)',
      EntryCategory.plumbingL: 'Plumbing (L)',
      EntryCategory.carpentryL: 'Carpentry (L)',
      EntryCategory.tileL: 'Tile (L)',
      EntryCategory.paintL: 'Paint (L)',
      EntryCategory.miscL: 'Misc Labour',
      EntryCategory.planApproval: 'Plan Approval',
      EntryCategory.otherMiscMaterials: 'Misc Materials',
      EntryCategory.additionalWorks: 'Additional Works',
      EntryCategory.miscExp: 'Miscellaneous',
    };
    return labels[categoryId] ?? categoryId;
  }
}
