import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum TransactionType { expense, credit }

class EntryCategory {
  // Income
  static const String paymentReceived = 'paymentReceived';

  // Material (-M)
  static const String cementM = 'cement-M';
  static const String sandM = 'sand-M';
  static const String aggregateM = 'aggregate-M';
  static const String bricksM = 'bricks-M';
  static const String steelM = 'steel-M';
  static const String electricalM = 'electrical-M';
  static const String plumbingM = 'plumbing-M';
  static const String carpentryM = 'carpentry-M';
  static const String grillM = 'grill-M';
  static const String tileM = 'tile-M';
  static const String paintM = 'paint-M';
  static const String rmcM = 'rmc-M';

  // Labour (-L)
  static const String masonL = 'mason-L';
  static const String electricalL = 'electrical-L';
  static const String plumbingL = 'plumbing-L';
  static const String carpentryL = 'carpentry-L';
  static const String tileL = 'tile-L';
  static const String paintL = 'paint-L';
  static const String miscL = 'misc-L'; // Watchman, sand moving, debris

  // Specialized
  static const String planApproval = 'planApproval';
  static const String otherMiscMaterials =
      'otherMiscMaterials'; // Well pooja, temporary toilet
  static const String additionalWorks =
      'additionalWorks'; // Damp roof paint, sump

  // Legacy / fallback
  static const String miscExp = 'miscExp';

  static const List<String> allCategories = [
    paymentReceived,
    cementM,
    sandM,
    aggregateM,
    bricksM,
    steelM,
    electricalM,
    plumbingM,
    carpentryM,
    grillM,
    tileM,
    paintM,
    rmcM,
    masonL,
    electricalL,
    plumbingL,
    carpentryL,
    tileL,
    paintL,
    miscL,
    planApproval,
    otherMiscMaterials,
    additionalWorks,
    miscExp,
  ];

  static String getLabel(String categoryId) {
    const labels = {
      paymentReceived: 'Payment Received',
      cementM: 'Cement',
      sandM: 'Sand',
      aggregateM: 'Aggregate / Jelly',
      bricksM: 'Bricks',
      steelM: 'Steel / TMT',
      electricalM: 'Electrical (Material)',
      plumbingM: 'Plumbing (Material)',
      carpentryM: 'Carpentry / Wood',
      grillM: 'Grill / MS Work',
      tileM: 'Tiles',
      paintM: 'Paint (Material)',
      rmcM: 'RMC (Ready Mix)',
      masonL: 'Mason / Labour',
      electricalL: 'Electrician (Labour)',
      plumbingL: 'Plumber (Labour)',
      carpentryL: 'Carpenter (Labour)',
      tileL: 'Tile Fixer (Labour)',
      paintL: 'Painter (Labour)',
      miscL: 'Misc Labour',
      planApproval: 'Plan Approval / Permit',
      otherMiscMaterials: 'Other Materials',
      additionalWorks: 'Additional Works',
      miscExp: 'Miscellaneous',
    };
    return labels[categoryId] ?? categoryId;
  }
}

enum PaymentMode { cash, cheque, online }

class ConstructionEntry {
  final String id;
  final String projectId;
  final String? contactId; // Linked person for Khatabook style ledger
  final DateTime date;
  final String description; // Translates to DESC

  final TransactionType transactionType; // expense or credit
  final String categoryId; // From EntryCategory

  // Tabular calculation fields
  final double quantity; // Defaults to 1 if not applicable
  final double rate; // Actual cost per unit

  // Payment Tracking
  final PaymentMode paymentMode;
  final String?
  referenceData; // Cheque Details, Bill No., Contractor Name, Source

  final String? attachmentUrl;
  final String? payableId; // Link to Accounts Payable if needed

  // Receipt specific fields
  final String? receiptNumber;
  final String? receiverName;
  final String? amountInWords;
  final DateTime? paymentDate;
  final String? bankName;
  final String? branchName;

  ConstructionEntry({
    String? id,
    required this.projectId,
    this.contactId,
    required this.date,
    required this.description,
    required this.transactionType,
    required this.categoryId,
    this.quantity = 1.0,
    required this.rate,
    this.paymentMode = PaymentMode.cash,
    this.referenceData,
    this.attachmentUrl,
    this.payableId,
    this.receiptNumber,
    this.receiverName,
    this.amountInWords,
    this.paymentDate,
    this.bankName,
    this.branchName,
  }) : id = id ?? uuid.v4();

  double get amount => quantity * rate;

  factory ConstructionEntry.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    // Legacy support logic
    // If it has 'spreadsheetCategory', it was the intermediate Expense model
    // If it has 'category' mapping to enum strings, it was the original Expense model
    // If it has 'amount' but no 'quantity'/'rate' it's either an old Expense or old Revenue.

    String categoryId = EntryCategory.miscExp;
    TransactionType type = TransactionType.expense;
    double parsedQuantity = 1.0;
    double parsedRate = 0.0;
    PaymentMode pMode = PaymentMode.cash;
    String? refData;

    // Determine type & category
    if (json.containsKey('amount') &&
        !json.containsKey('category') &&
        !json.containsKey('spreadsheetCategory') &&
        !json.containsKey('transactionType')) {
      // Highly likely a legacy Revenue object
      type = TransactionType.credit;
      categoryId = EntryCategory.paymentReceived;
      parsedRate = (json['amount'] as num?)?.toDouble() ?? 0.0;
    } else {
      type = TransactionType.values.firstWhere(
        (e) => e.name == json['transactionType'],
        orElse: () => TransactionType.expense,
      );

      if (json.containsKey('categoryId')) {
        categoryId = json['categoryId'] as String;
      } else if (json.containsKey('spreadsheetCategory')) {
        categoryId = _mapLegacySpreadsheetCategory(
          json['spreadsheetCategory'] as String,
        );
      } else if (json.containsKey('category')) {
        categoryId = _mapLegacyEnumCategory(json['category'] as String?);
      }
    }

    // Determine quantity/rate
    if (json.containsKey('quantity')) {
      parsedQuantity = (json['quantity'] as num?)?.toDouble() ?? 1.0;
    }
    if (json.containsKey('rate')) {
      parsedRate =
          (json['rate'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0.0;
    } else if (json.containsKey('amount')) {
      parsedRate = (json['amount'] as num?)?.toDouble() ?? 0.0;
    }

    // Determine payment mode
    if (json.containsKey('paymentMode')) {
      pMode = PaymentMode.values.firstWhere(
        (e) => e.name == json['paymentMode'],
        orElse: () => PaymentMode.cash,
      );
    } else if (json.containsKey('paymentMethod')) {
      // Legacy mapping
      final oldString = json['paymentMethod'] as String?;
      if (oldString == 'cheque') pMode = PaymentMode.cheque;
      if (oldString == 'online') pMode = PaymentMode.online;
    }

    // Reference Data
    if (json.containsKey('referenceData')) {
      refData = json['referenceData'] as String?;
    } else if (json.containsKey('chequeDetails') &&
        json['chequeDetails'] != null) {
      refData = json['chequeDetails'] as String?;
    } else if (json.containsKey('vendorName') && json['vendorName'] != null) {
      refData = json['vendorName'] as String?;
    } else if (json.containsKey('workerName') && json['workerName'] != null) {
      refData = json['workerName'] as String?;
    }

    return ConstructionEntry(
      id: documentId,
      projectId: json['projectId'] as String? ?? '',
      contactId: json['contactId'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      description: json['description'] as String? ?? 'No Description',
      transactionType: type,
      categoryId: categoryId,
      quantity: parsedQuantity,
      rate: parsedRate,
      paymentMode: pMode,
      referenceData: refData,
      attachmentUrl: json['attachmentUrl'] as String?,
      payableId: json['payableId'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
      receiverName: json['receiverName'] as String?,
      amountInWords: json['amountInWords'] as String?,
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'] as String)
          : null,
      bankName: json['bankName'] as String?,
      branchName: json['branchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'contactId': contactId,
      'date': date.toIso8601String(),
      'description': description,
      'transactionType': transactionType.name,
      'categoryId': categoryId,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'paymentMode': paymentMode.name,
      'referenceData': referenceData,
      'attachmentUrl': attachmentUrl,
      'payableId': payableId,
      'receiptNumber': receiptNumber,
      'receiverName': receiverName,
      'amountInWords': amountInWords,
      'paymentDate': paymentDate?.toIso8601String(),
      'bankName': bankName,
      'branchName': branchName,
    };
  }

  static String _mapLegacySpreadsheetCategory(String oldCat) {
    switch (oldCat) {
      case 'bricks-M':
        return EntryCategory.bricksM;
      case 'steel-M':
        return EntryCategory.steelM;
      case 'Elec-M':
        return EntryCategory.electricalM;
      case 'Plumb-M':
        return EntryCategory.plumbingM;
      case 'Carpent-M':
        return EntryCategory.carpentryM;
      case 'Grill-M':
        return EntryCategory.grillM;
      case 'Tile-M':
        return EntryCategory.tileM;
      case 'Paint-M':
        return EntryCategory.paintM;
      case 'misc-M':
        return EntryCategory.otherMiscMaterials;
      case 'Approval':
        return EntryCategory.planApproval;
      case 'elect-L':
        return EntryCategory.electricalL;
      case 'mason-L':
        return EntryCategory.masonL;
      case 'plumb-L':
        return EntryCategory.plumbingL;
      case 'carpent-L':
        return EntryCategory.carpentryL;
      case 'tile-L':
        return EntryCategory.tileL;
      case 'paint-L':
        return EntryCategory.paintL;
      case 'misc-L':
        return EntryCategory.miscL;
      case 'borewell':
        return EntryCategory.otherMiscMaterials;
      case 'addit works':
        return EntryCategory.additionalWorks;
      case 'RMC':
        return EntryCategory.rmcM;
      default:
        return EntryCategory.miscExp;
    }
  }

  static String _mapLegacyEnumCategory(String? oldEnumString) {
    if (oldEnumString == null) return EntryCategory.miscExp;
    if (oldEnumString.contains('contractor')) return EntryCategory.masonL;
    if (oldEnumString.contains('material'))
      return EntryCategory.otherMiscMaterials;
    return EntryCategory.miscExp;
  }
}
