import 'crm_dashboard_view_models.dart';

class CrmDashboardMappers {
  const CrmDashboardMappers._();

  static CrmOrderInProgressItem mapOrderInProgress(Map<String, dynamic> row) {
    final versions = _readList(row['versions']);
    final latestVersion = _findLatestVersion(versions);
    final latestProposal = _findFirstProposal(latestVersion);
    final orderRefForProposal =
        (latestVersion?['revision_ref'] ?? row['order_ref'] ?? '').toString();
    final proposalId = latestProposal?['id']?.toString();
    final sendProposalBlockReason = _buildSendProposalBlockReason(latestProposal);

    return CrmOrderInProgressItem(
      orderId: row['id'] ?? '',
      orderRef: (row['order_ref'] ?? '').toString(),
      versionLabel: _resolveVersionLabel(latestVersion),
      orderRefForProposal: orderRefForProposal,
      customerName: _readNestedString(row, 'customers', 'name'),
      requestedAt: _parseDateValue(latestVersion?['requested_at']),
      sentToBudgetingAt: _parseDateValue(latestVersion?['sent_to_budgeting_at']),
      expectedDeliveryDate:
          _parseDateValue(latestVersion?['expected_delivery_date']),
      commercialPhaseName: _readNestedString(row, 'commercial_phase', 'name'),
      budgetingPhaseName: _readNestedString(row, 'budgeting_phase', 'name'),
      budgeterName: _findActiveBudgeter(versions),
      commercialPhaseId: (row['commercial_phase_id'] as num?)?.toInt(),
      proposalId: proposalId,
      hasProposal: latestProposal != null,
      canSendProposal: sendProposalBlockReason == null,
      sendProposalBlockReason: sendProposalBlockReason,
    );
  }

  static CrmSentProposalItem mapSentProposal(Map<String, dynamic> row) {
    final versions = _readList(row['versions']);
    final latestVersion = _findLatestVersion(versions);
    final latestProposal = _findLatestProposal(latestVersion);

    return CrmSentProposalItem(
      orderId: (row['id'] ?? '').toString(),
      reference: _resolveOrderRef(row, latestVersion),
      customerName: _readNestedString(row, 'customers', 'name'),
      sentAt: latestProposal?['sent_at'],
      feedbackAt: latestProposal?['feedback_at'],
      validUntil: latestProposal?['valid_until'],
      rawOrder: row,
      rawLatestVersion: latestVersion,
      rawLatestProposal: latestProposal,
    );
  }

  static List<dynamic> _readList(dynamic value) {
    return value is List ? List<dynamic>.from(value) : <dynamic>[];
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

  static Map<String, dynamic>? _findLatestProposal(
    Map<String, dynamic>? latestVersion,
  ) {
    Map<String, dynamic>? latestProposal;
    final proposalsRaw = latestVersion?['proposals'];

    if (proposalsRaw is Map) {
      return Map<String, dynamic>.from(proposalsRaw);
    }

    if (proposalsRaw is List && proposalsRaw.isNotEmpty) {
      for (final proposal in proposalsRaw) {
        if (proposal is! Map) {
          continue;
        }

        final proposalMap = Map<String, dynamic>.from(proposal);
        if (latestProposal == null) {
          latestProposal = proposalMap;
          continue;
        }

        final currentSentAt =
            DateTime.tryParse((proposalMap['sent_at'] ?? '').toString());
        final latestSentAt =
            DateTime.tryParse((latestProposal['sent_at'] ?? '').toString());

        if (currentSentAt != null &&
            (latestSentAt == null || currentSentAt.isAfter(latestSentAt))) {
          latestProposal = proposalMap;
        }
      }
    }

    return latestProposal;
  }

  static Map<String, dynamic>? _findFirstProposal(
    Map<String, dynamic>? latestVersion,
  ) {
    final proposalsRaw = latestVersion?['proposals'];

    if (proposalsRaw is Map) {
      return Map<String, dynamic>.from(proposalsRaw);
    }

    if (proposalsRaw is List) {
      for (final proposal in proposalsRaw) {
        if (proposal is Map) {
          return Map<String, dynamic>.from(proposal);
        }
      }
    }

    return null;
  }

  static String _resolveOrderRef(
    Map<String, dynamic> row,
    Map<String, dynamic>? latestVersion,
  ) {
    var ref = (row['order_ref'] ?? '').toString();
    final latestRevisionRef =
        (latestVersion?['revision_ref'] ?? '').toString().trim();

    if (latestRevisionRef.isNotEmpty) {
      ref = latestRevisionRef;
    }

    return ref;
  }

  static String _resolveVersionLabel(Map<String, dynamic>? latestVersion) {
    final revisionCode =
        (latestVersion?['revision_code'] ?? '').toString().trim().toUpperCase();

    if (revisionCode.isEmpty) {
      return 'Original';
    }

    return revisionCode;
  }

  static String _findActiveBudgeter(List<dynamic> versions) {
    List<dynamic> assignments = const [];

    for (final version in versions) {
      if (version is Map && version['assignments'] is List) {
        assignments = List<dynamic>.from(version['assignments'] as List);
        break;
      }
    }

    for (final assignment in assignments) {
      if (assignment is Map && assignment['is_active'] == true) {
        final name = (assignment['assignee'] is Map
                ? assignment['assignee']['full_name']
                : null)
            ?.toString();
        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    }

    return '-';
  }

  static String? _buildSendProposalBlockReason(
    Map<String, dynamic>? latestProposal,
  ) {
    if (latestProposal == null) {
      return 'Sem proposta associada à versão atual.';
    }

    final proposalId = latestProposal['id']?.toString().trim() ?? '';
    if (proposalId.isEmpty) {
      return 'A proposta associada não tem identificador válido.';
    }

    final hasSellTotal = latestProposal['sell_total'] != null;
    final hasCostTotal = latestProposal['cost_total'] != null;
    final hasMargin = latestProposal['margin_pct'] != null;

    if (!hasSellTotal || !hasCostTotal || !hasMargin) {
      return 'A proposta associada ainda não tem os dados mínimos carregados.';
    }

    return null;
  }

  static DateTime? _parseDateValue(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
