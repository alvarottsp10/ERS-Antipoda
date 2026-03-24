class BudgetingOption {
  const BudgetingOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class BudgetingWorkflowPhaseOption {
  const BudgetingWorkflowPhaseOption({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
  });

  final int id;
  final String code;
  final String name;
  final int sortOrder;
}

class BudgetingBudgeterOption {
  const BudgetingBudgeterOption({
    required this.userId,
    required this.fullName,
  });

  final String userId;
  final String fullName;
}

class BudgetingAssignmentSummary {
  const BudgetingAssignmentSummary({
    required this.id,
    required this.assigneeUserId,
    required this.assigneeName,
    required this.assignmentRole,
    required this.workedHours,
    required this.budgetTypologyId,
    required this.budgetTypologyName,
    required this.productTypeId,
    required this.productTypeName,
    required this.isSpecial,
  });

  final String id;
  final String? assigneeUserId;
  final String assigneeName;
  final String assignmentRole;
  final double workedHours;
  final int? budgetTypologyId;
  final String budgetTypologyName;
  final int? productTypeId;
  final String productTypeName;
  final bool isSpecial;
}

class BudgetingOrderSummary {
  const BudgetingOrderSummary({
    required this.orderId,
    required this.orderRef,
    required this.latestVersionRef,
    required this.versionLabel,
    required this.customerName,
    required this.createdAt,
    required this.requestedAt,
    required this.sentToBudgetingAt,
    required this.expectedDeliveryDate,
    required this.budgetingPhaseId,
    required this.budgetingPhaseName,
    required this.latestVersionId,
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
    required this.activeAssignments,
  });

  final String orderId;
  final String orderRef;
  final String latestVersionRef;
  final String versionLabel;
  final String customerName;
  final DateTime? createdAt;
  final DateTime? requestedAt;
  final DateTime? sentToBudgetingAt;
  final DateTime? expectedDeliveryDate;
  final int? budgetingPhaseId;
  final String budgetingPhaseName;
  final String latestVersionId;
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
  final List<BudgetingAssignmentSummary> activeAssignments;
}
