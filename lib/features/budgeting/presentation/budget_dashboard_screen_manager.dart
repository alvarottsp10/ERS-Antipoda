import 'package:erp_app/features/app/application/app_access_providers.dart';
import 'package:erp_app/features/app/application/app_realtime_service.dart';
import 'package:erp_app/features/budgeting/application/budgeting_dashboard_providers.dart';
import 'package:erp_app/features/budgeting/presentation/budgeting_user_dashboard_screen.dart';
import 'package:erp_app/features/budgeting/presentation/widgets/active_budgets_panel.dart';
import 'package:erp_app/features/budgeting/presentation/widgets/budgeting_dashboard_actions_bar.dart';
import 'package:erp_app/features/budgeting/presentation/widgets/my_budgets_panel.dart';
import 'package:erp_app/features/budgeting/presentation/widgets/new_budget_orders_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetDashboardScreen extends ConsumerStatefulWidget {
  const BudgetDashboardScreen({super.key});

  @override
  ConsumerState<BudgetDashboardScreen> createState() =>
      _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState extends ConsumerState<BudgetDashboardScreen> {
  final _realtimeService = AppRealtimeService();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = _realtimeService.watchTables(
      channelName: 'budget-dashboard',
      tables: const [
        'orders',
        'order_versions',
        'order_budget_assignments',
        'proposals',
      ],
      onChanged: _invalidateBudgetingProviders,
    );
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      _realtimeService.disposeChannel(channel);
    }
    super.dispose();
  }

  void _invalidateBudgetingProviders() {
    ref.invalidate(budgetingNewOrdersProvider);
    ref.invalidate(budgetingActiveBudgetsProvider);
    ref.invalidate(budgetingMyBudgetsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(appAccessProvider);

    return accessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Erro a carregar permissoes: $error'),
        ),
      ),
      data: (access) {
        if (access.canAccessBudgetManagement) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BudgetingDashboardActionsBar(
                  showViewBudgetsAction: true,
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: NewBudgetOrdersPanel()),
                      SizedBox(width: 16),
                      Expanded(flex: 9, child: ActiveBudgetsPanel()),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(child: MyBudgetsPanel()),
              ],
            ),
          );
        }

        if (access.isBudgeter) {
          return const BudgetingUserDashboardScreen();
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Acesso restrito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Este ecra e reservado a utilizadores da area de orcamentacao ou administracao.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
