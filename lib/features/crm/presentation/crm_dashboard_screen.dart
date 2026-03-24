import 'package:erp_app/features/app/application/app_access_providers.dart';
import 'package:erp_app/features/app/application/app_realtime_service.dart';
import 'package:erp_app/features/crm/application/crm_commercial_providers.dart';
import 'package:erp_app/features/crm/application/crm_dashboard_providers.dart';
import 'package:erp_app/features/crm/presentation/crm_commercial_dashboard_screen.dart';
import 'package:erp_app/features/crm/presentation/widgets/crm_dashboard_actions_bar.dart';
import 'package:erp_app/features/crm/presentation/widgets/orders_in_progress_panel.dart';
import 'package:erp_app/features/crm/presentation/widgets/orders_sent_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrmDashboardScreen extends ConsumerStatefulWidget {
  const CrmDashboardScreen({super.key});

  @override
  ConsumerState<CrmDashboardScreen> createState() => _CrmDashboardScreenState();
}

class _CrmDashboardScreenState extends ConsumerState<CrmDashboardScreen> {
  final _realtimeService = AppRealtimeService();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = _realtimeService.watchTables(
      channelName: 'crm-dashboard',
      tables: const [
        'orders',
        'order_versions',
        'order_budget_assignments',
        'proposals',
      ],
      onChanged: _invalidateCrmProviders,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _invalidateCrmProviders();
    });
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      _realtimeService.disposeChannel(channel);
    }
    super.dispose();
  }

  void _invalidateCrmProviders() {
    ref.invalidate(crmOrdersInProgressProvider);
    ref.invalidate(crmSentProposalsProvider);
    ref.invalidate(crmOwnOrdersInProgressProvider);
    ref.invalidate(crmOwnSentProposalsProvider);
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
        if (access.canAccessCrmManagement) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CrmDashboardActionsBar(),
                SizedBox(height: 16),
                Expanded(child: OrdersInProgressPanel()),
                SizedBox(height: 16),
                Expanded(child: OrdersSentPanel()),
              ],
            ),
          );
        }

        if (access.isCommercial) {
          return const CrmCommercialDashboardScreen();
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
                      'Este ecra e reservado a utilizadores com perfil de gestao CRM ou administracao.',
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
