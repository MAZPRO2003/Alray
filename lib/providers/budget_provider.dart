import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/expense.dart';
import 'package:alray_app/models/revenue.dart';
import 'package:alray_app/models/milestone.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/models/snag_item.dart';

class BudgetProvider with ChangeNotifier {
  List<Project> _projects = [];
  List<Revenue> _revenues = []; // Global/Unlinked revenues
  String? _userId;
  bool _isLoading = false;
  bool _hasLoaded = false;
  Future<void>? _activeFetch;

  List<Project> get projects => [..._projects];

  List<Revenue> get revenues {
    List<Revenue> allRevs = [..._revenues];
    for (var p in _projects) {
      allRevs.addAll(p.revenues);
    }
    return allRevs;
  }

  List<Expense> get expenses {
    List<Expense> allExps = [];
    for (var p in _projects) {
      allExps.addAll(p.expenses);
    }
    return allExps;
  }

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  double get totalMonthlyReturn {
    final now = DateTime.now();

    // 1. Global Revenue
    double totalRev = _revenues
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (total, item) => total + item.amount);

    double totalExp = 0;

    for (var p in _projects) {
      // 2. Project Revenues
      totalRev += p.revenues
          .where((r) => r.date.year == now.year && r.date.month == now.month)
          .fold(0.0, (total, item) => total + item.amount);

      // 3. Project Expenses
      totalExp += p.expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0.0, (total, item) => total + item.amount);
    }

    return totalRev - totalExp;
  }

  double get totalYearlyReturn {
    final now = DateTime.now();

    double totalRev = _revenues
        .where((r) => r.date.year == now.year)
        .fold(0.0, (total, item) => total + item.amount);

    double totalExp = 0;

    for (var p in _projects) {
      totalRev += p.revenues
          .where((r) => r.date.year == now.year)
          .fold(0.0, (total, item) => total + item.amount);

      totalExp += p.expenses
          .where((e) => e.date.year == now.year)
          .fold(0.0, (total, item) => total + item.amount);
    }

    return totalRev - totalExp;
  }

  double get allTimeExpenses {
    return _projects.fold(0.0, (total, p) => total + p.totalSpent);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void updateUserId(String? uid) {
    if (_userId != uid) {
      _userId = uid;
      _hasLoaded = false;
      _projects = [];
      _revenues = [];
      if (uid != null) {
        // Defer to avoid "setState() called during build" from proxy provider update
        Future.microtask(() => fetchAndSetProjects());
      } else {
        Future.microtask(() => notifyListeners());
      }
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
        _firestore
            .collection('milestones')
            .where('userId', isEqualTo: _userId)
            .get(),
        _firestore
            .collection('payables')
            .where('userId', isEqualTo: _userId)
            .get(),
        _firestore
            .collection('snags')
            .where('userId', isEqualTo: _userId)
            .get(),
      ]);

      final projectsSnapshot = results[0];
      final expensesSnapshot = results[1];
      final revenuesSnapshot = results[2];
      final milestonesSnapshot = results[3];
      final payablesSnapshot = results[4];
      final snagsSnapshot = results[5];

      final List<Expense> allExpenses = expensesSnapshot.docs
          .map((doc) => Expense.fromJson(doc.data(), doc.id))
          .toList();

      final List<Revenue> allRevenues = revenuesSnapshot.docs
          .map((doc) => Revenue.fromJson(doc.data(), doc.id))
          .toList();

      final List<Milestone> allMilestones = milestonesSnapshot.docs
          .map((doc) => Milestone.fromJson(doc.data(), doc.id))
          .toList();

      final List<Payable> allPayables = payablesSnapshot.docs
          .map((doc) => Payable.fromJson(doc.data(), doc.id))
          .toList();

      final List<SnagItem> allSnags = snagsSnapshot.docs
          .map((doc) => SnagItem.fromJson(doc.data(), doc.id))
          .toList();

      // Separate revenues into "global" (no projectId) and "project-specific"
      final List<Project> loadedProjects = projectsSnapshot.docs.map((doc) {
        final projectExpenses = allExpenses
            .where((e) => e.projectId == doc.id)
            .toList();
        final projectRevenues = allRevenues
            .where((r) => r.projectId == doc.id)
            .toList();
        final projectMilestones = allMilestones
            .where((m) => m.projectId == doc.id)
            .toList();
        final projectPayables = allPayables
            .where((p) => p.projectId == doc.id)
            .toList();
        final projectSnags = allSnags
            .where((s) => s.projectId == doc.id)
            .toList();

        // Sort milestones by date ascending (oldest first, new ones go down)
        projectMilestones.sort(
          (a, b) => a.dateCreated.compareTo(b.dateCreated),
        );

        // Sort snags by date descending
        projectSnags.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Project.fromJson(
          doc.data(),
          doc.id,
          projectExpenses,
          projectRevenues,
          projectMilestones,
          projectPayables,
          projectSnags,
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

  Future<void> addProject(
    String name,
    double budget, {
    double? latitude,
    double? longitude,
    DateTime? startDate,
    DateTime? endDate,
    String? customerPhone,
  }) async {
    if (_userId == null) return;
    final newProjectData = {
      'name': name,
      'budget': budget,
      'userId': _userId,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'customerPhone': customerPhone,
    };
    final docRef = await _firestore.collection('projects').add(newProjectData);

    final newProject = Project(
      id: docRef.id,
      name: name,
      budget: budget,
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
      customerPhone: customerPhone,
      expenses: [],
      revenues: [],
      milestones: [],
      payables: [],
      snagItems: [],
    );

    _projects.add(newProject);
    notifyListeners();
  }

  Future<void> updateProject(
    String projectId,
    String newName,
    double newBudget, {
    double? latitude,
    double? longitude,
    DateTime? startDate,
    DateTime? endDate,
    String? customerPhone,
  }) async {
    await _firestore.collection('projects').doc(projectId).update({
      'name': newName,
      'budget': newBudget,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'customerPhone': customerPhone,
    });

    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final old = _projects[index];
      _projects[index] = Project(
        id: old.id,
        name: newName,
        budget: newBudget,
        latitude: latitude,
        longitude: longitude,
        startDate: startDate,
        endDate: endDate,
        customerPhone: customerPhone,
        expenses: old.expenses,
        revenues: old.revenues,
        milestones: old.milestones,
        payables: old.payables,
        snagItems: old.snagItems,
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

      // Cleanup related milestones
      final milestonesSnapshot = await _firestore
          .collection('milestones')
          .where('projectId', isEqualTo: projectId)
          .get();
      for (var doc in milestonesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Cleanup related payables
      final payablesSnapshot = await _firestore
          .collection('payables')
          .where('projectId', isEqualTo: projectId)
          .get();
      for (var doc in payablesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Cleanup related snags
      final snagsSnapshot = await _firestore
          .collection('snags')
          .where('projectId', isEqualTo: projectId)
          .get();
      for (var doc in snagsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e, st) {
      debugPrint('removeProject error: $e\n$st');
      await fetchAndSetProjects();
    }
  }

  // ── Weather History ────────────────────────────────────────────────────────
  // The fetchWeatherForProject method is removed as per instructions.

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
        attachmentUrl: expense.attachmentUrl,
        payableId: expense.payableId,
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

  // ── Milestones ─────────────────────────────────────────────────────────────

  Future<void> addMilestone(String projectId, String title) async {
    if (_userId == null) return;
    final newMilestone = Milestone(
      projectId: projectId,
      title: title,
      dateCreated: DateTime.now(),
    );
    final data = newMilestone.toJson();
    data['userId'] = _userId;

    final docRef = await _firestore.collection('milestones').add(data);
    final addedMilestone = newMilestone.copyWith(id: docRef.id);

    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      _projects[projectIndex].milestones.add(addedMilestone);
      notifyListeners();
    }
  }

  Future<bool> toggleMilestone(
    String projectId,
    String milestoneId,
    bool isCompleted,
  ) async {
    bool triggeredCapitalCall = false;
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      final milestoneIndex = _projects[projectIndex].milestones.indexWhere(
        (m) => m.id == milestoneId,
      );

      if (milestoneIndex >= 0) {
        final currentCompletion =
            _projects[projectIndex].milestones[milestoneIndex].isCompleted;

        // If it wasn't completed before, but now it is, trigger capital call
        if (!currentCompletion && isCompleted) {
          triggeredCapitalCall = true;
        }

        _projects[projectIndex].milestones[milestoneIndex] =
            _projects[projectIndex].milestones[milestoneIndex].copyWith(
              isCompleted: isCompleted,
            );
        notifyListeners();
      }
    }

    try {
      await _firestore.collection('milestones').doc(milestoneId).update({
        'isCompleted': isCompleted,
      });
    } catch (e, st) {
      debugPrint('toggleMilestone error: $e\n$st');
      await fetchAndSetProjects();
    }

    return triggeredCapitalCall;
  }

  Future<void> removeMilestone(String projectId, String milestoneId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      final milestoneIndex = _projects[projectIndex].milestones.indexWhere(
        (m) => m.id == milestoneId,
      );

      if (milestoneIndex >= 0) {
        _projects[projectIndex].milestones.removeAt(milestoneIndex);
        notifyListeners();
      }
    }

    try {
      await _firestore.collection('milestones').doc(milestoneId).delete();
    } catch (e, st) {
      debugPrint('removeMilestone error: $e\n$st');
      await fetchAndSetProjects();
    }
  }

  // ── Payables ─────────────────────────────────────────────────────────────

  Future<void> addPayable(Payable payable) async {
    if (_userId == null) return;
    final data = payable.toJson();
    data['userId'] = _userId;

    final docRef = await _firestore.collection('payables').add(data);
    final addedPayable = payable.copyWith(id: docRef.id);

    final projectIndex = _projects.indexWhere((p) => p.id == payable.projectId);
    if (projectIndex >= 0) {
      _projects[projectIndex].payables.add(addedPayable);
      notifyListeners();
    }
  }

  Future<void> updatePayable(Payable payable) async {
    await _firestore
        .collection('payables')
        .doc(payable.id)
        .update(payable.toJson());

    final projectIndex = _projects.indexWhere((p) => p.id == payable.projectId);
    if (projectIndex >= 0) {
      final payableIndex = _projects[projectIndex].payables.indexWhere(
        (p) => p.id == payable.id,
      );
      if (payableIndex >= 0) {
        _projects[projectIndex].payables[payableIndex] = payable;
        notifyListeners();
      }
    }
  }

  Future<void> removePayable(String projectId, String payableId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      final payableIndex = _projects[projectIndex].payables.indexWhere(
        (p) => p.id == payableId,
      );
      if (payableIndex >= 0) {
        _projects[projectIndex].payables.removeAt(payableIndex);
        notifyListeners();
      }
    }

    try {
      await _firestore.collection('payables').doc(payableId).delete();
    } catch (e, st) {
      debugPrint('removePayable error: $e\n$st');
      await fetchAndSetProjects();
    }
  }
  // ── Snag Items ─────────────────────────────────────────────────────────

  Future<void> addSnagItem(SnagItem snagItem) async {
    if (_userId == null) return;
    final data = snagItem.toJson();
    data['userId'] = _userId;

    final docRef = await _firestore.collection('snags').add(data);

    // We create a new item with the generated ID, copyWith is not available so we just construct a new one
    final addedSnag = SnagItem(
      id: docRef.id,
      projectId: snagItem.projectId,
      description: snagItem.description,
      status: snagItem.status,
      priority: snagItem.priority,
      createdAt: snagItem.createdAt,
      resolvedAt: snagItem.resolvedAt,
    );

    final projectIndex = _projects.indexWhere(
      (p) => p.id == snagItem.projectId,
    );
    if (projectIndex >= 0) {
      _projects[projectIndex].snagItems.insert(0, addedSnag);
      notifyListeners();
    }
  }

  Future<void> updateSnagItem(SnagItem snagItem) async {
    await _firestore
        .collection('snags')
        .doc(snagItem.id)
        .update(snagItem.toJson());

    final projectIndex = _projects.indexWhere(
      (p) => p.id == snagItem.projectId,
    );
    if (projectIndex >= 0) {
      final snagIndex = _projects[projectIndex].snagItems.indexWhere(
        (s) => s.id == snagItem.id,
      );
      if (snagIndex >= 0) {
        _projects[projectIndex].snagItems[snagIndex] = snagItem;
        notifyListeners();
      }
    }
  }

  Future<void> removeSnagItem(String projectId, String snagId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex >= 0) {
      final snagIndex = _projects[projectIndex].snagItems.indexWhere(
        (s) => s.id == snagId,
      );
      if (snagIndex >= 0) {
        _projects[projectIndex].snagItems.removeAt(snagIndex);
        notifyListeners();
      }
    }

    try {
      await _firestore.collection('snags').doc(snagId).delete();
    } catch (e, st) {
      debugPrint('removeSnagItem error: $e\n$st');
      await fetchAndSetProjects();
    }
  }
}
