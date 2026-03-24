import 'package:erp_app/features/crm/application/crm_dashboard_mappers.dart';
import 'package:erp_app/features/crm/application/crm_dashboard_view_models.dart';
import 'package:erp_app/features/crm/data/crm_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crm_dashboard_providers.dart';

final crmOwnOrdersInProgressProvider =
    FutureProvider<List<CrmOrderInProgressItem>>((ref) async {
  final repository = ref.watch(crmRepositoryProvider);
  final phases = await ref.watch(crmCommercialWorkflowPhasesProvider.future);
  final currentUserId = repository.currentUserId;

  if (currentUserId == null || currentUserId.trim().isEmpty) {
    return const [];
  }

  final rows = await repository.fetchOrdersInProgress(
    commercialPhases: phases,
    commercialUserId: currentUserId,
    commercialPhaseId: null,
  );

  return rows
      .map(CrmDashboardMappers.mapOrderInProgress)
      .toList(growable: false);
});

final crmOwnSentProposalsProvider =
    FutureProvider<List<CrmSentProposalItem>>((ref) async {
  final repository = ref.watch(crmRepositoryProvider);
  final currentUserId = repository.currentUserId;

  if (currentUserId == null || currentUserId.trim().isEmpty) {
    return const [];
  }

  final rows = await repository.fetchSentOrdersByCommercial(
    commercialUserId: currentUserId,
  );

  return rows
      .map(CrmDashboardMappers.mapSentProposal)
      .toList(growable: false);
});
