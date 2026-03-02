import 'package:flutter/material.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/services/ai_service.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/auth_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiRiskDialog extends StatefulWidget {
  final Project project;
  const AiRiskDialog({super.key, required this.project});

  @override
  State<AiRiskDialog> createState() => _AiRiskDialogState();
}

class _AiRiskDialogState extends State<AiRiskDialog> {
  final AiService _aiService = AiService();
  String? _prediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    final result = await _aiService.predictProjectDelays(
      widget.project,
      userId,
    );
    if (mounted) {
      setState(() {
        _prediction = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.smart_toy, color: Colors.indigo),
          SizedBox(width: 8),
          Text('AI Risk Analysis'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing project timeline, expenses, and milestones...',
                  ),
                ],
              )
            : SingleChildScrollView(
                child: MarkdownBody(
                  data: _prediction ?? 'Unable to retrieve prediction.',
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
