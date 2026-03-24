import 'crm_send_proposal_models.dart';

class CrmSendProposalService {
  const CrmSendProposalService();

  CrmSendProposalDraft createInitialDraft({
    required String proposalId,
    required String orderRef,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    return CrmSendProposalDraft(
      proposalId: proposalId,
      orderRef: orderRef,
      sentAt: today,
      feedbackAt: null,
      validUntil: today.add(const Duration(days: 30)),
      note: '',
    );
  }

  String? validateSentAt(DateTime? sentAt) {
    if (sentAt == null) {
      return 'Obrigatório';
    }
    return null;
  }

  String? validateFeedbackAt(DateTime? feedbackAt) {
    if (feedbackAt == null) {
      return 'Obrigatório';
    }
    return null;
  }

  String? validateValidUntil(DateTime? validUntil) {
    if (validUntil == null) {
      return 'Obrigatório';
    }
    return null;
  }

  CrmSendProposalResult buildResult(CrmSendProposalDraft draft) {
    final sentAt = draft.sentAt;
    final feedbackAt = draft.feedbackAt;
    final validUntil = draft.validUntil;

    if (sentAt == null || feedbackAt == null || validUntil == null) {
      throw StateError('Draft incompleto para envio de proposta.');
    }

    return CrmSendProposalResult(
      proposalId: draft.proposalId,
      sentAt: sentAt,
      feedbackAt: feedbackAt,
      validUntil: validUntil,
      note: draft.note.trim(),
    );
  }
}
