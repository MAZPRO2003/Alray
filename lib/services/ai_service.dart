import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:intl/intl.dart';

class AiService {
  static const String apiKeyPrefName = 'gemini_api_key';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getApiKey(String? userId) async {
    final prefs = await SharedPreferences.getInstance();

    if (userId != null) {
      try {
        final doc = await _firestore
            .collection('user_settings')
            .doc(userId)
            .get();
        if (doc.exists &&
            doc.data() != null &&
            doc.data()!['gemini_api_key'] != null) {
          final cloudKey = doc.data()!['gemini_api_key'] as String;
          await prefs.setString(apiKeyPrefName, cloudKey);
          return cloudKey;
        }
      } catch (e) {
        // Fallback to local if network fails
      }
    }

    // Check local cache
    final localKey = prefs.getString(apiKeyPrefName);
    if (localKey != null && localKey.isNotEmpty) return localKey;

    // Fall back to global shared key (set by app admin — works for all accounts)
    try {
      final globalDoc = await _firestore
          .collection('app_config')
          .doc('global')
          .get();
      if (globalDoc.exists &&
          globalDoc.data() != null &&
          globalDoc.data()!['gemini_api_key'] != null) {
        return globalDoc.data()!['gemini_api_key'] as String;
      }
    } catch (e) {
      // ignore
    }

    return null;
  }

  Future<void> setApiKey(String? userId, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiKeyPrefName, key);

    if (userId != null) {
      await _firestore.collection('user_settings').doc(userId).set({
        'gemini_api_key': key,
      }, SetOptions(merge: true));
    }

    // Also save as global key so all accounts can use it
    await _firestore.collection('app_config').doc('global').set({
      'gemini_api_key': key,
    }, SetOptions(merge: true));
  }

  Future<String> processNaturalLanguageQuery(
    String query,
    List<Project> allProjects,
    List<Expense> allExpenses,
    List<Revenue> allRevenues,
    String? userId,
  ) async {
    final apiKey = await getApiKey(userId);
    if (apiKey == null || apiKey.isEmpty) {
      return 'API Key not found. Please set your Gemini API Key in the Settings screen.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      // Serialize app data into a readable format for context
      final contextBuilder = StringBuffer();
      contextBuilder.writeln(
        'You are a smart AI assistant for a Real Estate Budget App named Alray.',
      );
      contextBuilder.writeln(
        'Here is the current state of the user\'s data:\n',
      );

      contextBuilder.writeln('--- PROJECTS ---');
      for (var p in allProjects) {
        contextBuilder.writeln(
          '- ${p.name} (Budget: ${p.budget}, Spent: ${p.totalSpent}, Received: ${p.totalReceived})',
        );
      }

      contextBuilder.writeln('\n--- EXPENSES ---');
      for (var e in allExpenses) {
        contextBuilder.writeln(
          '- ${e.description}: ${e.amount} on ${DateFormat('yyyy-MM-dd').format(e.date)} (Category: ${e.category.name})',
        );
      }

      contextBuilder.writeln('\n--- REVENUES ---');
      for (var r in allRevenues) {
        contextBuilder.writeln(
          '- Received ${r.amount} on ${DateFormat('yyyy-MM-dd').format(r.date)}',
        );
      }

      contextBuilder.writeln(
        '\nWhen answering the user\'s query, refer ONLY to the data provided above. Provide a concise, friendly, and helpful answer. Structure your answer using markdown if appropriate.',
      );
      contextBuilder.writeln('\nUser Query: $query');

      final content = [Content.text(contextBuilder.toString())];
      final response = await model.generateContent(content);

      return response.text ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      final err = e.toString();
      if (err.contains('quota') ||
          err.contains('429') ||
          err.contains('RESOURCE_EXHAUSTED')) {
        return '⚠️ Free tier limit reached. Please wait about 1 minute and try again. (Google allows ~15 requests/minute on free plans.)';
      }
      return 'Error processing query: $e';
    }
  }

  Future<String> predictProjectDelays(Project project, String? userId) async {
    final apiKey = await getApiKey(userId);
    if (apiKey == null || apiKey.isEmpty) {
      return 'API Key not found. Please set your Gemini API Key in the Settings screen.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      final contextBuilder = StringBuffer();
      contextBuilder.writeln(
        'You are an expert AI project manager and risk analyst in the real estate construction domain.',
      );
      contextBuilder.writeln(
        'Analyze the following project data and predict potential delays or risks. Provide actionable recommendations.\n',
      );

      contextBuilder.writeln('Project Name: ${project.name}');
      contextBuilder.writeln('Budget: ${project.budget}');
      contextBuilder.writeln('Total Spent: ${project.totalSpent}');
      contextBuilder.writeln(
        'Start Date: ${project.startDate != null ? DateFormat('yyyy-MM-dd').format(project.startDate!) : 'N/A'}',
      );
      contextBuilder.writeln(
        'End Date: ${project.endDate != null ? DateFormat('yyyy-MM-dd').format(project.endDate!) : 'N/A'}',
      );

      contextBuilder.writeln('\n--- MILESTONES ---');
      for (var m in project.milestones) {
        contextBuilder.writeln(
          '- ${m.title}: ${m.isCompleted ? "Completed" : "Pending"} (Created: ${DateFormat('yyyy-MM-dd').format(m.dateCreated)})',
        );
      }

      contextBuilder.writeln('\n--- RECENT EXPENSES ---');
      final sortedExpenses = List.from(project.expenses)
        ..sort((a, b) => b.date.compareTo(a.date));
      for (var e in sortedExpenses.take(5)) {
        contextBuilder.writeln(
          '- ${e.description}: ${e.amount} (${e.category.name})',
        );
      }

      contextBuilder.writeln('\nPlease provide a Risk Report consisting of:');
      contextBuilder.writeln('1. Delay Probability (Low/Medium/High/Critical)');
      contextBuilder.writeln('2. Key Bottlenecks Identified');
      contextBuilder.writeln('3. Actionable Recommendations');
      contextBuilder.writeln('Format as a cohesive Markdown report.');

      final content = [Content.text(contextBuilder.toString())];
      final response = await model.generateContent(content);

      return response.text ?? 'Sorry, I could not generate a prediction.';
    } catch (e) {
      final err = e.toString();
      if (err.contains('quota') ||
          err.contains('429') ||
          err.contains('RESOURCE_EXHAUSTED')) {
        return '⚠️ Free tier limit reached. Please wait about 1 minute and try again.';
      }
      return 'Error analyzing project risk: $e';
    }
  }
}
