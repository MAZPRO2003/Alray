import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/utils/project_report_generator.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportSelectionDialog extends StatefulWidget {
  final Project project;

  const ReportSelectionDialog({super.key, required this.project});

  @override
  State<ReportSelectionDialog> createState() => _ReportSelectionDialogState();
}

class _ReportSelectionDialogState extends State<ReportSelectionDialog> {
  ReportCategory _selectedCategory = ReportCategory.all;
  ReportStatus _selectedStatus = ReportStatus.both;
  bool _isPdf = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Generate Report',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryChip(
              ReportCategory.all,
              'Overall',
              Icons.dashboard_outlined,
            ),
            _buildCategoryChip(
              ReportCategory.material,
              'Material',
              Icons.inventory_2_outlined,
            ),
            _buildCategoryChip(
              ReportCategory.labour,
              'Labour',
              Icons.construction_outlined,
            ),
            _buildCategoryChip(
              ReportCategory.specialized,
              'Specialized',
              Icons.more_horiz,
            ),

            const SizedBox(height: 20),
            Text(
              'Select Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusChip(
              ReportStatus.both,
              'Paid & Pending',
              Icons.all_inclusive,
            ),
            _buildStatusChip(
              ReportStatus.paid,
              'Paid Only (Expenses)',
              Icons.payments_outlined,
            ),
            _buildStatusChip(
              ReportStatus.pending,
              'Pending Only (Bills)',
              Icons.hourglass_bottom_rounded,
            ),

            const SizedBox(height: 20),
            Text(
              'Export Format',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFormatCard(
                    true,
                    'PDF Document',
                    Icons.picture_as_pdf,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormatCard(
                    false,
                    'Excel (CSV)',
                    Icons.table_chart,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    ReportCategory category,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
              if (isSelected) const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status, String label, IconData icon) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
              if (isSelected) const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCard(
    bool isPdfFormat,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _isPdf == isPdfFormat;
    return InkWell(
      onTap: () => setState(() => _isPdf = isPdfFormat),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    setState(() => _isLoading = true);
    try {
      await ProjectReportGenerator.generate(
        context: context,
        project: widget.project,
        category: _selectedCategory,
        status: _selectedStatus,
        isPdf: _isPdf,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
