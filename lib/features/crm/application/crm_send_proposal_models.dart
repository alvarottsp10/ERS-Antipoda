class CrmSendProposalDraft {
  const CrmSendProposalDraft({
    required this.proposalId,
    required this.orderRef,
    required this.sentAt,
    required this.feedbackAt,
    required this.validUntil,
    required this.note,
  });

  final String proposalId;
  final String orderRef;
  final DateTime? sentAt;
  final DateTime? feedbackAt;
  final DateTime? validUntil;
  final String note;

  CrmSendProposalDraft copyWith({
    String? proposalId,
    String? orderRef,
    DateTime? sentAt,
    bool clearSentAt = false,
    DateTime? feedbackAt,
    bool clearFeedbackAt = false,
    DateTime? validUntil,
    bool clearValidUntil = false,
    String? note,
  }) {
    return CrmSendProposalDraft(
      proposalId: proposalId ?? this.proposalId,
      orderRef: orderRef ?? this.orderRef,
      sentAt: clearSentAt ? null : (sentAt ?? this.sentAt),
      feedbackAt: clearFeedbackAt ? null : (feedbackAt ?? this.feedbackAt),
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
      note: note ?? this.note,
    );
  }
}

class CrmSendProposalResult {
  const CrmSendProposalResult({
    required this.proposalId,
    required this.sentAt,
    required this.feedbackAt,
    required this.validUntil,
    required this.note,
  });

  final String proposalId;
  final DateTime sentAt;
  final DateTime feedbackAt;
  final DateTime validUntil;
  final String note;

  Map<String, dynamic> toDialogResult() {
    return {
      'proposal_id': proposalId,
      'sent_at': sentAt,
      'feedback_at': feedbackAt,
      'valid_until': validUntil,
      'note': note,
    };
  }
}
