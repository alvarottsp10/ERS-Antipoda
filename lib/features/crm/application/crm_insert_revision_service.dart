import 'crm_insert_revision_models.dart';

class CrmInsertRevisionService {
  const CrmInsertRevisionService();

  static const _eligibleCommercialPhaseCodes = {
    'enviado',
    'concluido',
  };

  List<CrmInsertRevisionOrder> filterEligibleOrders(
    List<CrmInsertRevisionOrder> orders,
  ) {
    return orders
        .map(_applyEligibility)
        .where((order) => order.isEligibleForRevision)
        .toList(growable: false);
  }

  CrmInsertRevisionOrder _applyEligibility(CrmInsertRevisionOrder order) {
    final phaseCode = order.commercialPhaseCode.trim().toLowerCase();

    if (_eligibleCommercialPhaseCodes.contains(phaseCode)) {
      return order.copyWith(
        isEligibleForRevision: true,
        ineligibleReason: null,
      );
    }

    return order.copyWith(
      isEligibleForRevision: false,
      ineligibleReason: 'Pedido ja ativo em ${order.commercialPhaseName}.',
    );
  }

  String? validateSelection({
    required CrmInsertRevisionOrder? order,
    required DateTime? requestedAt,
    required DateTime? expectedDeliveryDate,
  }) {
    if (order == null) {
      return 'Seleciona um pedido.';
    }

    if (order.id.trim().isEmpty) {
      return 'Pedido invalido.';
    }

    if (!order.isEligibleForRevision) {
      return order.ineligibleReason ?? 'Pedido nao elegivel para revisao.';
    }

    if (requestedAt == null) {
      return 'Seleciona a data do pedido da revisao.';
    }

    if (expectedDeliveryDate == null) {
      return 'Seleciona a data prevista de entrega.';
    }

    return null;
  }

  CrmInsertRevisionInput buildInput({
    required CrmInsertRevisionOrder order,
    required CrmInsertRevisionContact? selectedContact,
    required DateTime requestedAt,
    required DateTime? expectedDeliveryDate,
  }) {
    return CrmInsertRevisionInput(
      orderId: order.id,
      contactId: selectedContact?.id,
      requestedAt: DateTime(
        requestedAt.year,
        requestedAt.month,
        requestedAt.day,
      ),
      expectedDeliveryDate: expectedDeliveryDate == null
          ? null
          : DateTime(
              expectedDeliveryDate.year,
              expectedDeliveryDate.month,
              expectedDeliveryDate.day,
            ),
    );
  }
}
