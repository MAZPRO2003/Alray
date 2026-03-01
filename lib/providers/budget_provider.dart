import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';

class BudgetProvider with ChangeNotifier {
  List<Project> _projects = [];
  List<Revenue> _revenues = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<Project> get projects => [..._projects];
  List<Revenue> get revenues => [..._revenues];
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  double get totalMonthlyReturn {
    final now = DateTime.now();
    final rev = _revenues
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);

    double exp = 0;
    for (var p in _projects) {
      exp += p.expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0.0, (sum, item) => sum + item.amount);
    }
    return rev - exp;
  }

  double get totalYearlyReturn {
    final now = DateTime.now();
    final rev = _revenues
        .where((r) => r.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);

    double exp = 0;
    for (var p in _projects) {
      exp += p.expenses
          .where((e) => e.date.year == now.year)
          .fold(0.0, (sum, item) => sum + item.amount);
    }
    return rev - exp;
  }

  double get allTimeExpenses {
    return _projects.fold(0.0, (sum, p) => sum + p.totalExpenses);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchAndSetProjects() async {
    if (_isLoading) return; // guard against concurrent fetches
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _firestore.collection('projects').get(),
        _firestore.collection('expenses').get(),
        _firestore.collection('revenues').get(),
      ]);

      final projectsSnapshot = results[0];
      final expensesSnapshot = results[1];
      final revenuesSnapshot = results[2];

      final List<Expense> allExpenses = expensesSnapshot.docs
          .map((doc) => Expense.fromJson(doc.data(), doc.id))
          .toList();

      final List<Revenue> loadedRevenues = revenuesSnapshot.docs
          .map((doc) => Revenue.fromJson(doc.data(), doc.id))
          .toList();

      final List<Project> loadedProjects = projectsSnapshot.docs.map((doc) {
        final projectExpenses = allExpenses
            .where((e) => e.projectId == doc.id)
            .toList();
        return Project.fromJson(doc.data(), doc.id, projectExpenses);
      }).toList();

      _projects = loadedProjects;
      _revenues = loadedRevenues;
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    } catch (e, st) {
      _isLoading = false;
      notifyListeners();
      debugPrint('fetchAndSetProjects error: $e\n$st');
      rethrow; // Let the UI FutureBuilder show the error
    }
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Future<void> addProject(String name, double budget) async {
    final newProjectData = {'name': name, 'budget': budget};

    // Write to Firestore first — we need the document ID.
    final docRef = await _firestore.collection('projects').add(newProjectData);
    // rethrow is automatic if .add() throws

    final newProject = Project(
      id: docRef.id,
      name: name,
      budget: budget,
      expenses: [],
    );

    _projects.add(newProject);
    notifyListeners();
  }

  Future<void> updateProject(
    String projectId,
    String newName,
    double newBudget,
  ) async {
    // Write to Firestore — rethrows on failure so the dialog can show the error
    await _firestore.collection('projects').doc(projectId).update({
      'name': newName,
      'budget': newBudget,
    });

    // Optimistic local update
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final old = _projects[index];
      _projects[index] = Project(
        id: old.id,
        name: newName,
        budget: newBudget,
        expenses: old.expenses,
      );
      notifyListeners();
    }
  }

  Future<void> removeProject(String projectId) async {
    final existingProjectIndex = _projects.indexWhere((p) => p.id == projectId);

    // OPTIMISTIC UPDATE: Remove locally first for instant UI
    if (existingProjectIndex >= 0) {
      _projects.removeAt(existingProjectIndex);
      notifyListeners();
    }

    try {
      await _firestore.collection('projects').doc(projectId).delete();

      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('projectId', isEqualTo: projectId)
          .get();
      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e, st) {
      debugPrint('removeProject error: $e\n$st');
      // Revert optimism if network failed
      await fetchAndSetProjects();
    }
  }

  // ── Expenses ───────────────────────────────────────────────────────────────

  Future<void> addExpense(String projectId, Expense expense) async {
    final docRef = await _firestore
        .collection('expenses')
        .add(expense.toJson());
    // rethrow is automatic if .add() throws

    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      final addedExpense = Expense(
        id: docRef.id,
        projectId: expense.projectId,
        description: expense.description,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
      );
      _projects[projectIndex].expenses.add(addedExpense);
      notifyListeners();
    }
  }

  Future<void> removeExpense(String projectId, String expenseId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);

    // OPTIMISTIC UPDATE: Remove locally first
    if (projectIndex >= 0) {
      final expenseIndex = _projects[projectIndex].expenses.indexWhere(
        (e) => e.id == expenseId,
      );
      if (expenseIndex >= 0) {
        _projects[projectIndex].expenses.removeAt(expenseIndex);
        notifyListeners();
      }
    }

    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
    } catch (e, st) {
      debugPrint('removeExpense error: $e\n$st');
      await fetchAndSetProjects(); // Revert on failure
    }
  }

  // ── Revenues ───────────────────────────────────────────────────────────────

  Future<void> addRevenue(Revenue revenue) async {
    final docRef = await _firestore
        .collection('revenues')
        .add(revenue.toJson());
    // rethrow is automatic if .add() throws

    final addedRevenue = Revenue(
      id: docRef.id,
      amount: revenue.amount,
      description: revenue.description,
      date: revenue.date,
    );

    _revenues.add(addedRevenue);
    notifyListeners();
  }

  Future<void> removeRevenue(String revenueId) async {
    final revenueIndex = _revenues.indexWhere((r) => r.id == revenueId);

    // OPTIMISTIC UPDATE
    if (revenueIndex >= 0) {
      _revenues.removeAt(revenueIndex);
      notifyListeners();
    }

    try {
      await _firestore.collection('revenues').doc(revenueId).delete();
    } catch (e, st) {
      debugPrint('removeRevenue error: $e\n$st');
      await fetchAndSetProjects(); // Revert on failure
    }
  }
}
