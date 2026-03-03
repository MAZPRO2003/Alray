import 'package:uuid/uuid.dart';

const uuid = Uuid();

// Replace the generic enum with strict string constants to match Excel tabs.
class ExpenseCategories {
  // Material categories
  static const String bricksM = 'bricks-M';
  static const String steelM = 'steel-M';
  static const String elecM = 'Elec-M';
  static const String plumbM = 'Plumb-M';
  static const String carpentryM = 'Carpent-M';
  static const String grillM = 'Grill-M';
  static const String tileM = 'Tile-M';
  static const String paintM = 'Paint-M';
  static const String miscM = 'misc-M';

  // Labor categories
  static const String approval = 'Approval';
  static const String electL = 'elect-L';
  static const String masonL = 'mason-L';
  static const String plumbL = 'plumb-L';
  static const String carpentL = 'carpent-L';
  static const String tileL = 'tile-L';
  static const String paintL = 'paint-L';
  static const String miscL = 'misc-L';

  // Other specific sheets
  static const String borewell = 'borewell';
  static const String additWorks = 'addit works';
  static const String miscExp = 'MISC EXP';
  static const String rmc = 'RMC';

  static const List<String> allCategories = [
    bricksM,
    steelM,
    elecM,
    plumbM,
    carpentryM,
    grillM,
    tileM,
    paintM,
    miscM,
    approval,
    electL,
    masonL,
    plumbL,
    carpentL,
    tileL,
    paintL,
    miscL,
    borewell,
    additWorks,
    miscExp,
    rmc,
  ];
}

enum PaymentMethod { cash, cheque, online }

class Expense {
  final String id;
  final String projectId;
  final String description; // Translates to DESC in Excel

  // Tabular calculation fields
  final double quantity; // Defaults to 1 if not applicable
  final double rate; // Actual cost per unit
  final double amount; // quantity * rate

  final DateTime date;
  final String spreadsheetCategory; // Which Excel tab this goes into

  // Payment Tracking
  final PaymentMethod paymentMethod;
  final String? chequeDetails; // Combines Cheque No, Bank, and specific details

  final String? attachmentUrl;
  final String? payableId; // Link to Accounts Payable if needed

  Expense({
    String? id,
    required this.projectId,
    required this.description,
    this.quantity = 1.0,
    required this.rate,
    required this.date,
    required this.spreadsheetCategory,
    this.paymentMethod = PaymentMethod.cash,
    this.chequeDetails,
    this.attachmentUrl,
    this.payableId,
  }) : id = id ?? uuid.v4(),
       amount = quantity * rate;

  factory Expense.fromJson(Map<String, dynamic> json, String documentId) {
    // Handle legacy mapping gracefully if old data exists
    String mappedCategory =
        json['spreadsheetCategory'] as String? ?? ExpenseCategories.miscExp;
    if (!ExpenseCategories.allCategories.contains(mappedCategory)) {
      // Fallback for legacy data
      if (json['category'] == 'contractor')
        mappedCategory = ExpenseCategories.miscL;
      else if (json['category'] == 'material')
        mappedCategory = ExpenseCategories.miscM;
      else
        mappedCategory = ExpenseCategories.miscExp;
    }

    final double qty = (json['quantity'] as num?)?.toDouble() ?? 1.0;
    final double rt =
        (json['rate'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        0.0;

    return Expense(
      id: documentId,
      projectId: json['projectId'] as String? ?? '',
      description: json['description'] as String? ?? 'No Description',
      quantity: qty,
      rate: rt,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      spreadsheetCategory: mappedCategory,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (json['paymentMethod'] as String?),
        orElse: () => PaymentMethod.cash,
      ),
      chequeDetails: json['chequeDetails'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      payableId: json['payableId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'date': date.toIso8601String(),
      'spreadsheetCategory': spreadsheetCategory,
      'paymentMethod': paymentMethod.name,
      if (chequeDetails != null) 'chequeDetails': chequeDetails,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (payableId != null) 'payableId': payableId,
    };
  }
}
