class CrmOrderInProgressItem {
  const CrmOrderInProgressItem({
    required this.orderId,
    required this.orderRef,
    required this.versionLabel,
    required this.orderRefForProposal,
    required this.customerName,
    required this.requestedAt,
    required this.sentToBudgetingAt,
    required this.expectedDeliveryDate,
    required this.commercialPhaseName,
    required this.budgetingPhaseName,
    required this.budgeterName,
    required this.commercialPhaseId,
    required this.proposalId,
    required this.hasProposal,
    required this.canSendProposal,
    required this.sendProposalBlockReason,
  });

  final Object orderId;
  final String orderRef;
  final String versionLabel;
  final String orderRefForProposal;
  final String customerName;
  final DateTime? requestedAt;
  final DateTime? sentToBudgetingAt;
  final DateTime? expectedDeliveryDate;
  final String commercialPhaseName;
  final String budgetingPhaseName;
  final String budgeterName;
  final int? commercialPhaseId;
  final String? proposalId;
  final bool hasProposal;
  final bool canSendProposal;
  final String? sendProposalBlockReason;

  bool get hasExpectedDeliveryDate => expectedDeliveryDate != null;

  bool get isExpectedDeliveryOverdue {
    final value = expectedDeliveryDate;
    if (value == null) {
      return false;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedValue = DateTime(value.year, value.month, value.day);
    return normalizedValue.isBefore(normalizedToday);
  }

  bool get isExpectedDeliverySoon {
    final value = expectedDeliveryDate;
    if (value == null) {
      return false;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedValue = DateTime(value.year, value.month, value.day);
    final difference = normalizedValue.difference(normalizedToday).inDays;
    return difference >= 0 && difference <= 2;
  }
}

class CrmSentProposalItem {
  const CrmSentProposalItem({
    required this.orderId,
    required this.reference,
    required this.customerName,
    required this.sentAt,
    required this.feedbackAt,
    required this.validUntil,
    required this.rawOrder,
    required this.rawLatestVersion,
    required this.rawLatestProposal,
  });

  final String orderId;
  final String reference;
  final String customerName;
  final dynamic sentAt;
  final dynamic feedbackAt;
  final dynamic validUntil;
  final Map<String, dynamic> rawOrder;
  final Map<String, dynamic>? rawLatestVersion;
  final Map<String, dynamic>? rawLatestProposal;
}
