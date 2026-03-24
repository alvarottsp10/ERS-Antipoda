import 'package:erp_app/features/crm/application/crm_commercial_providers.dart';
import 'package:erp_app/features/crm/application/crm_dashboard_providers.dart';
import 'package:erp_app/features/budgeting/application/budgeting_dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crm_panel.dart';

class OrdersSentPanel extends ConsumerStatefulWidget {
  const OrdersSentPanel({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  ConsumerState<OrdersSentPanel> createState() => _OrdersSentPanelState();
}

class _OrdersSentPanelState extends ConsumerState<OrdersSentPanel> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = widget.useCurrentCommercialOnly
        ? ref.watch(crmOwnSentProposalsProvider)
        : ref.watch(crmSentProposalsProvider);

    return CrmPanel(
      title: 'Propostas Enviadas',
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Erro a carregar propostas enviadas: $error'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Sem propostas enviadas.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 18, child: Text('Ref', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 24, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 14, child: Text('Data Enviada', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 16, child: Text('Data Feedback', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 18, child: Text('Data Validade Proposta', style: TextStyle(fontWeight: FontWeight.w700))),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 18,
                              child: Text(
                                item.reference,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              flex: 24,
                              child: Text(item.customerName, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 14,
                              child: Text(
                                _fmtDate(item.sentAt),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 16,
                              child: _buildDateStatusCell(
                                item.feedbackAt,
                                isExpiry: false,
                              ),
                            ),
                            Expanded(
                              flex: 18,
                              child: _buildDateStatusCell(
                                item.validUntil,
                                isExpiry: true,
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: IconButton(
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                tooltip: 'Marcar como concluido',
                                onPressed: () => _markAsConcluded(item.orderId),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAsConcluded(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Marcar como concluido'),
          content: const Text(
            'Queres marcar esta proposta enviada como concluida?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final concludedPhaseId =
        await ref.read(crmConcludedCommercialPhaseIdProvider.future);
    if (concludedPhaseId == null) {
      return;
    }

    final repository = ref.read(crmRepositoryProvider);
    await repository.setOrderCommercialPhase(
      orderId: orderId,
      commercialPhaseId: concludedPhaseId,
    );

    ref.invalidate(crmSentProposalsProvider);
    ref.invalidate(crmOrdersInProgressProvider);
    ref.invalidate(budgetingNewOrdersProvider);
    ref.invalidate(budgetingActiveBudgetsProvider);
    ref.invalidate(budgetingMyBudgetsProvider);
  }

  String _fmtDate(dynamic value) {
    if (value == null) return '-';

    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return '-';

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  DateTime? _toDateOnly(dynamic value) {
    if (value == null) return null;

    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return null;

    return DateTime(dt.year, dt.month, dt.day);
  }

  Widget _buildDateStatusCell(
    dynamic value, {
    required bool isExpiry,
  }) {
    final dt = _toDateOnly(value);
    final text = _fmtDate(value);

    if (dt == null) {
      return Text(text, overflow: TextOverflow.ellipsis);
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    Color? bgColor;
    if (!dt.isAfter(todayOnly)) {
      bgColor = isExpiry ? const Color(0xFFF4C7C3) : const Color(0xFFFFE0B2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: bgColor == null
          ? null
          : BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
