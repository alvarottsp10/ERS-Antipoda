import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/crm_add_customer_models.dart';
import '../application/crm_insert_revision_models.dart';
import '../application/crm_view_customers_models.dart';
import '../domain/crm_models.dart';

class CrmRepository {
  CrmRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchOrdersInAnalysis() async {
    final res = await _supabase
        .from('orders')
        .select('order_ref, created_at, customers(name)')
        .eq('status', 'Em análise')
        .order('created_at', ascending: false)
        .limit(50);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<CommercialOption>> fetchCommercialOptions() async {
    final res = await _supabase
        .from('commercials_list_view')
        .select('user_id, full_name, is_active')
        .eq('is_active', true)
        .order('full_name', ascending: true);

    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(CommercialOption.fromMap)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchInsertOrderCustomers({
    String? commercialUserId,
  }) async {
    var query = _supabase
        .from('customers')
        .select('id,name,vat_number,commercial_user_id');

    if (commercialUserId != null && commercialUserId.trim().isNotEmpty) {
      query = query.eq('commercial_user_id', commercialUserId);
    }

    final response = await query.order('name', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchContactsForCustomer(
    String customerId,
  ) async {
    final response = await _supabase
        .from('contacts')
        .select('id,name,email,phone,is_primary')
        .eq('customer_id', customerId)
        .order('is_primary', ascending: false)
        .order('name', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchActiveCommercialsList() async {
    final response = await _supabase
        .from('commercials_list_view')
        .select()
        .eq('is_active', true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<CrmViewCustomerListItem>> fetchCustomersList({
    String? commercialUserId,
  }) async {
    var query = _supabase.from('customer_list_view').select();

    if (commercialUserId != null && commercialUserId.trim().isNotEmpty) {
      query = query.eq('commercial_user_id', commercialUserId);
    }

    final response = await query.order('name', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CrmViewCustomerListItem.fromMap)
        .toList(growable: false);
  }

  Future<List<CrmViewCustomerCountry>> fetchCountries() async {
    final response = await _supabase
        .from('countries')
        .select('id,name,iso2,vat_prefix,phone_prefix')
        .order('name', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CrmViewCustomerCountry.fromMap)
        .toList(growable: false);
  }

  Future<CrmViewCustomerDetail> fetchCustomerDetail(String customerId) async {
    final response = await _supabase
        .from('customers')
        .select('id,name,vat_number,country_id,countries(name)')
        .eq('id', customerId)
        .single();

    return CrmViewCustomerDetail.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<CrmViewCustomerContact>> fetchCustomerContacts(
    String customerId,
  ) async {
    final response = await _supabase
        .from('contacts')
        .select('id,name,email,phone,role,is_primary,created_at')
        .eq('customer_id', customerId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CrmViewCustomerContact.fromMap)
        .toList(growable: false);
  }

  Future<List<CrmViewCustomerSite>> fetchCustomerSites(String customerId) async {
    final response = await _supabase
        .from('customer_sites')
        .select('''
          id,
          name,
          code,
          address_line_1,
          address_line_2,
          postal_code,
          city,
          country_id,
          is_active,
          created_at,
          countries(name)
        ''')
        .eq('customer_id', customerId)
        .order('created_at', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CrmViewCustomerSite.fromMap)
        .toList(growable: false);
  }

  Future<List<WorkflowPhaseOption>> fetchCommercialWorkflowPhases() async {
    final res = await _supabase
        .from('workflow_phases')
        .select('id, name, code, sort_order, is_active, department_code')
        .eq('department_code', 'COM')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(WorkflowPhaseOption.fromMap)
        .toList(growable: false);
  }

  Future<List<CrmInsertRevisionOrder>> fetchOrdersEligibleForRevision({
    String? commercialUserId,
  }) async {
    var query = _supabase.from('orders').select('''
          id,
          order_ref,
          customer_id,
          status,
          contact_id,
          commercial_phase_id,
          customers(name),
          commercial_phase:workflow_phases!fk_orders_commercial_phase(id,code,name),
          order_contact:contacts!orders_contact_id_fkey(id,name,email,phone)
        ''');

    if (commercialUserId != null && commercialUserId.trim().isNotEmpty) {
      query = query.eq('commercial_user_id', commercialUserId);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CrmInsertRevisionOrder.fromMap)
        .toList(growable: false);
  }

  Future<List<CrmInsertRevisionContact>> fetchRevisionContactsForCustomer(
    String customerId,
  ) async {
    final response = await _supabase
        .from('contacts')
        .select('id,name,email,phone,is_primary')
        .eq('customer_id', customerId)
        .order('is_primary', ascending: false)
        .order('name', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CrmInsertRevisionContact.fromMap)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchOrdersInProgress({
    required List<WorkflowPhaseOption> commercialPhases,
    String? commercialUserId,
    int? commercialPhaseId,
  }) async {
    final concludedPhaseId = commercialPhases
        .where((phase) => phase.code == 'concluido')
        .map((phase) => phase.id)
        .firstOrNull;

    final sentPhaseId = commercialPhases
        .where((phase) => phase.code == 'enviado')
        .map((phase) => phase.id)
        .firstOrNull;

    var query = _supabase.from('orders').select('''
      id,
      order_ref,
      created_at,
      customers(name),
      commercial_user_id,
      commercial_phase_id,
      budgeting_phase_id,
      commercial_phase:workflow_phases!fk_orders_commercial_phase(id,name),
      budgeting_phase:workflow_phases!fk_orders_budgeting_phase(id,name),
      versions:order_versions!order_revisions_order_id_fkey(
        id,
        version_number,
        revision_code,
        revision_ref,
        created_at,
        requested_at,
        sent_to_budgeting_at,
        expected_delivery_date,
        proposals:proposals!proposals_order_version_id_fkey(
          id,
          sell_total,
          cost_total,
          margin_pct,
          sent_at,
          feedback_at,
          valid_until
        ),
        assignments:order_budget_assignments(
          is_active,
          assignee:profiles!order_budget_assignments_assignee_user_id_fkey(full_name)
        )
      )
    ''');

    if (commercialPhaseId == null) {
      if (concludedPhaseId != null) {
        query = query.neq('commercial_phase_id', concludedPhaseId);
      }
      if (sentPhaseId != null) {
        query = query.neq('commercial_phase_id', sentPhaseId);
      }
    }

    if (commercialUserId != null && commercialUserId.isNotEmpty) {
      query = query.eq('commercial_user_id', commercialUserId);
    }

    if (commercialPhaseId != null) {
      query = query.eq('commercial_phase_id', commercialPhaseId);
    }

    final res = await query.order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchSentOrders() async {
    return fetchSentOrdersByCommercial();
  }

  Future<List<Map<String, dynamic>>> fetchSentOrdersByCommercial({
    String? commercialUserId,
  }) async {
    final phaseIds = await _fetchCommercialTerminalPhaseIds();
    final sentPhaseId = phaseIds.sentPhaseId;

    if (sentPhaseId == null) {
      return const [];
    }

    var query = _supabase.from('orders').select('''
          id,
          order_ref,
          customer_id,
          commercial_user_id,
          commercial_phase_id,
          customers(name),
          versions:order_versions!order_revisions_order_id_fkey(
            id,
            version_number,
            revision_code,
            revision_ref,
            created_at,
            requested_at,
            sent_to_budgeting_at,
            expected_delivery_date,
            proposals:proposals!proposals_order_version_id_fkey(
              id,
              sent_at,
              feedback_at,
              valid_until
            )
          )
        ''');

    query = query.eq('commercial_phase_id', sentPhaseId);

    if (commercialUserId != null && commercialUserId.trim().isNotEmpty) {
      query = query.eq('commercial_user_id', commercialUserId);
    }

    final res = await query.order('created_at', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> setOrderCommercialPhase({
    required Object orderId,
    required int commercialPhaseId,
  }) {
    return _supabase.rpc(
      'set_order_commercial_phase',
      params: {
        'p_order_id': orderId,
        'p_commercial_phase_id': commercialPhaseId,
      },
    );
  }

  Future<void> updateLatestOrderVersionExpectedDelivery({
    required Object orderId,
    required DateTime expectedDeliveryDate,
  }) {
    final formattedDate =
        '${expectedDeliveryDate.year.toString().padLeft(4, '0')}-${expectedDeliveryDate.month.toString().padLeft(2, '0')}-${expectedDeliveryDate.day.toString().padLeft(2, '0')}';

    return _supabase.rpc(
      'update_latest_order_version_expected_delivery',
      params: {
        'p_order_id': orderId,
        'p_expected_delivery_date': formattedDate,
      },
    );
  }

  Future<void> cancelOrderFromCrm({
    required Object orderId,
    String? reason,
  }) {
    return _supabase.rpc(
      'cancel_order_from_crm',
      params: {
        'p_order_id': orderId,
        'p_reason': reason,
      },
    );
  }

  Future<void> sendProposal({
    required String proposalId,
    required DateTime sentAt,
    required DateTime feedbackAt,
    required DateTime validUntil,
    String? note,
  }) {
    return _supabase.rpc(
      'send_proposal',
      params: {
        'p_proposal_id': proposalId,
        'p_sent_at': sentAt.toIso8601String(),
        'p_feedback_at': feedbackAt.toIso8601String(),
        'p_valid_until': validUntil.toIso8601String(),
        'p_note': note,
      },
    );
  }

  Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required String commercialUserId,
    required String commercialSigla,
    required String contactId,
    required DateTime requestedAt,
    DateTime? expectedDeliveryDate,
    int? commercialPhaseId,
  }) async {
    final response = await _supabase.rpc(
      'create_order',
      params: {
        'p_customer_id': customerId,
        'p_commercial_user_id': commercialUserId,
        'p_commercial_sigla': commercialSigla,
        'p_commercial_phase_id': commercialPhaseId,
        'p_contact_id': contactId,
        'p_requested_at':
            '${requestedAt.year.toString().padLeft(4, '0')}-${requestedAt.month.toString().padLeft(2, '0')}-${requestedAt.day.toString().padLeft(2, '0')}',
        'p_expected_delivery_date': expectedDeliveryDate == null
            ? null
            : '${expectedDeliveryDate.year.toString().padLeft(4, '0')}-${expectedDeliveryDate.month.toString().padLeft(2, '0')}-${expectedDeliveryDate.day.toString().padLeft(2, '0')}',
      },
    );

    return Map<String, dynamic>.from((response as List).first as Map);
  }

  Future<String> createOrderRevisionFromCrm({
    required String orderId,
    String? contactId,
    required DateTime requestedAt,
    DateTime? expectedDeliveryDate,
  }) async {
    final response = await _supabase.rpc(
      'create_order_revision_from_crm',
      params: {
        'p_order_id': orderId,
        'p_contact_id': contactId,
        'p_requested_at':
            '${requestedAt.year.toString().padLeft(4, '0')}-${requestedAt.month.toString().padLeft(2, '0')}-${requestedAt.day.toString().padLeft(2, '0')}',
        'p_expected_delivery_date': expectedDeliveryDate == null
            ? null
            : '${expectedDeliveryDate.year.toString().padLeft(4, '0')}-${expectedDeliveryDate.month.toString().padLeft(2, '0')}-${expectedDeliveryDate.day.toString().padLeft(2, '0')}',
      },
    );

    return response.toString();
  }

  Future<String> createCustomerWithContacts(CrmCreateCustomerInput input) async {
    final primarySite = input.sites.first;
    final response = await _supabase.rpc(
      'create_customer_with_contacts',
      params: {
        'p_name': input.customerName,
        'p_country_id': input.customerCountryId,
        'p_vat_number': input.vatNumber,
        'p_email': input.email,
        'p_phone': input.phone,
        'p_commercial_user_id': input.commercialUserId,
        'p_contacts': input.contacts
            .map((contact) => {
                  'name': contact.name,
                  'email': contact.email,
                  'phone': contact.phone,
                  'role': contact.role,
                  'is_primary': contact.isPrimary,
                })
            .toList(growable: false),
        'p_site_name': primarySite.name,
        'p_site_address_line_1': primarySite.addressLine1,
        'p_site_address_line_2': primarySite.addressLine2,
        'p_site_postal_code': primarySite.postalCode,
        'p_site_city': primarySite.city,
        'p_site_country_id': primarySite.countryId,
      },
    );

    final customerId = response.toString();

    if (input.sites.length > 1) {
      for (final site in input.sites.skip(1)) {
        await addCustomerSite(
          CrmAddCustomerSiteInput(
            customerId: customerId,
            name: site.name,
            code: site.code,
            addressLine1: site.addressLine1,
            addressLine2: site.addressLine2,
            postalCode: site.postalCode,
            city: site.city,
            countryId: site.countryId,
          ),
        );
      }
    }

    return customerId;
  }

  Future<void> addCustomerContact(CrmAddCustomerContactInput input) {
    return _supabase.rpc(
      'add_customer_contact',
      params: {
        'p_customer_id': input.customerId,
        'p_name': input.name.trim(),
        'p_email': input.email.trim(),
        'p_phone': input.phone.trim(),
        'p_role': input.role.trim(),
        'p_is_primary': input.isPrimary,
      },
    );
  }

  Future<void> removeCustomerContact(String contactId) {
    return _supabase.rpc(
      'remove_customer_contact',
      params: {'p_contact_id': contactId},
    );
  }

  Future<void> addCustomerSite(CrmAddCustomerSiteInput input) {
    return _supabase.rpc(
      'add_customer_site',
      params: {
        'p_customer_id': input.customerId,
        'p_name': input.name.trim(),
        'p_code': input.code.trim(),
        'p_address_line_1': input.addressLine1.trim(),
        'p_address_line_2': input.addressLine2.trim(),
        'p_postal_code': input.postalCode.trim(),
        'p_city': input.city.trim(),
        'p_country_id': input.countryId,
      },
    );
  }

  Future<void> removeCustomerSite(String siteId) {
    return _supabase.rpc(
      'remove_customer_site',
      params: {'p_site_id': siteId},
    );
  }

  Future<int?> fetchConcludedCommercialPhaseId() async {
    final phaseIds = await _fetchCommercialTerminalPhaseIds();
    return phaseIds.concludedPhaseId;
  }

  Future<_CommercialTerminalPhaseIds> _fetchCommercialTerminalPhaseIds() async {
    final res = await _supabase
        .from('workflow_phases')
        .select('id, code')
        .eq('department_code', 'COM')
        .inFilter('code', ['enviado', 'concluido']);

    int? sentPhaseId;
    int? concludedPhaseId;

    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final code = (row['code'] ?? '').toString();
      final id = ((row['id'] as num?) ?? 0).toInt();

      if (code == 'enviado') sentPhaseId = id;
      if (code == 'concluido') concludedPhaseId = id;
    }

    return _CommercialTerminalPhaseIds(
      sentPhaseId: sentPhaseId,
      concludedPhaseId: concludedPhaseId,
    );
  }

}

class _CommercialTerminalPhaseIds {
  const _CommercialTerminalPhaseIds({
    required this.sentPhaseId,
    required this.concludedPhaseId,
  });

  final int? sentPhaseId;
  final int? concludedPhaseId;
}
