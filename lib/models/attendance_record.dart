import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alray_app/utils/date_utils.dart' as alray_date;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Stores a single day's attendance: for each worker type the count and
/// their individual daily rate (₹). Total cost = sum(count × rate).
class AttendanceRecord {
  final String id;
  final String projectId;
  final DateTime date;

  // ── Counts (how many of each role were present) ──────────────────────────
  final int mason;
  final int helper;
  final int plumber;
  final int electrician;
  final int carpenter;
  final int steelWorker;
  final int grillWorker;
  final int tileLabour;
  final int customEntered;
  final int others;

  // ── Daily rates per worker in each role (₹) ──────────────────────────────
  final double masonRate;
  final double helperRate;
  final double plumberRate;
  final double electricianRate;
  final double carpenterRate;
  final double steelWorkerRate;
  final double grillWorkerRate;
  final double tileLabourRate;
  final double customEnteredRate;
  final double othersRate;

  final String customRoleName;
  final String notes;

  AttendanceRecord({
    String? id,
    required this.projectId,
    DateTime? date,
    this.mason = 0,
    this.helper = 0,
    this.plumber = 0,
    this.electrician = 0,
    this.carpenter = 0,
    this.steelWorker = 0,
    this.grillWorker = 0,
    this.tileLabour = 0,
    this.customEntered = 0,
    this.others = 0,
    this.masonRate = 0,
    this.helperRate = 0,
    this.plumberRate = 0,
    this.electricianRate = 0,
    this.carpenterRate = 0,
    this.steelWorkerRate = 0,
    this.grillWorkerRate = 0,
    this.tileLabourRate = 0,
    this.customEnteredRate = 0,
    this.othersRate = 0,
    this.customRoleName = '',
    this.notes = '',
  }) : id = id ?? _uuid.v4(),
       date = date ?? DateTime.now();

  int get totalWorkers =>
      mason +
      helper +
      plumber +
      electrician +
      carpenter +
      steelWorker +
      grillWorker +
      tileLabour +
      customEntered +
      others;

  double get totalCost =>
      mason * masonRate +
      helper * helperRate +
      plumber * plumberRate +
      electrician * electricianRate +
      carpenter * carpenterRate +
      steelWorker * steelWorkerRate +
      grillWorker * grillWorkerRate +
      tileLabour * tileLabourRate +
      customEntered * customEnteredRate +
      others * othersRate;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json, String docId) {
    double _d(String key) => (json[key] as num? ?? 0).toDouble();
    int _i(String key) => json[key] as int? ?? 0;

    return AttendanceRecord(
      id: docId,
      projectId: json['projectId'] as String? ?? '',
      date: alray_date.DateUtils.parseRequired(json['date']),
      mason: _i('mason'),
      helper: _i('helper'),
      plumber: _i('plumber'),
      electrician: _i('electrician'),
      carpenter: _i('carpenter'),
      steelWorker: _i('steelWorker'),
      grillWorker: _i('grillWorker'),
      tileLabour: _i('tileLabour'),
      customEntered: _i('customEntered'),
      others: _i('others'),
      masonRate: _d('masonRate'),
      helperRate: _d('helperRate'),
      plumberRate: _d('plumberRate'),
      electricianRate: _d('electricianRate'),
      carpenterRate: _d('carpenterRate'),
      steelWorkerRate: _d('steelWorkerRate'),
      grillWorkerRate: _d('grillWorkerRate'),
      tileLabourRate: _d('tileLabourRate'),
      customEnteredRate: _d('customEnteredRate'),
      othersRate: _d('othersRate'),
      customRoleName: json['customRoleName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'date': Timestamp.fromDate(date),
    'mason': mason,
    'helper': helper,
    'plumber': plumber,
    'electrician': electrician,
    'carpenter': carpenter,
    'steelWorker': steelWorker,
    'grillWorker': grillWorker,
    'tileLabour': tileLabour,
    'customEntered': customEntered,
    'others': others,
    'masonRate': masonRate,
    'helperRate': helperRate,
    'plumberRate': plumberRate,
    'electricianRate': electricianRate,
    'carpenterRate': carpenterRate,
    'steelWorkerRate': steelWorkerRate,
    'grillWorkerRate': grillWorkerRate,
    'tileLabourRate': tileLabourRate,
    'customEnteredRate': customEnteredRate,
    'othersRate': othersRate,
    'customRoleName': customRoleName,
    'notes': notes,
  };

  AttendanceRecord copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    int? mason,
    int? helper,
    int? plumber,
    int? electrician,
    int? carpenter,
    int? steelWorker,
    int? grillWorker,
    int? tileLabour,
    int? customEntered,
    int? others,
    double? masonRate,
    double? helperRate,
    double? plumberRate,
    double? electricianRate,
    double? carpenterRate,
    double? steelWorkerRate,
    double? grillWorkerRate,
    double? tileLabourRate,
    double? customEnteredRate,
    double? othersRate,
    String? customRoleName,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      mason: mason ?? this.mason,
      helper: helper ?? this.helper,
      plumber: plumber ?? this.plumber,
      electrician: electrician ?? this.electrician,
      carpenter: carpenter ?? this.carpenter,
      steelWorker: steelWorker ?? this.steelWorker,
      grillWorker: grillWorker ?? this.grillWorker,
      tileLabour: tileLabour ?? this.tileLabour,
      customEntered: customEntered ?? this.customEntered,
      others: others ?? this.others,
      masonRate: masonRate ?? this.masonRate,
      helperRate: helperRate ?? this.helperRate,
      plumberRate: plumberRate ?? this.plumberRate,
      electricianRate: electricianRate ?? this.electricianRate,
      carpenterRate: carpenterRate ?? this.carpenterRate,
      steelWorkerRate: steelWorkerRate ?? this.steelWorkerRate,
      grillWorkerRate: grillWorkerRate ?? this.grillWorkerRate,
      tileLabourRate: tileLabourRate ?? this.tileLabourRate,
      customEnteredRate: customEnteredRate ?? this.customEnteredRate,
      othersRate: othersRate ?? this.othersRate,
      customRoleName: customRoleName ?? this.customRoleName,
      notes: notes ?? this.notes,
    );
  }
}
