import 'crm_insert_order_models.dart';

class CrmInsertOrderService {
  const CrmInsertOrderService();

  String? validateSelection({
    required CrmInsertOrderCustomer? customer,
    required CrmInsertOrderContact? contact,
    required String? commercialUserId,
    required DateTime? requestedAt,
    required DateTime? expectedDeliveryDate,
  }) {
    if (customer == null) {
      return 'Seleciona um cliente.';
    }

    if (contact == null) {
      return 'Seleciona um contacto do pedido.';
    }

    if (commercialUserId == null || commercialUserId.trim().isEmpty) {
      return 'Seleciona um comercial valido.';
    }

    if (requestedAt == null) {
      return 'Seleciona a data do pedido.';
    }

    if (expectedDeliveryDate == null) {
      return 'Seleciona a data prevista de entrega.';
    }

    return null;
  }

  CrmCreateOrderInput buildCreateOrderInput({
    required CrmInsertOrderCustomer customer,
    required CrmInsertOrderContact contact,
    required String commercialUserId,
    required List<CrmInsertOrderCommercial> commercials,
    required DateTime requestedAt,
    required DateTime? expectedDeliveryDate,
    int? commercialPhaseId,
  }) {
    CrmInsertOrderCommercial? selectedCommercial;
    for (final commercial in commercials) {
      if (commercial.userId == commercialUserId) {
        selectedCommercial = commercial;
        break;
      }
    }

    final initials = selectedCommercial?.initials.trim() ?? '';
    if (initials.isEmpty) {
      throw StateError('Seleciona um comercial valido.');
    }

    return CrmCreateOrderInput(
      customerId: customer.id,
      commercialUserId: commercialUserId,
      commercialSigla: initials,
      contactId: contact.id,
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
      commercialPhaseId: commercialPhaseId,
    );
  }
}
