class CrmInsertRevisionOrder {
  const CrmInsertRevisionOrder({
    required this.id,
    required this.orderRef,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.commercialPhaseId,
    required this.commercialPhaseCode,
    required this.commercialPhaseName,
    required this.contactId,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.isEligibleForRevision,
    required this.ineligibleReason,
  });

  final String id;
  final String orderRef;
  final String customerId;
  final String customerName;
  final String status;
  final int? commercialPhaseId;
  final String commercialPhaseCode;
  final String commercialPhaseName;
  final String? contactId;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final bool isEligibleForRevision;
  final String? ineligibleReason;

  factory CrmInsertRevisionOrder.fromMap(Map<String, dynamic> map) {
    final customerMap = map['customers'];
    final commercialPhaseMap = map['commercial_phase'];
    final contactMap = map['order_contact'];

    return CrmInsertRevisionOrder(
      id: (map['id'] ?? '').toString(),
      orderRef: (map['order_ref'] ?? '').toString(),
      customerId: (map['customer_id'] ?? '').toString(),
      customerName:
          customerMap is Map ? (customerMap['name'] ?? '').toString() : '',
      status: (map['status'] ?? '').toString(),
      commercialPhaseId: (map['commercial_phase_id'] as num?)?.toInt(),
      commercialPhaseCode: commercialPhaseMap is Map
          ? (commercialPhaseMap['code'] ?? '').toString()
          : '',
      commercialPhaseName: commercialPhaseMap is Map
          ? (commercialPhaseMap['name'] ?? '').toString()
          : '',
      contactId: contactMap is Map ? contactMap['id']?.toString() : null,
      contactName:
          contactMap is Map ? (contactMap['name'] ?? '').toString() : '',
      contactEmail:
          contactMap is Map ? (contactMap['email'] ?? '').toString() : '',
      contactPhone:
          contactMap is Map ? (contactMap['phone'] ?? '').toString() : '',
      isEligibleForRevision: true,
      ineligibleReason: null,
    );
  }

  CrmInsertRevisionOrder copyWith({
    bool? isEligibleForRevision,
    String? ineligibleReason,
  }) {
    return CrmInsertRevisionOrder(
      id: id,
      orderRef: orderRef,
      customerId: customerId,
      customerName: customerName,
      status: status,
      commercialPhaseId: commercialPhaseId,
      commercialPhaseCode: commercialPhaseCode,
      commercialPhaseName: commercialPhaseName,
      contactId: contactId,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      isEligibleForRevision:
          isEligibleForRevision ?? this.isEligibleForRevision,
      ineligibleReason: ineligibleReason ?? this.ineligibleReason,
    );
  }

  String get display {
    if (customerName.trim().isEmpty) {
      return orderRef;
    }
    return '$orderRef - $customerName';
  }

  String get currentContactDisplay {
    final parts = <String>[
      if (contactName.trim().isNotEmpty) contactName.trim(),
      if (contactEmail.trim().isNotEmpty) contactEmail.trim(),
      if (contactPhone.trim().isNotEmpty) contactPhone.trim(),
    ];

    if (parts.isEmpty) {
      return 'Sem contacto associado';
    }

    return parts.join(' - ');
  }
}

class CrmInsertRevisionContact {
  const CrmInsertRevisionContact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isPrimary;

  factory CrmInsertRevisionContact.fromMap(Map<String, dynamic> map) {
    return CrmInsertRevisionContact(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      isPrimary: map['is_primary'] == true,
    );
  }

  String get display {
    final parts = <String>[
      if (name.trim().isNotEmpty) name.trim(),
      if (email.trim().isNotEmpty) email.trim(),
      if (phone.trim().isNotEmpty) phone.trim(),
    ];

    if (parts.isEmpty) {
      return id;
    }

    return parts.join(' - ');
  }
}

class CrmInsertRevisionInput {
  const CrmInsertRevisionInput({
    required this.orderId,
    required this.contactId,
    required this.requestedAt,
    required this.expectedDeliveryDate,
  });

  final String orderId;
  final String? contactId;
  final DateTime requestedAt;
  final DateTime? expectedDeliveryDate;
}
