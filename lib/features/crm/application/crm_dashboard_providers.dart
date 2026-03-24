import 'package:erp_app/features/crm/application/crm_dashboard_mappers.dart';
import 'package:erp_app/features/crm/application/crm_dashboard_view_models.dart';
import 'package:erp_app/features/crm/data/crm_repository.dart';
import 'package:erp_app/features/crm/domain/crm_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  return CrmRepository();
});

final crmCommercialFilterProvider = StateProvider<String?>((ref) => null);
final crmCommercialPhaseFilterProvider = StateProvider<int?>((ref) => null);

final crmCommercialOptionsProvider = FutureProvider<List<CommercialOption>>((
  ref,
) async {
  final repository = ref.watch(crmRepositoryProvider);
  return repository.fetchCommercialOptions();
});

final crmCommercialWorkflowPhasesProvider =
    FutureProvider<List<WorkflowPhaseOption>>((ref) async {
  final repository = ref.watch(crmRepositoryProvider);
  return repository.fetchCommercialWorkflowPhases();
});

final crmOrdersInProgressProvider =
    FutureProvider<List<CrmOrderInProgressItem>>((ref) async {
  final repository = ref.watch(crmRepositoryProvider);
  final commercialUserId = ref.watch(crmCommercialFilterProvider);
  final commercialPhaseId = ref.watch(crmCommercialPhaseFilterProvider);
  final phases = await ref.watch(crmCommercialWorkflowPhasesProvider.future);

  final rows = await repository.fetchOrdersInProgress(
    commercialPhases: phases,
    commercialUserId: commercialUserId,
    commercialPhaseId: commercialPhaseId,
  );

  return rows
      .map(CrmDashboardMappers.mapOrderInProgress)
      .toList(growable: false);
});

final crmSentProposalsProvider =
    FutureProvider<List<CrmSentProposalItem>>((ref) async {
  final repository = ref.watch(crmRepositoryProvider);
  final rows = await repository.fetchSentOrders();

  return rows
      .map(CrmDashboardMappers.mapSentProposal)
      .toList(growable: false);
});

final crmConcludedCommercialPhaseIdProvider = FutureProvider<int?>((ref) async {
  final repository = ref.watch(crmRepositoryProvider);
  return repository.fetchConcludedCommercialPhaseId();
});
