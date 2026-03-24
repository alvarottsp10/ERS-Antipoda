class ViewBudgetVersionData {
  const ViewBudgetVersionData({
    required this.versionId,
    required this.versionTitle,
    required this.dateLabel,
    required this.phaseLabel,
    required this.proposalTypology,
    required this.proposalProductType,
    required this.isSpecial,
    required this.entryDateLabel,
    required this.exitDateLabel,
    required this.isConcluded,
    required this.proposal,
    required this.proposalItems,
    required this.totalValue,
    required this.totalHours,
    required this.hasProposal,
  });

  final String versionId;
  final String versionTitle;
  final String dateLabel;
  final String phaseLabel;
  final String proposalTypology;
  final String proposalProductType;
  final bool isSpecial;
  final String entryDateLabel;
  final String exitDateLabel;
  final bool isConcluded;
  final Map<String, dynamic>? proposal;
  final List<Map<String, dynamic>> proposalItems;
  final double? totalValue;
  final double totalHours;
  final bool hasProposal;
}

ViewBudgetVersionData mapViewBudgetVersionData(
  Map<String, dynamic> version,
  int index,
) {
  final rawProposals = version['proposals'];
  final proposals = rawProposals is Map
      ? [Map<String, dynamic>.from(rawProposals)]
      : ((rawProposals as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

  final proposal = version['proposal'] is Map
      ? Map<String, dynamic>.from(version['proposal'])
      : (proposals.isNotEmpty ? proposals.first : null);
  final proposalItems = ((proposal?['proposal_items'] as List?) ??
          const <dynamic>[])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);

  return ViewBudgetVersionData(
    versionId: readViewBudgetText(version['id']),
    versionTitle: resolveProposalTitle(version, index),
    dateLabel: readViewBudgetText(
      version['date_label'] ?? proposal?['sent_at_label'],
    ),
    phaseLabel: readViewBudgetText(version['phase_name']),
    proposalTypology: readViewBudgetText(version['proposal_typology']),
    proposalProductType: readViewBudgetText(version['proposal_product_type']),
    isSpecial: version['is_special'] == true,
    entryDateLabel: formatViewBudgetDate(
      tryParseViewBudgetDate(version['sent_to_budgeting_at']),
    ),
    exitDateLabel: formatViewBudgetDate(
      tryParseViewBudgetDate(version['budget_delivered_at']),
    ),
    isConcluded: version['is_concluded'] == true,
    proposal: proposal,
    proposalItems: proposalItems,
    totalValue: (version['total_value'] as num?)?.toDouble(),
    totalHours: ((version['total_hours'] as num?) ?? 0).toDouble(),
    hasProposal: proposal != null,
  );
}

List<Map<String, dynamic>> readBudgeters(Map<String, dynamic> detail) {
  return ((detail['budgeters'] as List?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<Map<String, dynamic>> mapProposalItemsForDialog(
  List<Map<String, dynamic>> proposalItems,
) {
  return proposalItems
      .map(mapProposalItemForDialog)
      .toList(growable: false);
}

Map<String, dynamic> mapProposalItemForDialog(
  Map<String, dynamic> item,
) {
  final rawPayload = item['raw_payload'];
  final payload = rawPayload is Map
      ? Map<String, dynamic>.from(rawPayload)
      : <String, dynamic>{};

  return {
    'main_equipment': payload['main_equipment'] ?? item['equipment_name'],
    'main_description': payload['main_description'] ?? item['specification'],
    'quantity': payload['quantity'] ?? item['quantity'],
    'cost_total': payload['cost_total'] ?? item['cost_total'],
    'margin': payload['margin'] ?? item['margin'],
    'detected_attributes':
        payload['detected_attributes'] ?? const <String, dynamic>{},
  };
}

String resolveProposalTitle(Map<String, dynamic> version, int index) {
  final revisionCode = readViewBudgetText(version['revision_code']);

  if (revisionCode.isNotEmpty) {
    return 'Proposta ${revisionCode.toUpperCase()}';
  }

  final versionNumber = version['version_number'];

  if (versionNumber == 1) {
    return 'Proposta Original';
  }

  if (versionNumber is int && versionNumber > 1) {
    final letterCode = 64 + versionNumber - 1;
    if (letterCode >= 65 && letterCode <= 90) {
      return 'Proposta ${String.fromCharCode(letterCode)}';
    }
  }

  return 'Proposta ${index + 1}';
}

DateTime? tryParseViewBudgetDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String formatViewBudgetDate(DateTime? value) {
  if (value == null) {
    return '-';
  }

  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year}';
}

String formatViewBudgetAmount(double? value) {
  if (value == null) {
    return '-';
  }
  return value.toStringAsFixed(2);
}

String readViewBudgetText(dynamic value) {
  return (value ?? '').toString().trim();
}

bool isExpandedVersion(String expandedVersionId, String versionId) {
  return versionId.isNotEmpty && expandedVersionId == versionId;
}
