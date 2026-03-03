import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/models/attendance.dart';
import 'package:intl/intl.dart';

class AttendanceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Attendance> _attendances = [];
  String? _userId;
  StreamSubscription? _attendanceSubscription;

  List<Attendance> get attendances => [..._attendances];

  void updateUserId(String? uid) {
    if (_userId != uid) {
      _userId = uid;
      _attendances = [];
      _attendanceSubscription?.cancel();

      if (uid != null) {
        Future.microtask(() => startListening());
      } else {
        Future.microtask(() => notifyListeners());
      }
    }
  }

  void startListening() {
    if (_userId == null) return;

    _attendanceSubscription = _firestore
        .collection('attendances')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen((snapshot) {
          _attendances = snapshot.docs
              .map((doc) => Attendance.fromJson(doc.data(), doc.id))
              .toList();

          // Sort by date descending (Newest First)
          _attendances.sort((a, b) => b.date.compareTo(a.date));

          notifyListeners();
        });
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchAttendances() async {
    // Re-trigger the listener to ensure data is fresh.
    startListening();
  }

  Future<void> addAttendance(Attendance attendance) async {
    if (_userId == null) return;
    try {
      final newRef = _firestore.collection('attendances').doc();
      final data = attendance.toJson();
      data['userId'] = _userId;
      data['createdAt'] = FieldValue.serverTimestamp();

      final newAttendance = Attendance(
        id: newRef.id,
        projectId: attendance.projectId,
        date: attendance.date,
        workerCounts: attendance.workerCounts,
        workerWages: attendance.workerWages,
        presentWorkerIds: attendance.presentWorkerIds,
      );

      // Optimistic upate
      _attendances.insert(0, newAttendance);
      notifyListeners();

      await newRef.set(data);

      // Create ledger entries for each present worker
      for (var workerId in attendance.presentWorkerIds) {
        final wage = attendance.workerWages[workerId] ?? 0.0;
        if (wage > 0) {
          final entryRef = _firestore.collection('entries').doc();
          await entryRef.set({
            'projectId': attendance.projectId,
            'contactId': workerId,
            'amount': wage,
            'transactionType':
                'expense', // Attendance is an expense we owe the worker
            'description':
                'Attendance: ${DateFormat('dd MMM yyyy').format(attendance.date)}',
            'date': attendance.date.toIso8601String(),
            'userId': _userId,
            'createdAt': FieldValue.serverTimestamp(),
            'quantity': 1,
            'rate': wage,
            'categoryId': 'Labor', // Default category
          });
        }
      }
    } catch (e) {
      debugPrint('Error adding attendance: $e');
    }
  }

  Future<void> deleteAttendance(String id) async {
    try {
      // Optimistic UI update
      final index = _attendances.indexWhere((a) => a.id == id);
      if (index >= 0) {
        _attendances.removeAt(index);
        notifyListeners();
      }

      await _firestore.collection('attendances').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting attendance: $e');
      if (_userId != null) {
        // Re-sync if failed
        startListening();
      }
    }
  }

  List<Attendance> getAttendancesForProject(String projectId) {
    return _attendances.where((a) => a.projectId == projectId).toList();
  }
}
