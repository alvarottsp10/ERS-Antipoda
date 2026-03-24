import 'package:erp_app/features/app/application/app_realtime_service.dart';
import 'package:erp_app/features/budgeting/application/budgeting_dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/budgeting_dashboard_actions_bar.dart';
import 'widgets/my_budgets_panel.dart';

class BudgetingUserDashboardScreen extends ConsumerStatefulWidget {
  const BudgetingUserDashboardScreen({super.key});

  @override
  ConsumerState<BudgetingUserDashboardScreen> createState() =>
      _BudgetingUserDashboardScreenState();
}

class _BudgetingUserDashboardScreenState
    extends ConsumerState<BudgetingUserDashboardScreen> {
  final _realtimeService = AppRealtimeService();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = _realtimeService.watchTables(
      channelName: 'budget-user-dashboard',
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
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetingDashboardActionsBar(
            showSupplierAction: true,
            showViewBudgetsAction: true,
          ),
          SizedBox(height: 16),
          Expanded(child: MyBudgetsPanel()),
        ],
      ),
    );
  }
}
