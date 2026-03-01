import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';

class BudgetProvider with ChangeNotifier {
  List<Project> _projects = [];
  List<Revenue> _revenues = []; // Global/Unlinked revenues
  String? _userId;
  bool _isLoading = false;
  bool _hasLoaded = false;
  Future<void>? _activeFetch;

  List<Project> get projects => [..._projects];
  List<Revenue> get revenues => [..._revenues];
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  double get totalMonthlyReturn {
    final now = DateTime.now();

    // 1. Global Revenue
    double totalRev = _revenues
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);

    double totalExp = 0;

    for (var p in _projects) {
      // 2. Project Revenues
      totalRev += p.revenues
          .where((r) => r.date.year == now.year && r.date.month == now.month)
          .fold(0.0, (sum, item) => sum + item.amount);

      // 3. Project Expenses
      totalExp += p.expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0.0, (sum, item) => sum + item.amount);
    }

    return totalRev - totalExp;
  }

  double get totalYearlyReturn {
    final now = DateTime.now();

    double totalRev = _revenues
        .where((r) => r.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);

    double totalExp = 0;

    for (var p in _projects) {
      totalRev += p.revenues
          .where((r) => r.date.year == now.year)
          .fold(0.0, (sum, item) => sum + item.amount);

      totalExp += p.expenses
          .where((e) => e.date.year == now.year)
          .fold(0.0, (sum, item) => sum + item.amount);
    }

    return totalRev - totalExp;
  }

  double get allTimeExpenses {
    return _projects.fold(0.0, (sum, p) => sum + p.totalSpent);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void updateUserId(String? uid) {
    if (_userId != uid) {
      _userId = uid;
      _hasLoaded = false;
      _projects = [];
      _revenues = [];
      if (uid != null) {
        fetchAndSetProjects();
      }
      notifyListeners();
    }
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchAndSetProjects() async {
    if (_activeFetch != null) return _activeFetch!;

    _activeFetch = _performFetch();
    return _activeFetch!;
  }

  Future<void> _performFetch() async {
    if (_userId == null) {
      _isLoading = false;
      _activeFetch = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _firestore
            .collection('projects')
            .where('userId', isEqualTo: _userId)
            .get(),
        _firestore
            .collection('expenses')
            .where('userId', isEqualTo: _userId)
            .get(),
        _firestore
            .collection('revenues')
            .where('userId', isEqualTo: _userId)
            .get(),
      ]);

      final projectsSnapshot = results[0];
      final expensesSnapshot = results[1];
      final revenuesSnapshot = results[2];

      final List<Expense> allExpenses = expensesSnapshot.docs
          .map((doc) => Expense.fromJson(doc.data(), doc.id))
          .toList();

      final List<Revenue> allRevenues = revenuesSnapshot.docs
          .map((doc) => Revenue.fromJson(doc.data(), doc.id))
          .toList();

      // Separate revenues into "global" (no projectId) and "project-specific"
      final List<Project> loadedProjects = projectsSnapshot.docs.map((doc) {
        final projectExpenses = allExpenses
            .where((e) => e.projectId == doc.id)
            .toList();
        final projectRevenues = allRevenues
            .where((r) => r.projectId == doc.id)
            .toList();
        return Project.fromJson(
          doc.data(),
          doc.id,
          projectExpenses,
          projectRevenues,
        );
      }).toList();

      // Global revenues are those with an empty or non-existent projectId
      _revenues = allRevenues.where((r) => r.projectId.isEmpty).toList();
      _projects = loadedProjects;
      _isLoading = false;
      _hasLoaded = true;
      _activeFetch = null;
      notifyListeners();
    } catch (e, st) {
      _isLoading = false;
      _activeFetch = null;
      notifyListeners();
      debugPrint('fetchAndSetProjects error: $e\n$st');
      rethrow;
    }
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Future<void> addProject(String name, double budget) async {
    if (_userId == null) return;
    final newProjectData = {'name': name, 'budget': budget, 'userId': _userId};
    final docRef = await _firestore.collection('projects').add(newProjectData);

    final newProject = Project(
      id: docRef.id,
      name: name,
      budget: budget,
      expenses: [],
      revenues: [],
    );

    _projects.add(newProject);
    notifyListeners();
  }

  Future<void> updateProject(
    String projectId,
    String newName,
    double newBudget,
  ) async {
    await _firestore.collection('projects').doc(projectId).update({
      'name': newName,
      'budget': newBudget,
    });

    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final old = _projects[index];
      _projects[index] = Project(
        id: old.id,
        name: newName,
        budget: newBudget,
        expenses: old.expenses,
        revenues: old.revenues,
      );
      notifyListeners();
    }
  }

  Future<void> removeProject(String projectId) async {
    final existingProjectIndex = _projects.indexWhere((p) => p.id == projectId);

    if (existingProjectIndex >= 0) {
      _projects.removeAt(existingProjectIndex);
      notifyListeners();
    }

    try {
      await _firestore.collection('projects').doc(projectId).delete();

      // Cleanup related expenses
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('projectId', isEqualTo: projectId)
          .get();
      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Cleanup related revenues
      final revenuesSnapshot = await _firestore
          .collection('revenues')
          .where('projectId', isEqualTo: projectId)
          .get();
      for (var doc in revenuesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e, st) {
      debugPrint('removeProject error: $e\n$st');
      await fetchAndSetProjects();
    }
  }

  // ── Expenses ───────────────────────────────────────────────────────────────

  Future<void> addExpense(String projectId, Expense expense) async {
    if (_userId == null) return;
    final data = expense.toJson();
    data['userId'] = _userId;

    final docRef = await _firestore.collection('expenses').add(data);

    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      final addedExpense = Expense(
        id: docRef.id,
        projectId: expense.projectId,
        description: expense.description,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
        customCategoryName: expense.customCategoryName,
        quantity: expense.quantity,
        unit: expense.unit,
        materialType: expense.materialType,
        workerName: expense.workerName,
        vendorName: expense.vendorName,
      );
      _projects[projectIndex].expenses.add(addedExpense);
      notifyListeners();
    }
  }

  Future<void> removeExpense(String projectId, String expenseId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);

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
      await fetchAndSetProjects();
    }
  }

  // ── Revenues ───────────────────────────────────────────────────────────────

  Future<void> addRevenue(Revenue revenue) async {
    if (_userId == null) return;
    final data = revenue.toJson();
    data['userId'] = _userId;

    final docRef = await _firestore.collection('revenues').add(data);

    final addedRevenue = Revenue(
      id: docRef.id,
      projectId: revenue.projectId,
      amount: revenue.amount,
      description: revenue.description,
      date: revenue.date,
    );

    if (revenue.projectId.isEmpty) {
      _revenues.add(addedRevenue);
    } else {
      final projectIndex = _projects.indexWhere(
        (p) => p.id == revenue.projectId,
      );
      if (projectIndex >= 0) {
        _projects[projectIndex].revenues.add(addedRevenue);
      }
    }
    notifyListeners();
  }

  Future<void> removeRevenue(String revenueId) async {
    // Check global first
    int globalIndex = _revenues.indexWhere((r) => r.id == revenueId);
    if (globalIndex >= 0) {
      _revenues.removeAt(globalIndex);
      notifyListeners();
    } else {
      // Check projects
      for (var p in _projects) {
        int idx = p.revenues.indexWhere((r) => r.id == revenueId);
        if (idx >= 0) {
          p.revenues.removeAt(idx);
          notifyListeners();
          break;
        }
      }
    }

    try {
      await _firestore.collection('revenues').doc(revenueId).delete();
    } catch (e, st) {
      debugPrint('removeRevenue error: $e\n$st');
      await fetchAndSetProjects();
    }
  }
}
