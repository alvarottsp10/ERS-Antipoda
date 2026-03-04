import 'package:flutter/material.dart';
import 'dialogs/add_customer_dialog.dart';
import 'dialogs/view_customers_dialog.dart';
import 'package:erp_app/features/admin/presentation/dialogs/manage_comercials_dialog.dart';
import 'dialogs/insert_order_dialog.dart';

class CrmDashboardScreen extends StatelessWidget {
  const CrmDashboardScreen({super.key});

  // Cores “corporate” alinhadas com a sidebar
  static const Color menuGrey = Color(0xFFE7E7E7);
  static const Color borderSoft = Color(0xFFC9C9C9);
  static const Color dividerSoft = Color(0xFFD6D6D6);
  static const Color textDark = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// ESQUERDA
              SizedBox(
                width: 200,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const InsertOrderDialog(),
                    );

                    if (res != null) {
                      debugPrint('Pedido criado: ${res['id']}  ref=${res['order_ref']}');

                      // Se já tiveres ecrã do pedido, podes navegar aqui:
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (_) => OrderScreen(orderId: res['id']),
                      // ));
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    "Inserir Pedido",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
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

              /// DIREITA
              Row(
                children: [

                  _ActionButton(
                    label: "Adicionar Cliente",
                    icon: Icons.person_add_alt_1_outlined,
                    onPressed: () async {
                      final res = await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const AddCustomerDialog(),
                      );

                      if (res != null) {
                        debugPrint("Cliente: ${res.customerName} | VAT: ${res.vatNumber}");
                        debugPrint("Contactos: ${res.contacts.length}");
                      }
                    },
                  ),

                  const SizedBox(width: 14),

                  _ActionButton(
                    label: "Ver Clientes",
                    icon: Icons.visibility_outlined,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ViewCustomersDialog(),
                      );
                    },
                  ),

                  const SizedBox(width: 14),

                  _ActionButton(
                    label: "Comerciais",
                    icon: Icons.badge_outlined,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ManageCommercialsDialog(),
                      );
                    },
                  ),

                  const SizedBox(width: 14),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          Expanded(
            child: _Panel(
              title: "Pedidos em curso",
            ),
          ),

          SizedBox(height: 16),

          Expanded(
            child: _Panel(
              title: "Leaderboard (Clientes + Comerciais)",
              placeholder: "Placeholder (PowerBI depois)",
            ),
          ),
        ],
      ),
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: CrmDashboardScreen.menuGrey,
          foregroundColor: CrmDashboardScreen.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: CrmDashboardScreen.borderSoft,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    this.placeholder = "Placeholder",
  });

  final String title;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CrmDashboardScreen.menuGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrmDashboardScreen.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: CrmDashboardScreen.textDark,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: CrmDashboardScreen.dividerSoft),
          Expanded(
            child: Center(
              child: Text(
                placeholder,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}