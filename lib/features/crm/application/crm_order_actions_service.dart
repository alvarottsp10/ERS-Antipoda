import 'package:erp_app/features/crm/application/crm_dashboard_view_models.dart';
import 'package:erp_app/features/crm/domain/crm_models.dart';

class CrmOrderActionsService {
  const CrmOrderActionsService();

  List<WorkflowPhaseOption> editableCommercialPhases(
    List<WorkflowPhaseOption> phases,
  ) {
    return phases
        .where((phase) => phase.code != 'enviado' && phase.code != 'concluido')
        .toList(growable: false);
  }

  String? validateCommercialPhaseSelection(int? commercialPhaseId) {
    if (commercialPhaseId == null) {
      return 'Seleciona um estado comercial.';
    }

    return null;
  }

  String? validateProposalId(CrmOrderInProgressItem item) {
    final proposalId = item.proposalId;
    if (proposalId == null || proposalId.trim().isEmpty) {
      return 'Nao existe proposta valida associada a este pedido.';
    }

    return null;
  }

  String? validateExpectedDeliveryDate(DateTime? expectedDeliveryDate) {
    if (expectedDeliveryDate == null) {
      return 'Seleciona uma data prevista de entrega.';
    }

    return null;
  }

  String? validateOrderCancellation(CrmOrderInProgressItem item) {
    final orderId = item.orderId.toString().trim();
    if (orderId.isEmpty) {
      return 'Pedido invalido para anular.';
    }

    return null;
  }
}
