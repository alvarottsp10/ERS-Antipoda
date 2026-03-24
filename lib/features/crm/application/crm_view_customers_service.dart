import 'crm_view_customers_models.dart';

class CrmViewCustomersService {
  const CrmViewCustomersService();

  List<CrmViewCustomerListItem> filterCustomers({
    required List<CrmViewCustomerListItem> customers,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      return customer.name.toLowerCase().contains(normalizedQuery) ||
          customer.vatNumber.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }

  String? validateAddContactInput(CrmAddCustomerContactInput input) {
    if (input.customerId.trim().isEmpty) {
      return 'Cliente invalido.';
    }

    if (input.name.trim().isEmpty) {
      return 'Nome do contacto obrigatorio.';
    }

    if (input.email.trim().isEmpty) {
      return 'Email do contacto obrigatorio.';
    }

    if (input.role.trim().isEmpty) {
      return 'Role do contacto obrigatorio.';
    }

    return null;
  }

  String? validateAddSiteInput(CrmAddCustomerSiteInput input) {
    if (input.customerId.trim().isEmpty) {
      return 'Cliente invalido.';
    }

    if (input.name.trim().isEmpty) {
      return 'Nome do local obrigatorio.';
    }

    if (input.addressLine1.trim().isEmpty) {
      return 'Morada do local obrigatoria.';
    }

    if (input.postalCode.trim().isEmpty) {
      return 'Codigo postal do local obrigatorio.';
    }

    if (input.city.trim().isEmpty) {
      return 'Cidade do local obrigatoria.';
    }

    if (input.countryId <= 0) {
      return 'Pais do local obrigatorio.';
    }

    return null;
  }

  String buildCustomerTitle({
    CrmViewCustomerDetail? detail,
    CrmViewCustomerListItem? fallback,
  }) {
    final name = detail?.name ?? fallback?.name ?? '';
    return name.trim().isEmpty ? 'Cliente' : name;
  }
}
