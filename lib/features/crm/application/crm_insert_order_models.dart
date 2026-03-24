class CrmInsertOrderCustomer {
  const CrmInsertOrderCustomer({
    required this.id,
    required this.name,
    this.vatNumber,
  });

  final String id;
  final String name;
  final String? vatNumber;
}

class CrmInsertOrderContact {
  const CrmInsertOrderContact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final bool isPrimary;
}

class CrmInsertOrderCommercial {
  const CrmInsertOrderCommercial({
    required this.userId,
    required this.fullName,
    required this.initials,
  });

  final String userId;
  final String fullName;
  final String initials;
}

class CrmCreateOrderInput {
  const CrmCreateOrderInput({
    required this.customerId,
    required this.commercialUserId,
    required this.commercialSigla,
    required this.contactId,
    required this.requestedAt,
    required this.expectedDeliveryDate,
    this.commercialPhaseId,
  });

  final String customerId;
  final String commercialUserId;
  final String commercialSigla;
  final String contactId;
  final DateTime requestedAt;
  final DateTime? expectedDeliveryDate;
  final int? commercialPhaseId;
}
