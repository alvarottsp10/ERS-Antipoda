import 'package:erp_app/features/crm/presentation/dialogs/add_customer_dialog.dart';
import 'package:erp_app/features/crm/presentation/dialogs/insert_order_dialog.dart';
import 'package:erp_app/features/crm/presentation/dialogs/insert_revision_dialog.dart';
import 'package:erp_app/features/crm/presentation/dialogs/view_customers_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/crm_commercial_providers.dart';
import '../../application/crm_dashboard_providers.dart';
import 'crm_panel.dart';

class CrmDashboardActionsBar extends ConsumerWidget {
  const CrmDashboardActionsBar({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1150;

        final left = Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => InsertOrderDialog(
                      useCurrentCommercialOnly: useCurrentCommercialOnly,
                    ),
                  );

                  if (res != null) {
                    ref.invalidate(crmOrdersInProgressProvider);
                    ref.invalidate(crmSentProposalsProvider);
                    ref.invalidate(crmOwnOrdersInProgressProvider);
                    ref.invalidate(crmOwnSentProposalsProvider);
                    debugPrint('Pedido criado: ${res['id']}  ref=${res['order_ref']}');
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Inserir Pedido',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB7E4C7),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => InsertRevisionDialog(
                      useCurrentCommercialOnly: useCurrentCommercialOnly,
                    ),
                  );

                  if (res != null) {
                    ref.invalidate(crmOrdersInProgressProvider);
                    ref.invalidate(crmSentProposalsProvider);
                    ref.invalidate(crmOwnOrdersInProgressProvider);
                    ref.invalidate(crmOwnSentProposalsProvider);
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  '+ Revisão',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrmDashboardStyles.menuGrey,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );

        final right = Wrap(
          spacing: 14,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            _ActionButton(
              label: 'Adicionar Cliente',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () async {
                final res = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AddCustomerDialog(
                    useCurrentCommercialOnly: useCurrentCommercialOnly,
                  ),
                );

                if (res != null) {
                  debugPrint('Cliente: ${res.customerName} | VAT: ${res.vatNumber}');
                  debugPrint('Contactos: ${res.contacts.length}');
                }
              },
            ),
            _ActionButton(
              label: 'Ver Clientes',
              icon: Icons.visibility_outlined,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ViewCustomersDialog(
                    useCurrentCommercialOnly: useCurrentCommercialOnly,
                  ),
                );
              },
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: right,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            right,
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: CrmDashboardStyles.menuGrey,
          foregroundColor: CrmDashboardStyles.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: CrmDashboardStyles.borderSoft,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
