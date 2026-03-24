class CrmViewCustomerListItem {
  const CrmViewCustomerListItem({
    required this.id,
    required this.name,
    required this.vatNumber,
    required this.email,
    required this.phone,
    required this.countryName,
    required this.contactCount,
  });

  final String id;
  final String name;
  final String vatNumber;
  final String email;
  final String phone;
  final String countryName;
  final int contactCount;

  factory CrmViewCustomerListItem.fromMap(Map<String, dynamic> map) {
    return CrmViewCustomerListItem(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      vatNumber: (map['vat_number'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      contactCount: ((map['contact_count'] as num?) ?? 0).toInt(),
    );
  }
}

class CrmViewCustomerCountry {
  const CrmViewCustomerCountry({
    required this.id,
    required this.name,
    this.iso2,
    this.vatPrefix,
    this.phonePrefix,
  });

  final int id;
  final String name;
  final String? iso2;
  final String? vatPrefix;
  final String? phonePrefix;

  factory CrmViewCustomerCountry.fromMap(Map<String, dynamic> map) {
    return CrmViewCustomerCountry(
      id: ((map['id'] as num?) ?? 0).toInt(),
      name: (map['name'] ?? '').toString(),
      iso2: map['iso2'] as String?,
      vatPrefix: map['vat_prefix'] as String?,
      phonePrefix: map['phone_prefix'] as String?,
    );
  }
}

class CrmViewCustomerDetail {
  const CrmViewCustomerDetail({
    required this.id,
    required this.name,
    required this.vatNumber,
    required this.countryId,
    required this.countryName,
  });

  final String id;
  final String name;
  final String vatNumber;
  final int? countryId;
  final String countryName;

  factory CrmViewCustomerDetail.fromMap(Map<String, dynamic> map) {
    final countryMap = map['countries'];

    return CrmViewCustomerDetail(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      vatNumber: (map['vat_number'] ?? '').toString(),
      countryId: (map['country_id'] as num?)?.toInt(),
      countryName: countryMap is Map
          ? (countryMap['name'] ?? '').toString()
          : '',
    );
  }
}

class CrmViewCustomerContact {
  const CrmViewCustomerContact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isPrimary;

  factory CrmViewCustomerContact.fromMap(Map<String, dynamic> map) {
    return CrmViewCustomerContact(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      isPrimary: map['is_primary'] == true,
    );
  }
}

class CrmViewCustomerSite {
  const CrmViewCustomerSite({
    required this.id,
    required this.name,
    required this.code,
    required this.addressLine1,
    required this.addressLine2,
    required this.postalCode,
    required this.city,
    required this.countryId,
    required this.countryName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final String addressLine1;
  final String addressLine2;
  final String postalCode;
  final String city;
  final int? countryId;
  final String countryName;
  final bool isActive;

  factory CrmViewCustomerSite.fromMap(Map<String, dynamic> map) {
    final countryMap = map['countries'];

    return CrmViewCustomerSite(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      addressLine1: (map['address_line_1'] ?? '').toString(),
      addressLine2: (map['address_line_2'] ?? '').toString(),
      postalCode: (map['postal_code'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      countryId: (map['country_id'] as num?)?.toInt(),
      countryName: countryMap is Map
          ? (countryMap['name'] ?? '').toString()
          : '',
      isActive: map['is_active'] == true,
    );
  }
}

class CrmAddCustomerContactInput {
  const CrmAddCustomerContactInput({
    required this.customerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isPrimary,
  });

  final String customerId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isPrimary;
}

class CrmAddCustomerSiteInput {
  const CrmAddCustomerSiteInput({
    required this.customerId,
    required this.name,
    required this.code,
    required this.addressLine1,
    required this.addressLine2,
    required this.postalCode,
    required this.city,
    required this.countryId,
  });

  final String customerId;
  final String name;
  final String code;
  final String addressLine1;
  final String addressLine2;
  final String postalCode;
  final String city;
  final int countryId;
}
