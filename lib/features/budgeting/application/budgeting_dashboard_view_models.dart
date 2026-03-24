class BudgetingAssignmentItem {
  const BudgetingAssignmentItem({
    required this.id,
    required this.assigneeUserId,
    required this.assigneeName,
    required this.assignmentRole,
    required this.roleLabel,
    required this.typologyName,
    required this.productTypeName,
    required this.workedHours,
    required this.isSpecial,
  });

  final String id;
  final String? assigneeUserId;
  final String assigneeName;
  final String assignmentRole;
  final String roleLabel;
  final String typologyName;
  final String productTypeName;
  final double workedHours;
  final bool isSpecial;
}

class BudgetingNewOrderItem {
  const BudgetingNewOrderItem({
    required this.orderId,
    required this.orderRef,
    required this.versionLabel,
    required this.displayLabel,
    required this.customerName,
    required this.createdAt,
    required this.createdAtLabel,
    required this.entryDate,
    required this.entryDateLabel,
    required this.expectedDeliveryDate,
    required this.expectedDeliveryDateLabel,
  });

  final String orderId;
  final String orderRef;
  final String versionLabel;
  final String displayLabel;
  final String customerName;
  final DateTime? createdAt;
  final String createdAtLabel;
  final DateTime? entryDate;
  final String entryDateLabel;
  final DateTime? expectedDeliveryDate;
  final String expectedDeliveryDateLabel;
}

class BudgetingMyBudgetItem {
  const BudgetingMyBudgetItem({
    required this.orderId,
    required this.latestVersionId,
    required this.orderRef,
    required this.versionLabel,
    required this.displayLabel,
    required this.customerName,
    required this.budgetingPhaseId,
    required this.budgetingPhaseName,
    required this.primaryTypologyName,
    required this.primaryProductTypeName,
    required this.isSpecial,
    required this.totalWorkedHours,
    required this.activeProposalId,
    required this.activeProposalSellTotal,
    required this.activeProposalCostTotal,
    this.activeProposalCostMaterialTotal,
    this.activeProposalCostLaborTotal,
    this.activeProposalCostProjectTotal,
    required this.activeProposalMarginPct,
    required this.activeProposalSentAt,
    required this.activeProposalFeedbackAt,
    required this.activeProposalValidUntil,
    this.activeProposalItems = const [],
    required this.assignments,
  });

  final String orderId;
  final String latestVersionId;
  final String orderRef;
  final String versionLabel;
  final String displayLabel;
  final String customerName;
  final int? budgetingPhaseId;
  final String budgetingPhaseName;
  final String primaryTypologyName;
  final String primaryProductTypeName;
  final bool isSpecial;
  final double totalWorkedHours;
  final String? activeProposalId;
  final double? activeProposalSellTotal;
  final double? activeProposalCostTotal;
  final double? activeProposalCostMaterialTotal;
  final double? activeProposalCostLaborTotal;
  final double? activeProposalCostProjectTotal;
  final double? activeProposalMarginPct;
  final DateTime? activeProposalSentAt;
  final DateTime? activeProposalFeedbackAt;
  final DateTime? activeProposalValidUntil;
  final List<Map<String, dynamic>> activeProposalItems;
  final List<BudgetingAssignmentItem> assignments;
}

class BudgetingActiveBudgetItem {
  const BudgetingActiveBudgetItem({
    required this.orderId,
    required this.latestVersionId,
    required this.orderRef,
    required this.versionLabel,
    required this.displayLabel,
    required this.customerName,
    required this.budgetingPhaseId,
    required this.budgetingPhaseName,
    required this.primaryTypologyName,
    required this.primaryProductTypeName,
    required this.isSpecial,
    required this.totalWorkedHours,
    required this.activeProposalId,
    required this.activeProposalSellTotal,
    required this.activeProposalCostTotal,
    this.activeProposalCostMaterialTotal,
    this.activeProposalCostLaborTotal,
    this.activeProposalCostProjectTotal,
    required this.activeProposalMarginPct,
    required this.activeProposalSentAt,
    required this.activeProposalFeedbackAt,
    required this.activeProposalValidUntil,
    this.activeProposalItems = const [],
    required this.assignments,
  });

  final String orderId;
  final String latestVersionId;
  final String orderRef;
  final String versionLabel;
  final String displayLabel;
  final String customerName;
  final int? budgetingPhaseId;
  final String budgetingPhaseName;
  final String primaryTypologyName;
  final String primaryProductTypeName;
  final bool isSpecial;
  final double totalWorkedHours;
  final String? activeProposalId;
  final double? activeProposalSellTotal;
  final double? activeProposalCostTotal;
  final double? activeProposalCostMaterialTotal;
  final double? activeProposalCostLaborTotal;
  final double? activeProposalCostProjectTotal;
  final double? activeProposalMarginPct;
  final DateTime? activeProposalSentAt;
  final DateTime? activeProposalFeedbackAt;
  final DateTime? activeProposalValidUntil;
  final List<Map<String, dynamic>> activeProposalItems;
  final List<BudgetingAssignmentItem> assignments;
}
