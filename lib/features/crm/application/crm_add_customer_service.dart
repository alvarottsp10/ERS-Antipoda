import 'crm_add_customer_models.dart';

class CrmAddCustomerService {
  const CrmAddCustomerService();

  String? validateSelection({
    required CrmAddCustomerCountry? customerCountry,
    required String? commercialUserId,
    required List<CrmAddCustomerContactDraft> contacts,
    required int siteCount,
  }) {
    if (customerCountry == null) {
      return 'Seleciona um pais para o cliente.';
    }

    if (contacts.isEmpty) {
      return 'E obrigatorio pelo menos um contacto.';
    }

    if (commercialUserId == null || commercialUserId.trim().isEmpty) {
      return 'Seleciona um comercial responsavel.';
    }

    if (siteCount == 0) {
      return 'E obrigatorio pelo menos um local.';
    }

    return null;
  }

  String? validateContacts(List<CrmAddCustomerContactDraft> contacts) {
    var primaryCount = 0;

    for (var i = 0; i < contacts.length; i++) {
      final contact = contacts[i];

      if (contact.name.trim().isEmpty) {
        return 'Contacto ${i + 1}: nome e obrigatorio.';
      }

      if (contact.email.trim().isEmpty) {
        return 'Contacto ${i + 1}: email e obrigatorio.';
      }

      if (contact.role.trim().isEmpty) {
        return 'Contacto ${i + 1}: role e obrigatorio.';
      }

      if (contact.isPrimary) {
        primaryCount++;
      }
    }

    if (primaryCount != 1) {
      return 'Deve existir exatamente um contacto primario.';
    }

    return null;
  }

  String? validateSites(List<CrmAddCustomerSiteDraft> sites) {
    for (var i = 0; i < sites.length; i++) {
      final site = sites[i];

      if (site.name.trim().isEmpty) {
        return 'Local ${i + 1}: nome e obrigatorio.';
      }

      if (site.addressLine1.trim().isEmpty) {
        return 'Local ${i + 1}: morada e obrigatoria.';
      }

      if (site.postalCode.trim().isEmpty) {
        return 'Local ${i + 1}: codigo postal e obrigatorio.';
      }

      if (site.city.trim().isEmpty) {
        return 'Local ${i + 1}: cidade e obrigatoria.';
      }
    }

    return null;
  }

  CrmCreateCustomerInput buildCreateCustomerInput({
    required String customerName,
    required CrmAddCustomerCountry customerCountry,
    required String vatNumber,
    required String email,
    required String phone,
    required String commercialUserId,
    required List<CrmAddCustomerContactDraft> contacts,
    required List<CrmAddCustomerSiteDraft> sites,
  }) {
    return CrmCreateCustomerInput(
      customerName: customerName.trim(),
      customerCountryId: customerCountry.id,
      vatNumber: vatNumber.trim(),
      email: email.trim(),
      phone: phone.trim(),
      commercialUserId: commercialUserId.trim(),
      contacts: contacts,
      sites: sites,
    );
  }
}
