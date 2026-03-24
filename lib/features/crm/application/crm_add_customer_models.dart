class CrmAddCustomerCountry {
  const CrmAddCustomerCountry({
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
}

class CrmAddCustomerContactDraft {
  const CrmAddCustomerContactDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isPrimary,
  });

  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isPrimary;
}

class CrmAddCustomerSiteDraft {
  const CrmAddCustomerSiteDraft({
    required this.name,
    required this.code,
    required this.addressLine1,
    required this.addressLine2,
    required this.postalCode,
    required this.city,
    required this.countryId,
  });

  final String name;
  final String code;
  final String addressLine1;
  final String addressLine2;
  final String postalCode;
  final String city;
  final int countryId;
}

class CrmCreateCustomerInput {
  const CrmCreateCustomerInput({
    required this.customerName,
    required this.customerCountryId,
    required this.vatNumber,
    required this.email,
    required this.phone,
    required this.commercialUserId,
    required this.contacts,
    required this.sites,
  });

  final String customerName;
  final int customerCountryId;
  final String vatNumber;
  final String email;
  final String phone;
  final String commercialUserId;
  final List<CrmAddCustomerContactDraft> contacts;
  final List<CrmAddCustomerSiteDraft> sites;
}
