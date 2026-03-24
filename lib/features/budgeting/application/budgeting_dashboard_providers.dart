import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budgeting_repository.dart';
import 'budgeting_dashboard_mappers.dart';
import 'budgeting_dashboard_view_models.dart';

final budgetingRepositoryProvider = Provider<BudgetingRepository>((ref) {
  return BudgetingRepository();
});

final budgetingNewOrdersProvider =
    FutureProvider<List<BudgetingNewOrderItem>>((ref) async {
  final repository = ref.watch(budgetingRepositoryProvider);
  final rows = await repository.fetchNewOrdersForAssignment();
  return rows
      .map(BudgetingDashboardMappers.mapNewOrder)
      .toList(growable: false);
});

final budgetingMyBudgetsProvider =
    FutureProvider<List<BudgetingMyBudgetItem>>((ref) async {
  final repository = ref.watch(budgetingRepositoryProvider);
  final rows = await repository.fetchMyBudgetOrders();
  return rows
      .map(BudgetingDashboardMappers.mapMyBudget)
      .toList(growable: false);
});

final budgetingActiveBudgetsProvider =
    FutureProvider<List<BudgetingActiveBudgetItem>>((ref) async {
  final repository = ref.watch(budgetingRepositoryProvider);
  final rows = await repository.fetchActiveBudgetOrders();
  return rows
      .map(BudgetingDashboardMappers.mapActiveBudget)
      .toList(growable: false);
});
