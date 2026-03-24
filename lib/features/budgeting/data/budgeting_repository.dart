import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../domain/budgeting_models.dart';

class WorkTimeCategoryOption {
  const WorkTimeCategoryOption({
    required this.id,
    required this.code,
    required this.label,
  });

  final int id;
  final String code;
  final String label;
}

class BudgetingRepository {
  BudgetingRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<BudgetingBudgeterOption>> fetchBudgeters() async {
    final response = await _supabase
        .from('profiles')
        .select('''
          user_id,
          full_name,
          is_active,
          profile_roles!inner(
            roles!inner(code)
          )
        ''')
        .eq('is_active', true)
        .inFilter(
          'profile_roles.roles.code',
          ['ORCAMENTISTA', 'ORC_MANAGER', 'ADMIN'],
        )
        .order('full_name', ascending: true);

    final unique = <String, BudgetingBudgeterOption>{};
    for (final row in (response as List).cast<Map<String, dynamic>>()) {
      final userId = (row['user_id'] ?? '').toString().trim();
      final fullName = (row['full_name'] ?? '').toString().trim();
      if (userId.isEmpty || fullName.isEmpty) {
        continue;
      }
      unique[userId] = BudgetingBudgeterOption(
        userId: userId,
        fullName: fullName,
      );
    }

    return unique.values.toList(growable: false);
  }

  Future<List<BudgetingOption>> fetchBudgetTypologies() async {
    final response = await _supabase
        .from('budget_typologies')
        .select('id,name,sort_order')
        .order('sort_order', ascending: true);

    final items = (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => BudgetingOption(
            id: ((row['id'] as num?) ?? 0).toInt(),
            name: (row['name'] ?? '').toString(),
          ),
        )
        .toList(growable: false);

    debugPrint('Budget typologies loaded: ${items.length}');
    return items;
  }

  Future<List<BudgetingOption>> fetchProductTypes() async {
    final response = await _supabase
        .from('product_types')
        .select('id,name,sort_order')
        .order('sort_order', ascending: true);

    final items = (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => BudgetingOption(
            id: ((row['id'] as num?) ?? 0).toInt(),
            name: (row['name'] ?? '').toString(),
          ),
        )
        .toList(growable: false);

    debugPrint('Product types loaded: ${items.length}');
    return items;
  }

  Future<List<BudgetingWorkflowPhaseOption>> fetchBudgetingWorkflowPhases() async {
    final response = await _supabase
        .from('workflow_phases')
        .select('id,code,name,sort_order')
        .eq('department_code', 'ORC')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => BudgetingWorkflowPhaseOption(
            id: ((row['id'] as num?) ?? 0).toInt(),
            code: (row['code'] ?? '').toString(),
            name: (row['name'] ?? '').toString(),
            sortOrder: ((row['sort_order'] as num?) ?? 0).toInt(),
          ),
        )
        .toList(growable: false);
  }

  Future<int?> fetchInitialBudgetingPhaseId() async {
    final phases = await fetchBudgetingWorkflowPhases();
    return phases.isEmpty ? null : phases.first.id;
  }

  Future<List<BudgetingOrderSummary>> fetchNewOrdersForAssignment() async {
    final initialPhaseId = await fetchInitialBudgetingPhaseId();
    if (initialPhaseId == null) {
      return const [];
    }

    final response = await _supabase
        .from('orders')
        .select(_ordersDashboardSelect)
        .eq('budgeting_phase_id', initialPhaseId)
        .order('created_at', ascending: false)
        .limit(100);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows
        .map(_mapOrderSummary)
        .where((item) => item.activeAssignments.isEmpty)
        .toList(growable: false);
  }

  Future<List<BudgetingOrderSummary>> fetchMyBudgetOrders() async {
    final userId = currentUserId;
    if (userId == null || userId.trim().isEmpty) {
      return const [];
    }

    final response = await _supabase
        .from('orders')
        .select(_ordersDashboardSelect)
        .not('budgeting_phase_id', 'is', null)
        .order('created_at', ascending: false)
        .limit(200);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows
        .map(_mapOrderSummary)
        .where(
          (item) => item.activeAssignments.any(
            (assignment) => assignment.assigneeUserId == userId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<BudgetingOrderSummary>> fetchActiveBudgetOrders() async {
    final response = await _supabase
        .from('orders')
        .select(_ordersDashboardSelect)
        .not('budgeting_phase_id', 'is', null)
        .order('created_at', ascending: false)
        .limit(200);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows
        .map(_mapOrderSummary)
        .where((item) => item.activeAssignments.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> assignBudgeter({
    required String orderId,
    required String assigneeUserId,
    required String assignmentRole,
    int? budgetTypologyId,
    int? productTypeId,
    required bool isSpecial,
  }) {
    return _supabase.rpc(
      'assign_budgeter',
      params: {
        'p_order_id': orderId,
        'p_assignee_user_id': assigneeUserId,
        'p_assignment_role': assignmentRole,
        'p_budget_typology_id': budgetTypologyId,
        'p_product_type_id': productTypeId,
        'p_is_special': isSpecial,
      },
    );
  }

  Future<void> updateOrderBudgetDetails({
    required String orderId,
    required String orderVersionId,
    required int budgetingPhaseId,
    int? budgetTypologyId,
    int? productTypeId,
    required bool isSpecial,
  }) {
    return _supabase.rpc(
      'update_order_budget_details',
      params: {
        'p_order_id': orderId,
        'p_order_version_id': orderVersionId,
        'p_budgeting_phase_id': budgetingPhaseId,
        'p_budget_typology_id': budgetTypologyId,
        'p_product_type_id': productTypeId,
        'p_is_special': isSpecial,
      },
    );
  }

  Future<List<WorkTimeCategoryOption>> fetchWorkTimeCategories() async {
    final response = await _supabase
      .from('work_time_category_definitions')
      .select('id,code,label,sort_order')
      .eq('department_id', 2)
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('label', ascending: true);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => WorkTimeCategoryOption(
            id: ((row['id'] as num?) ?? 0).toInt(),
            code: (row['code'] ?? '').toString(),
            label: (row['label'] ?? '').toString(),
          ),
        )
        .where((item) => item.id > 0 && item.label.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> addWorkTimeEntry({
    required String budgetAssignmentId,
    required int categoryDefinitionId,
    required Duration duration,
  }) async {
    final assignmentId = int.tryParse(budgetAssignmentId.trim());
    if (assignmentId == null) {
      throw ArgumentError('Invalid budget assignment id');
    }

    final hours = duration.inSeconds / Duration.secondsPerHour;
    if (hours <= 0) {
      throw ArgumentError('Duration must be greater than zero');
    }

    await _supabase.rpc(
      'add_work_time_entry',
      params: {
        'p_budget_assignment_id': assignmentId,
        'p_category_definition_id': categoryDefinitionId,
        'p_hours': hours,
      },
    );
  }

  Future<Map<String, dynamic>> importProposalFromExcel({
    required String orderVersionId,
    required String? fileName,
    required double? totalMaterial,
    required double? totalMo,
    required double? totalProjeto,
    required double? totalVenda,
    required double? margemPct,
    required List<Map<String, dynamic>> equipmentBlocks,
  }) async {
    final response = await _supabase.rpc(
      'import_proposal_from_excel',
      params: {
        'p_order_version_id': orderVersionId,
        'p_file_name': fileName,
        'p_total_material': totalMaterial,
        'p_total_mo': totalMo,
        'p_total_projeto': totalProjeto,
        'p_total_venda': totalVenda,
        'p_margem_pct': margemPct,
        'p_equipment_blocks': equipmentBlocks,
      },
    );

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return {};
  }


  Future<List<Map<String, dynamic>>> fetchOrdersWithFilters({
    String? customerQuery,
    String? orderRefQuery,
    int? year,
  }) async {
    var query = _supabase
        .from('orders')
        .select('''
          id,
          order_ref,
          requested_at,
          customers(name)
        ''');

    final customerFilter = (customerQuery ?? '').trim();
    final orderRefFilter = (orderRefQuery ?? '').trim();

    if (customerFilter.isNotEmpty) {
      query = query.ilike('customers.name', '%$customerFilter%');
    }
    if (orderRefFilter.isNotEmpty) {
      query = query.ilike('order_ref', '%$orderRefFilter%');
    }
    if (year != null) {
      query = query
          .gte('requested_at', '$year-01-01')
          .lt('requested_at', '${year + 1}-01-01');
    }

    final rows = (await query.order('requested_at', ascending: false).limit(300) as List).cast<Map<String, dynamic>>();
    return rows
        .map(
          (row) => {
            'id': (row['id'] ?? '').toString(),
            'order_ref': (row['order_ref'] ?? '').toString(),
            'requested_at': row['requested_at'],
            'requested_year': _parseDateTime(row['requested_at'])?.year,
            'requested_at_label': _formatDate(_parseDateTime(row['requested_at'])),
            'customer_name': _readNestedString(row, 'customers', 'name'),
          },
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> fetchOrderDetail(String orderId) async {
    final row = await _supabase
        .from('orders')
        .select('''
          id,
          order_ref,
          requested_at,
          customers(name),
          versions:order_versions!order_revisions_order_id_fkey(
            id,
            version_number,
            revision_code,
            revision_ref,
            created_at,
            sent_to_budgeting_at,
            budget_delivered_at,
            proposals:proposals!proposals_order_version_id_fkey(
              id,
              cost_material_total,
              cost_labor_total,
              cost_project_total,
              cost_total,
              sell_total,
              margin_pct,
              sent_at,
              feedback_at,
              valid_until,
              proposal_items:proposal_items!proposal_items_proposal_fk(
                id,
                position,
                equipment_name,
                specification,
                quantity,
                cost_total,
                margin,
                raw_payload
              )
            ),
            assignments:order_budget_assignments!order_budget_assignments_order_version_id_fkey(
              id,
              assignee_user_id,
              assignment_role,
              worked_hours,
              budget_typology_id,
              product_type_id,
              assignee:profiles!order_budget_assignments_assignee_user_id_fkey(full_name),
              budget_typology:budget_typologies(name),
              product_type:product_types(name)
            )
          )
        ''')
        .eq('id', orderId)
        .maybeSingle();

    if (row == null) {
      return {};
    }

    final order = Map<String, dynamic>.from(row);
    final versions = _readList(order['versions'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true)
      ..sort((a, b) {
        final aNum = (a['version_number'] as num?)?.toInt() ?? 0;
        final bNum = (b['version_number'] as num?)?.toInt() ?? 0;
        return aNum.compareTo(bNum);
      });

    final budgetersByUser = <String, Map<String, dynamic>>{};
    String primaryTypology = '';
    String primaryProductType = '';

    for (final version in versions) {
      final assignments = _readList(version['assignments']);

      for (final rawAssignment in assignments) {
        if (rawAssignment is! Map) {
          continue;
        }

        final assignment = Map<String, dynamic>.from(rawAssignment);
        final assignee = assignment['assignee'];
        final assigneeName = assignee is Map
            ? (assignee['full_name'] ?? '').toString().trim()
            : '';

        final assigneeUserId =
            (assignment['assignee_user_id'] ?? '').toString().trim();
        final budgeterKey = assigneeUserId.isNotEmpty ? assigneeUserId : assigneeName;
        final hours = ((assignment['worked_hours'] as num?) ?? 0).toDouble();

        if (budgeterKey.isNotEmpty) {
          final existing = budgetersByUser[budgeterKey];
          if (existing == null) {
            budgetersByUser[budgeterKey] = {
              'name': assigneeName,
              'hours': hours,
            };
          } else {
            existing['hours'] = (((existing['hours'] as num?) ?? 0).toDouble()) + hours;
          }
        }

        if (primaryTypology.isEmpty) {
          final budgetTypology = assignment['budget_typology'];
          if (budgetTypology is Map) {
            primaryTypology = (budgetTypology['name'] ?? '').toString().trim();
          }
        }

        if (primaryProductType.isEmpty) {
          final productType = assignment['product_type'];
          if (productType is Map) {
            primaryProductType = (productType['name'] ?? '').toString().trim();
          }
        }
      }
    }

    final budgeters = budgetersByUser.values.toList(growable: false)
      ..sort((a, b) => ((b['hours'] as num?) ?? 0)
          .toDouble()
          .compareTo(((a['hours'] as num?) ?? 0).toDouble()));

    debugPrint('FETCH DETAIL RAW VERSIONS: ${order['versions']}');

    return {
      'id': (order['id'] ?? '').toString(),
      'order_ref': (order['order_ref'] ?? '').toString(),
      'requested_at': order['requested_at'],
      'customer_name': _readNestedString(order, 'customers', 'name'),
      'primary_typology': primaryTypology,
      'primary_product_type': primaryProductType,
      'budgeters': budgeters,
      'versions': versions.map((version) {
        final assignments = _readList(version['assignments']);
        final rawProposals = version['proposals'];
        final proposals = rawProposals is Map
            ? <Map<String, dynamic>>[Map<String, dynamic>.from(rawProposals)]
            : _readList(rawProposals)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList(growable: false);
        final proposal = proposals.isEmpty
            ? null
            : Map<String, dynamic>.from(proposals.first as Map);

        return {
          'id': (version['id'] ?? '').toString(),
          'version_number': (version['version_number'] as num?)?.toInt(),
          'revision_code': (version['revision_code'] ?? '').toString(),
          'revision_ref': (version['revision_ref'] ?? '').toString(),
          'version_label': _resolveVersionLabel(version).isEmpty
              ? ((version['revision_ref'] ?? version['id'] ?? 'Versao').toString())
              : _resolveVersionLabel(version),
          'sent_to_budgeting_at': version['sent_to_budgeting_at'],
          'budget_delivered_at': version['budget_delivered_at'],
          'proposal_typology': _readNestedString(
            proposal ?? const <String, dynamic>{},
            'budget_typology',
            'name',
          ),
          'proposal_product_type': _readNestedString(
            proposal ?? const <String, dynamic>{},
            'product_type',
            'name',
          ),
          'is_special': proposal?['is_special'] == true,
          'phase_name': _readNestedString(
            proposal ?? const <String, dynamic>{},
            'phase',
            'name',
          ),
          'date_label': _formatDate(_parseDateTime(proposal?['sent_at'])),
          'total_hours': assignments.fold<double>(
            0,
            (sum, item) => sum + (((item as Map)['worked_hours'] as num?) ?? 0).toDouble(),
          ),
          'total_value': (proposal?['sell_total'] as num?)?.toDouble(),
          'proposal': proposal,
          'proposals': proposals,
        };
      }).toList(growable: false),
    };
  }

  BudgetingOrderSummary _mapOrderSummary(Map<String, dynamic> row) {
    final versions = _readList(row['versions']);
    final latestVersion = _findLatestVersion(versions);

    final activeProposal = _findFirstProposal(latestVersion);

    return BudgetingOrderSummary(
      orderId: (row['id'] ?? '').toString(),
      orderRef: (row['order_ref'] ?? '').toString(),
      latestVersionRef: (latestVersion?['revision_ref'] ?? row['order_ref'] ?? '')
          .toString(),
      versionLabel: _resolveVersionLabel(latestVersion),
      customerName: _readNestedString(row, 'customers', 'name'),
      createdAt: _parseDateTime(row['created_at']),
      requestedAt: _parseDateTime(latestVersion?['requested_at']),
      sentToBudgetingAt: _parseDateTime(latestVersion?['sent_to_budgeting_at']),
      expectedDeliveryDate:
          _parseDateTime(latestVersion?['expected_delivery_date']),
      budgetingPhaseId: (row['budgeting_phase_id'] as num?)?.toInt(),
      budgetingPhaseName: _readNestedString(row, 'budgeting_phase', 'name'),
      latestVersionId: (latestVersion?['id'] ?? '').toString(),
      activeProposalId: activeProposal?['id']?.toString(),
      activeProposalSellTotal:
          (activeProposal?['sell_total'] as num?)?.toDouble(),
      activeProposalCostTotal:
          (activeProposal?['cost_total'] as num?)?.toDouble(),
      activeProposalCostMaterialTotal:
          (activeProposal?['cost_material_total'] as num?)?.toDouble(),
      activeProposalCostLaborTotal:
          (activeProposal?['cost_labor_total'] as num?)?.toDouble(),
      activeProposalCostProjectTotal:
          (activeProposal?['cost_project_total'] as num?)?.toDouble(),
      activeProposalMarginPct:
          (activeProposal?['margin_pct'] as num?)?.toDouble(),
      activeProposalSentAt: _parseDateTime(activeProposal?['sent_at']),
      activeProposalFeedbackAt: _parseDateTime(activeProposal?['feedback_at']),
      activeProposalValidUntil: _parseDateTime(activeProposal?['valid_until']),
      activeProposalItems: _readMapList(activeProposal?['proposal_items']),
      activeAssignments: _findActiveAssignments(latestVersion),
    );
  }

  static List<dynamic> _readList(dynamic value) {
    return value is List ? List<dynamic>.from(value) : <dynamic>[];
  }

  static List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static String _readNestedString(
    Map<String, dynamic> row,
    String parentKey,
    String childKey,
  ) {
    final parent = row[parentKey];
    if (parent is Map) {
      return (parent[childKey] ?? '').toString();
    }
    return '';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static Map<String, dynamic>? _findLatestVersion(List<dynamic> versions) {
    Map<String, dynamic>? latestVersion;

    for (final version in versions) {
      if (version is! Map) {
        continue;
      }

      final versionMap = Map<String, dynamic>.from(version);
      if (latestVersion == null) {
        latestVersion = versionMap;
        continue;
      }

      final currentVersionNumber =
          (versionMap['version_number'] as num?)?.toInt() ?? 0;
      final latestVersionNumber =
          (latestVersion['version_number'] as num?)?.toInt() ?? 0;

      if (currentVersionNumber > latestVersionNumber) {
        latestVersion = versionMap;
        continue;
      }

      if (currentVersionNumber == latestVersionNumber) {
        final currentCreatedAt =
            DateTime.tryParse((versionMap['created_at'] ?? '').toString());
        final latestCreatedAt =
            DateTime.tryParse((latestVersion['created_at'] ?? '').toString());

        if (currentCreatedAt != null &&
            (latestCreatedAt == null ||
                currentCreatedAt.isAfter(latestCreatedAt))) {
          latestVersion = versionMap;
        }
      }
    }

    return latestVersion;
  }

  static Map<String, dynamic>? _findFirstProposal(
    Map<String, dynamic>? latestVersion,
  ) {
    final proposals = latestVersion?['proposals'];
    if (proposals is Map) {
      return Map<String, dynamic>.from(proposals);
    }
    if (proposals is! List) {
      return null;
    }

    for (final proposal in proposals) {
      if (proposal is Map) {
        return Map<String, dynamic>.from(proposal);
      }
    }

    return null;
  }

  static List<BudgetingAssignmentSummary> _findActiveAssignments(
    Map<String, dynamic>? latestVersion,
  ) {
    final assignments = latestVersion?['assignments'];
    if (assignments is! List) {
      return const [];
    }

    final items = <BudgetingAssignmentSummary>[];
    for (final assignment in assignments) {
      if (assignment is! Map || assignment['is_active'] != true) {
        continue;
      }

      final assignmentMap = Map<String, dynamic>.from(assignment);
      final assigneeMap = assignmentMap['assignee'];
      final typologyMap = assignmentMap['budget_typology'];
      final productTypeMap = assignmentMap['product_type'];

      items.add(
        BudgetingAssignmentSummary(
          id: (assignmentMap['id'] ?? '').toString(),
          assigneeUserId: assignmentMap['assignee_user_id']?.toString(),
          assigneeName: assigneeMap is Map
              ? (assigneeMap['full_name'] ?? '').toString()
              : '',
          assignmentRole: (assignmentMap['assignment_role'] ?? 'support')
              .toString()
              .trim()
              .toLowerCase(),
          workedHours: ((assignmentMap['worked_hours'] as num?) ?? 0)
              .toDouble(),
          budgetTypologyId:
              (assignmentMap['budget_typology_id'] as num?)?.toInt(),
          budgetTypologyName: typologyMap is Map
              ? (typologyMap['name'] ?? '').toString()
              : '',
          productTypeId: (assignmentMap['product_type_id'] as num?)?.toInt(),
          productTypeName: productTypeMap is Map
              ? (productTypeMap['name'] ?? '').toString()
              : '',
          isSpecial: assignmentMap['is_special'] == true,
        ),
      );
    }

    items.sort((a, b) {
      if (a.assignmentRole == b.assignmentRole) {
        return a.assigneeName.compareTo(b.assigneeName);
      }
      return a.assignmentRole == 'lead' ? -1 : 1;
    });

    return items;
  }

  static String _resolveVersionLabel(Map<String, dynamic>? latestVersion) {
    final revisionCode =
        (latestVersion?['revision_code'] ?? '').toString().trim().toUpperCase();

    if (revisionCode.isEmpty) {
      return '';
    }

    return revisionCode;
  }

  static const String _ordersDashboardSelect = '''
    id,
    order_ref,
    created_at,
    budgeting_phase_id,
    customers(name),
    budgeting_phase:workflow_phases!fk_orders_budgeting_phase(id,name),
    versions:order_versions!order_revisions_order_id_fkey(
      id,
      created_at,
      version_number,
      revision_code,
      revision_ref,
      requested_at,
      sent_to_budgeting_at,
      expected_delivery_date,
      proposals:proposals!proposals_order_version_id_fkey(
        id,
        cost_material_total,
        cost_labor_total,
        cost_project_total,
        cost_total,
        sell_total,
        margin_pct,
        sent_at,
        feedback_at,
        valid_until,
        proposal_items:proposal_items!proposal_items_proposal_fk(
          id,
          position,
          equipment_name,
          specification,
          quantity,
          cost_total,
          margin,
          raw_payload
        )
      ),
      assignments:order_budget_assignments!order_budget_assignments_order_version_id_fkey(
        id,
        is_active,
        assignee_user_id,
        assignment_role,
        worked_hours,
        is_special,
        budget_typology_id,
        product_type_id,
        assignee:profiles!order_budget_assignments_assignee_user_id_fkey(full_name),
        budget_typology:budget_typologies(name),
        product_type:product_types(name)
      )
    )
  ''';
}
