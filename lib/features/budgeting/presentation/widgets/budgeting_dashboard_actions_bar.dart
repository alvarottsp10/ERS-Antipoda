import 'package:flutter/material.dart';

import '../view_budgets_screen.dart';

class BudgetingDashboardActionsBar extends StatelessWidget {
  const BudgetingDashboardActionsBar({
    super.key,
    this.showSupplierAction = true,
    this.showViewBudgetsAction = false,
  });

  final bool showSupplierAction;
  final bool showViewBudgetsAction;

  @override
  Widget build(BuildContext context) {
    if (!showSupplierAction && !showViewBudgetsAction) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          if (showViewBudgetsAction)
            SizedBox(
              width: 180,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ViewBudgetsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text(
                  'Ver orcamentos',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE7E7E7),
                  foregroundColor: const Color(0xFF151515),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFC9C9C9), width: 1),
                  ),
                ),
              ),
            ),
          if (showSupplierAction)
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const _AddSupplierPlaceholderDialog(),
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text(
                  'Adicionar Fornecedor',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE7E7E7),
                  foregroundColor: const Color(0xFF151515),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFC9C9C9), width: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddSupplierPlaceholderDialog extends StatelessWidget {
  const _AddSupplierPlaceholderDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Fornecedor'),
      content: const Text(
        'Ainda nao existe tabela ou fluxo de fornecedores no Supabase.\n\n'
        'Cria a tabela e depois ligamos aqui o formulario e a escrita por RPC.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
