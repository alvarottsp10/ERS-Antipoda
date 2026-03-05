import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dialog/assign_budgeter_dialog.dart';

class BudgetDashboardScreen extends StatelessWidget {
  const BudgetDashboardScreen({super.key});

  static const Color menuGrey = Color(0xFFE7E7E7);
  static const Color borderSoft = Color(0xFFC9C9C9);
  static const Color dividerSoft = Color(0xFFD6D6D6);
  static const Color textDark = Color(0xFF151515);

  static const int initialBudgetingPhaseId = 7;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1150;

              final left = Wrap(
                spacing: 14,
                runSpacing: 10,
                children: const [],
              );

              final right = Wrap(
                spacing: 14,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  _ActionButton(
                    label: 'Adicionar Fornecedor',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const _AddSupplierPlaceholderDialog(),
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
          ),
          const SizedBox(height: 16),

          // Linha de cima: Novos Pedidos (pequeno) + Os meus orçamentos (maior)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1150;

                final newOrders = _NewOrdersPanel(
                  initialBudgetingPhaseId: initialBudgetingPhaseId,
                );

                final myBudgets = const _MyBudgetsPanel();

                if (isNarrow) {
                  return Column(
                    children: [
                      Expanded(child: newOrders),
                      const SizedBox(height: 16),
                      Expanded(child: myBudgets),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: newOrders),
                    const SizedBox(width: 16),
                    Expanded(flex: 9, child: myBudgets),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          const Expanded(
            child: _Panel(
              title: 'Métricas',
              placeholder: 'Placeholder para métricas (KPIs, tempos, etc.)',
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
          backgroundColor: BudgetDashboardScreen.menuGrey,
          foregroundColor: BudgetDashboardScreen.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: BudgetDashboardScreen.borderSoft,
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
    this.child,
    this.actions,
    this.placeholder = 'Placeholder',
  });

  final String title;
  final String placeholder;
  final Widget? child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BudgetDashboardScreen.menuGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BudgetDashboardScreen.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: BudgetDashboardScreen.textDark,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actions != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actions!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: BudgetDashboardScreen.dividerSoft),
          Expanded(
            child: child ??
                Center(
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

class _NewOrdersPanel extends StatelessWidget {
  const _NewOrdersPanel({required this.initialBudgetingPhaseId});

  final int initialBudgetingPhaseId;

  Future<List<Map<String, dynamic>>> _fetchNewOrders() async {
    final sb = Supabase.instance.client;

    final res = await sb
        .from('orders')
        .select('''
          id,
          order_ref,
          created_at,
          customers(name),
          budgeting_phase:workflow_phases!fk_orders_budgeting_phase(id,name),
          assignments:order_budget_assignments!order_budget_assignments_order_id_fkey(
            is_active,
            assignee_user_id,
            assignee:profiles!order_budget_assignments_assignee_user_id_fkey(full_name)
          )
        ''')
        .eq('budgeting_phase_id', initialBudgetingPhaseId)
        .order('created_at', ascending: false)
        .limit(100);

    final rows = (res as List).cast<Map<String, dynamic>>();

    bool hasActiveAssignment(Map<String, dynamic> row) {
      final assignments = row['assignments'];
      if (assignments is! List) return false;
      for (final a in assignments) {
        if (a is Map && a['is_active'] == true) return true;
      }
      return false;
    }

    return rows.where((r) => !hasActiveAssignment(r)).toList(growable: false);
  }

  String _fmtDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Novos Pedidos',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNewOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Erro ao carregar novos pedidos: ${snapshot.error}',
                style: const TextStyle(color: Colors.black54),
              ),
            );
          }

          final data = snapshot.data ?? const [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Sem novos pedidos por atribuir.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final row = data[i];
              final orderId = row['id'];
              final orderRef = (row['order_ref'] ?? '').toString();
              final customerName =
                  (row['customers'] is Map ? row['customers']['name'] : null)?.toString() ?? '';
              final createdAt = _fmtDate(row['created_at']);

              return ListTile(
                dense: true,
                title: Text(
                  orderRef.isEmpty ? '(sem referência)' : orderRef,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${customerName.isEmpty ? '(sem cliente)' : customerName}\n$createdAt',
                  style: const TextStyle(color: Colors.black54),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AssignBudgeterDialog(
                      orderId: orderId.toString(),
                      orderRef: orderRef,
                      customerName: customerName,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MyBudgetsPanel extends StatelessWidget {
  const _MyBudgetsPanel();

  Future<List<Map<String, dynamic>>> _fetchMyBudgets() async {
    final sb = Supabase.instance.client;
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return const [];

    bool isMine(Map<String, dynamic> row) {
      final assignments = row['assignments'];
      if (assignments is! List) return false;
      for (final a in assignments) {
        if (a is Map &&
            a['is_active'] == true &&
            a['assignee_user_id']?.toString() == userId) {
          return true;
        }
      }
      return false;
    }

    // 1) Buscar orders + assignments (com IDs)
    final res = await sb
        .from('orders')
        .select('''
          id,
          order_ref,
          created_at,
          budgeting_phase_id,
          customers(name),
          budgeting_phase:workflow_phases!fk_orders_budgeting_phase(id,name),
          assignments:order_budget_assignments!order_budget_assignments_order_id_fkey(
            is_active,
            assignee_user_id,
            is_special,
            budget_typology_id,
            product_type_id
          )
        ''')
        .eq('assignments.is_active', true)
        .eq('assignments.assignee_user_id', userId)
        .order('created_at', ascending: false)
        .limit(200);

    final rows = (res as List).cast<Map<String, dynamic>>();
    final mine = rows.where(isMine).toList(growable: false);

    // 2) Recolher IDs tipologia/produtos do assignment ativo
    final Set<int> typologyIds = {};
    final Set<int> productTypeIds = {};

    for (final r in mine) {
      final assigns = r['assignments'];
      if (assigns is! List) continue;

      for (final a in assigns) {
        if (a is Map && a['is_active'] == true) {
          final tId = (a['budget_typology_id'] as num?)?.toInt();
          final pId = (a['product_type_id'] as num?)?.toInt();
          if (tId != null) typologyIds.add(tId);
          if (pId != null) productTypeIds.add(pId);
          break;
        }
      }
    }

    // 3) Buscar nomes
    final Map<int, String> typologyNameById = {};
    if (typologyIds.isNotEmpty) {
      final typRes = await sb
          .from('budget_typologies')
          .select('id, name')
          .inFilter('id', typologyIds.toList());
      for (final t in (typRes as List)) {
        if (t is Map) {
          final id = (t['id'] as num?)?.toInt();
          final name = (t['name'] ?? '').toString();
          if (id != null) typologyNameById[id] = name;
        }
      }
    }

    final Map<int, String> productTypeNameById = {};
    if (productTypeIds.isNotEmpty) {
      final prodRes = await sb
          .from('product_types')
          .select('id, name')
          .inFilter('id', productTypeIds.toList());
      for (final p in (prodRes as List)) {
        if (p is Map) {
          final id = (p['id'] as num?)?.toInt();
          final name = (p['name'] ?? '').toString();
          if (id != null) productTypeNameById[id] = name;
        }
      }
    }

    // 4) Enriquecer assignment ativo com nomes
    for (final r in mine) {
      final assigns = r['assignments'];
      if (assigns is! List) continue;

      for (final a in assigns) {
        if (a is Map && a['is_active'] == true) {
          final tId = (a['budget_typology_id'] as num?)?.toInt();
          final pId = (a['product_type_id'] as num?)?.toInt();
          a['budget_typology_name'] = tId == null ? null : typologyNameById[tId];
          a['product_type_name'] = pId == null ? null : productTypeNameById[pId];
          break;
        }
      }
    }

    return mine;
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Os meus orçamentos',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyBudgets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Erro ao carregar os meus orçamentos: ${snapshot.error}',
                style: const TextStyle(color: Colors.black54),
              ),
            );
          }

          final data = snapshot.data ?? const [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Sem orçamentos atribuídos.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 16, child: Text('Orçamento', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 24, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 18, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 16, child: Text('Tipologia', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 14, child: Text('Produtos', style: TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 10, child: Text('Especial', style: TextStyle(fontWeight: FontWeight.w700))),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final row = data[i];

                      final orderId = row['id'];
                      final orderRef = (row['order_ref'] ?? '').toString();
                      final customerName =
                          (row['customers'] is Map ? row['customers']['name'] : null)?.toString() ?? '';
                      final phaseName =
                          (row['budgeting_phase'] is Map ? row['budgeting_phase']['name'] : null)?.toString() ?? '';

                      // assignment ativo
                      String typologyName = '';
                      String productTypeName = '';
                      bool isSpecial = false;

                      final assignments = row['assignments'];
                      if (assignments is List) {
                        for (final a in assignments) {
                          if (a is Map && a['is_active'] == true) {
                            typologyName = (a['budget_typology_name'] ?? '').toString();
                            productTypeName = (a['product_type_name'] ?? '').toString();
                            isSpecial = a['is_special'] == true;
                            break;
                          }
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 16,
                              child: Text(
                                orderRef.isEmpty ? '-' : orderRef,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              flex: 24,
                              child: Text(customerName.isEmpty ? '-' : customerName, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 18,
                              child: Text(phaseName.isEmpty ? '-' : phaseName, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 16,
                              child: Text(
                                typologyName.isEmpty ? '-' : typologyName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 14,
                              child: Text(
                                productTypeName.isEmpty ? '-' : productTypeName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Text(isSpecial ? 'Sim' : 'Não', overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 44,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Editar',
                                onPressed: () {
                                  debugPrint('Editar orçamento: $orderId');
                                },
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
}

class _AddSupplierPlaceholderDialog extends StatelessWidget {
  const _AddSupplierPlaceholderDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Fornecedor'),
      content: const Text(
        'Ainda não existe tabela/fluxo de fornecedores no Supabase.\n\n'
        'Cria a tabela (ex.: suppliers/vendors) e depois ligamos aqui o formulário + insert.',
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