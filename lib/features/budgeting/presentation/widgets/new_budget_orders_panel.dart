import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/budgeting_dashboard_providers.dart';
import '../dialog/assign_budgeter_dialog.dart';
import 'budgeting_panel.dart';

class NewBudgetOrdersPanel extends ConsumerWidget {
  const NewBudgetOrdersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(budgetingNewOrdersProvider);

    return BudgetingPanel(
      title: 'Novos Pedidos',
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Erro ao carregar novos pedidos: $error',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Sem novos pedidos por atribuir.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () async {
                  final changed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AssignBudgeterDialog(
                      orderId: item.orderId,
                      orderRef: item.orderRef,
                      customerName: item.customerName,
                      entryDateLabel: item.entryDateLabel,
                      expectedDeliveryDateLabel:
                          item.expectedDeliveryDateLabel,
                    ),
                  );

                  if (changed == true) {
                    ref.invalidate(budgetingNewOrdersProvider);
                    ref.invalidate(budgetingActiveBudgetsProvider);
                    ref.invalidate(budgetingMyBudgetsProvider);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayLabel.isEmpty
                              ? '(sem referencia)'
                              : item.displayLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
