import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/project.dart';
import 'package:alray_app/models/construction_entry.dart';
import 'package:alray_app/models/milestone.dart';
import 'package:alray_app/models/payable.dart';
import 'package:alray_app/models/snag_item.dart';

class BudgetProvider with ChangeNotifier {
  List<Project> _projects = [];
  List<ConstructionEntry> _globalEntries = []; // Unlinked credits/revenues
  String? _userId;
  String? _selectedProjectId;
  bool _isLoading = false;
  bool _hasLoaded = false;
  Future<void>? _activeFetch;

  List<Project> get projects => [..._projects];

  List<ConstructionEntry> get globalEntries => [..._globalEntries];

  List<ConstructionEntry> get allEntries {
    List<ConstructionEntry> list = [..._globalEntries];
    for (var p in _projects) {
      list.addAll(p.entries);
    }
    return list;
  }

  bool get isLoading => _isLoading;
  String? get currentUserId => _userId;
  bool get hasLoaded => _hasLoaded;
  String? get selectedProjectId => _selectedProjectId;

  void selectProject(String? id) {
    if (_selectedProjectId != id) {
      _selectedProjectId = id;
      notifyListeners();
    }
  }

  double get totalMonthlyReturn {
    final now = DateTime.now();
    double totalRev = 0;
    double totalExp = 0;

    for (var entry in allEntries) {
      if (entry.date.year == now.year && entry.date.month == now.month) {
        if (entry.transactionType == TransactionType.credit) {
          totalRev += entry.amount;
        } else {
          totalExp += entry.amount;
        }
      }
    }

    return totalRev - totalExp;
  }

  double get totalYearlyReturn {
    final now = DateTime.now();
    double totalRev = 0;
    double totalExp = 0;

    for (var entry in allEntries) {
      if (entry.date.year == now.year) {
        if (entry.transactionType == TransactionType.credit) {
          totalRev += entry.amount;
        } else {
          totalExp += entry.amount;
        }
      }
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
      _globalEntries = [];
      if (uid != null) {
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
            .collection('entries')
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
      final entriesSnapshot = results[3];
      final milestonesSnapshot = results[4];
      final payablesSnapshot = results[5];
      final snagsSnapshot = results[6];

      final List<ConstructionEntry> combinedEntries = [];

      combinedEntries.addAll(
        expensesSnapshot.docs.map(
          (doc) => ConstructionEntry.fromJson(doc.data(), doc.id),
        ),
      );
      combinedEntries.addAll(
        revenuesSnapshot.docs.map(
          (doc) => ConstructionEntry.fromJson(doc.data(), doc.id),
        ),
      );
      combinedEntries.addAll(
        entriesSnapshot.docs.map(
          (doc) => ConstructionEntry.fromJson(doc.data(), doc.id),
        ),
      );

      final List<Milestone> allMilestones = milestonesSnapshot.docs
          .map((doc) => Milestone.fromJson(doc.data(), doc.id))
          .toList();

      final List<Payable> allPayables = payablesSnapshot.docs
          .map((doc) => Payable.fromJson(doc.data(), doc.id))
          .toList();

      final List<SnagItem> allSnags = snagsSnapshot.docs
          .map((doc) => SnagItem.fromJson(doc.data(), doc.id))
          .toList();

      final List<Project> loadedProjects = projectsSnapshot.docs.map((doc) {
        final projectEntries = combinedEntries
            .where((e) => e.projectId == doc.id)
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

        projectMilestones.sort(
          (a, b) => a.dateCreated.compareTo(b.dateCreated),
        );
        projectSnags.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Project.fromJson(
          doc.data(),
          doc.id,
          projectEntries,
          projectMilestones,
          projectPayables,
          projectSnags,
        );
      }).toList();

      _globalEntries = combinedEntries
          .where((e) => e.projectId.isEmpty)
          .toList();
      _projects = loadedProjects;

      if (_selectedProjectId == null && _projects.isNotEmpty) {
        _selectedProjectId = _projects.first.id;
      } else if (_selectedProjectId != null &&
          !_projects.any((p) => p.id == _selectedProjectId)) {
        _selectedProjectId = _projects.isNotEmpty ? _projects.first.id : null;
      }

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
      entries: [],
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
        entries: old.entries,
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

      // We might have legacy expenses/revenues to delete as well
      final collections = [
        'expenses',
        'revenues',
        'entries',
        'milestones',
        'payables',
        'snags',
      ];
      for (var coll in collections) {
        final snap = await _firestore
            .collection(coll)
            .where('projectId', isEqualTo: projectId)
            .get();
        for (var doc in snap.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e, st) {
      debugPrint('removeProject error: $e\n$st');
      await fetchAndSetProjects();
    }
  }

  // ── Unified Entries ────────────────────────────────────────────────────────

  Future<void> addEntry(ConstructionEntry entry) async {
    if (_userId == null) return;
    final data = entry.toJson();
    data['userId'] = _userId;

    // Use unified 'entries' collection for new data
    final docRef = await _firestore.collection('entries').add(data);

    final addedEntry = ConstructionEntry(
      id: docRef.id,
      projectId: entry.projectId,
      date: entry.date,
      description: entry.description,
      transactionType: entry.transactionType,
      categoryId: entry.categoryId,
      quantity: entry.quantity,
      rate: entry.rate,
      paymentMode: entry.paymentMode,
      referenceData: entry.referenceData,
      attachmentUrl: entry.attachmentUrl,
      payableId: entry.payableId,
    );

    if (entry.projectId.isEmpty) {
      _globalEntries.add(addedEntry);
    } else {
      final projectIndex = _projects.indexWhere((p) => p.id == entry.projectId);
      if (projectIndex >= 0) {
        _projects[projectIndex].entries.add(addedEntry);
      }
    }
    notifyListeners();
  }

  Future<void> removeEntry(String entryId) async {
    // Check global
    int globalIndex = _globalEntries.indexWhere((e) => e.id == entryId);
    if (globalIndex >= 0) {
      _globalEntries.removeAt(globalIndex);
      notifyListeners();
    } else {
      for (var p in _projects) {
        int idx = p.entries.indexWhere((e) => e.id == entryId);
        if (idx >= 0) {
          p.entries.removeAt(idx);
          notifyListeners();
          break;
        }
      }
    }

    try {
      // Need to delete from whatever collection it came from.
      // Easiest is to try all three collections if we don't know the source collection.
      await _deleteFromAny('entries', entryId);
      await _deleteFromAny('expenses', entryId);
      await _deleteFromAny('revenues', entryId);
    } catch (e, st) {
      debugPrint('removeEntry error: $e\n$st');
      await fetchAndSetProjects();
    }
  }

  Future<void> _deleteFromAny(String collectionPath, String id) async {
    try {
      final doc = await _firestore.collection(collectionPath).doc(id).get();
      if (doc.exists) await doc.reference.delete();
    } catch (_) {}
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
