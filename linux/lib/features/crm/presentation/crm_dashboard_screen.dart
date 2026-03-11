import 'package:flutter/material.dart';
import 'dialogs/add_customer_dialog.dart';
import 'dialogs/view_customers_dialog.dart';
import 'package:erp_app/features/admin/presentation/dialogs/manage_comercials_dialog.dart';
import 'dialogs/insert_order_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dialogs/insert_revision_dialog.dart';
import 'dialogs/send_proposal_dialog.dart';

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1150; // ajusta este valor se precisares

              // ESQUERDA (os teus 3 botões)
              final left = Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  // INSERIR PEDIDO
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

                  // INSERIR REVISÃO
                                    SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const InsertRevisionDialog(),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        "+ Revisão",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7E7E7),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // VER TODOS OS PEDIDOS
                  SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        debugPrint("Ver todos os pedidos");
                      },
                      icon: const Icon(Icons.list_alt_outlined, size: 18),
                      label: const Text(
                        "Ver Todos os Pedidos",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7E7E7),
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

              // DIREITA (os teus 3 _ActionButton)
              final right = Wrap(
                spacing: 14,
                runSpacing: 10,
                alignment: WrapAlignment.end,
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
                ],
              );

              // Layout responsivo:
              // - Largo: esquerda e direita na mesma linha
              // - Estreito: esquerda em cima, direita em baixo alinhada à direita
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

          SizedBox(height: 16),

          Expanded(
            child: _OrdersInProgressPanel(),
          ),

          SizedBox(height: 16),

          Expanded(
            child: _OrdersSentPanel(),
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
    this.child,
    this.actions,
  });

  final String title;
  final String placeholder;
  final Widget? child;
  final List<Widget>? actions;

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: CrmDashboardScreen.textDark,
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
          const Divider(height: 1, color: CrmDashboardScreen.dividerSoft),

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

class _OrdersInAnalysisList extends StatelessWidget {
  const _OrdersInAnalysisList();

  // ⚠️ Ajusta este valor se o enum na BD NÃO guardar "Em análise" exatamente assim.
  static const String _statusValue = 'Em análise';

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final supabase = Supabase.instance.client;

    final res = await supabase
        .from('orders')
        // Vai buscar o nome do customer via FK orders.customer_id -> customers.id
        .select('order_ref, created_at, customers(name)')
        .eq('status', _statusValue)
        .order('created_at', ascending: false)
        .limit(50);

    return (res as List).cast<Map<String, dynamic>>();
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Erro ao carregar pedidos: ${snapshot.error}',
              style: const TextStyle(color: Colors.black54),
            ),
          );
        }

        final data = snapshot.data ?? const [];
        if (data.isEmpty) {
          return const Center(
            child: Text(
              'Sem pedidos "Em análise".',
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
              onTap: () {
                // se quiseres abrir o pedido aqui, é só navegares com o id
                // (nota: neste select não pedi o id, mas podes acrescentar facilmente)
              },
            );
          },
        );
      },
    );
  }
}
class _OrdersInProgressPanel extends StatefulWidget {
  const _OrdersInProgressPanel();

  @override
  State<_OrdersInProgressPanel> createState() => _OrdersInProgressPanelState();
}

class _OrdersInProgressPanelState extends State<_OrdersInProgressPanel> {
  final _sb = Supabase.instance.client;

  String? _commercialFilter; // user_id (uuid) ou null = todos

  late Future<void> _boot;
  List<Map<String, dynamic>> _commercials = [];

  @override
  void initState() {
    super.initState();
    _boot = _loadFilters();
  }

    Future<void> _loadFilters() async {
    await Future.wait([
      _loadCommercialsOnly(),
      _loadCommercialWorkflowPhases(),
    ]);
  }

    Future<void> _loadCommercialsOnly() async {
    final res = await _sb
        .from('profiles')
        .select('''
          user_id,
          full_name,
          is_active,
          profile_roles!inner(
            roles!inner(code)
          )
        ''')
        .eq('is_active', true)
        .eq('profile_roles.roles.code', 'COMERCIAL')
        .order('full_name', ascending: true);

    _commercials = (res as List).cast<Map<String, dynamic>>();
  }

    int? _commercialPhaseFilter; // workflow_phases.id ou null
    List<Map<String, dynamic>> _commercialPhases = [];

    Future<void> _loadCommercialWorkflowPhases() async {
      final res = await _sb
          .from('workflow_phases')
          .select('id, name, code, sort_order, is_active, department_code')
          .eq('department_code', 'COM')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      _commercialPhases = (res as List).cast<Map<String, dynamic>>();
    }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
   
   final concluidoPhaseId = _commercialPhases
      .where((p) => (p['code'] ?? '').toString() == 'concluido')
      .map((p) => (p['id'] as num).toInt())
      .cast<int?>()
      .firstOrNull;

  final enviadoPhaseId = _commercialPhases
      .where((p) => (p['code'] ?? '').toString() == 'enviado')
      .map((p) => (p['id'] as num).toInt())
      .cast<int?>()
      .firstOrNull;

  var q = _sb.from('orders').select('''
      id,
      order_ref,
      created_at,
      customers(name),
      commercial_user_id,

      commercial_phase_id,
      budgeting_phase_id,

      commercial_phase:workflow_phases!fk_orders_commercial_phase(id,name),
      budgeting_phase:workflow_phases!fk_orders_budgeting_phase(id,name),

      versions:order_versions!order_revisions_order_id_fkey(
        id,
        revision_ref,
        created_at,
        assignments:order_budget_assignments(
          is_active,
          assignee:profiles!order_budget_assignments_assignee_user_id_fkey(full_name)
        )
      )
    
    ''');

  if (_commercialPhaseFilter == null) {
    if (concluidoPhaseId != null) {
      q = q.neq('commercial_phase_id', concluidoPhaseId);
    }
    if (enviadoPhaseId != null) {
      q = q.neq('commercial_phase_id', enviadoPhaseId);
    }
  }

  if (_commercialFilter != null && _commercialFilter!.isNotEmpty) {
    q = q.eq('commercial_user_id', _commercialFilter!);
  }

  if (_commercialPhaseFilter != null) {
    q = q.eq('commercial_phase_id', _commercialPhaseFilter!);
  }

  final res = await q.order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, bootSnap) {
        if (bootSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (bootSnap.hasError) {
          return _Panel(
            title: "Pedidos em curso",
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Erro a carregar comerciais: ${bootSnap.error}'),
            ),
          );
        }

        return _Panel(
          title: "Pedidos em curso",
          actions: [
            // Filtro Comercial
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                value: _commercialFilter,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: 'Comercial',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Todos',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._commercials.map((c) {
                    return DropdownMenuItem<String?>(
                      value: (c['user_id'] ?? '').toString(),
                      child: Text(
                        (c['full_name'] ?? '').toString(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _commercialFilter = value;
                  });
                },
              )
            ),
            const SizedBox(width: 8),

            // Filtro Estado
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                value: _commercialPhaseFilter,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: 'Estado',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos', overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  ..._commercialPhases.map((p) {
                    final id = p['id'] as int?;
                    final name = (p['name'] ?? '').toString();
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _commercialPhaseFilter = v),
              ),
            ),
          ],
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchOrders(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Erro a carregar pedidos: ${snap.error}'),
                );
              }

              final rows = snap.data ?? const [];
              if (rows.isEmpty) {
                return const Center(child: Text('Sem pedidos para os filtros atuais.'));
              }

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Header "tabela"
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 18, child: Text('Ref', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(flex: 28, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(flex: 18, child: Text('Estado Comercial', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(flex: 18, child: Text('Estado Orçamentação', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(flex: 18, child: Text('Orçamentista', style: TextStyle(fontWeight: FontWeight.w700))),
                          SizedBox(width: 44),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = rows[i];

                                                    String ref = (r['order_ref'] ?? '').toString();

                          final orderVersions = r['versions'] is List
                              ? List<dynamic>.from(r['versions'] as List)
                              : <dynamic>[];

                          Map<String, dynamic>? latestVersion;

                          for (final v in orderVersions) {
                            if (v is! Map) continue;

                            final versionMap = Map<String, dynamic>.from(v);

                            if (latestVersion == null) {
                              latestVersion = versionMap;
                              continue;
                            }

                            final currentCreatedAt = DateTime.tryParse(
                              (versionMap['created_at'] ?? '').toString(),
                            );
                            final latestCreatedAt = DateTime.tryParse(
                              (latestVersion['created_at'] ?? '').toString(),
                            );

                            if (currentCreatedAt != null &&
                                (latestCreatedAt == null ||
                                    currentCreatedAt.isAfter(latestCreatedAt))) {
                              latestVersion = versionMap;
                            }
                          }

                          final latestRevisionRef =
                              (latestVersion?['revision_ref'] ?? '').toString().trim();

                          if (latestRevisionRef.isNotEmpty) {
                            ref = latestRevisionRef;
                          }

                          final customer =
                              (r['customers'] is Map ? r['customers']['name'] : null)?.toString() ?? '';

                          final comPhase =
                              (r['commercial_phase'] is Map ? r['commercial_phase']['name'] : null)?.toString() ?? '';
                          final budPhase =
                              (r['budgeting_phase'] is Map ? r['budgeting_phase']['name'] : null)?.toString() ?? '';

                          // Orçamentista responsável: 1º assignment ativo (se houver)
                          String budgeter = '-';

                          List<dynamic> assigns = <dynamic>[];
                          for (final v in orderVersions) {
                            if (v is Map && v['assignments'] is List) {
                              assigns = List<dynamic>.from(v['assignments'] as List);
                              break;
                            }
                          }
                          for (final a in assigns) {
                            if (a is Map && a['is_active'] == true) {
                              final name = (a['assignee'] is Map ? a['assignee']['full_name'] : null)?.toString();
                              if (name != null && name.trim().isNotEmpty) {
                                budgeter = name;
                                break;
                              }
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 18,
                                  child: Text(ref,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                Expanded(
                                  flex: 28,
                                  child: Text(customer, overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 18,
                                  child: Text(comPhase.isEmpty ? '-' : comPhase, overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 18,
                                  child: Text(budPhase.isEmpty ? '-' : budPhase, overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 18,
                                  child: Text(budgeter, overflow: TextOverflow.ellipsis),
                                ),
                                Row(
                                  children: [

                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      tooltip: 'Alterar Estado',
                                      onPressed: () => _openEditOrderDialog(context, r),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.send_rounded, size: 18),
                                      tooltip: 'Enviar Proposta',
                                      onPressed: () => _openSendProposalDialog(context, r),
                                    ),

                                  ],
                                )
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
      },
    );
  }
  Future<void> _openEditOrderDialog(BuildContext context, Map<String, dynamic> r) async {
    final orderId = r['id'];

    int? comId = (r['commercial_phase_id'] as num?)?.toInt();
    
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar pedido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                value: comId,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'Estado Comercial',
                ),
                items: _commercialPhases
                    .where((p) {
                      final code = (p['code'] ?? '').toString().toLowerCase();
                      return code != 'enviado' && code != 'concluido';
                    })
                    .map((p) {
                      final id = (p['id'] as num).toInt();
                      final name = (p['name'] ?? '').toString();
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                onChanged: (v) => comId = v,
              ),
              
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
          ],
        );
      },
    );

    if (saved != true) return;
    if (comId == null) return;

    await _sb.rpc(
      'set_order_commercial_phase',
      params: {
        'p_order_id': orderId,
        'p_commercial_phase_id': comId,
      },
    );

    setState(() {});
  }

}

class _OrdersSentPanel extends StatefulWidget {
  const _OrdersSentPanel();

  @override
  State<_OrdersSentPanel> createState() => _OrdersSentPanelState();
}

class _OrdersSentPanelState extends State<_OrdersSentPanel> {
  final _sb = Supabase.instance.client;

  int? _sentPhaseId;
  int? _concludedPhaseId;

  Future<void> _loadPhaseIds() async {
    final res = await _sb
        .from('workflow_phases')
        .select('id, code')
        .eq('department_code', 'COM')
        .inFilter('code', ['enviado', 'concluido']);

    final rows = (res as List).cast<Map<String, dynamic>>();

    for (final row in rows) {
      final code = (row['code'] ?? '').toString();
      final id = (row['id'] as num).toInt();

      if (code == 'enviado') _sentPhaseId = id;
      if (code == 'concluido') _concludedPhaseId = id;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSentOrders() async {
    await _loadPhaseIds();

    if (_sentPhaseId == null) {
      return <Map<String, dynamic>>[];
    }

    final res = await _sb
        .from('orders')
        .select('''
          id,
          order_ref,
          customer_id,
          commercial_phase_id,
          customers(name),
          versions:order_versions!order_revisions_order_id_fkey(
            id,
            revision_ref,
            created_at,
            proposals(
              id,
              sent_at,
              feedback_at,
              valid_until
            )
          )
        ''')
        .eq('commercial_phase_id', _sentPhaseId!)
        .order('created_at', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
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
      bgColor = isExpiry
          ? const Color(0xFFF4C7C3) // vermelho suave
          : const Color(0xFFFFE0B2); // laranja suave
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

  Future<void> _markAsConcluded(String orderId) async {
    if (_concludedPhaseId == null) return;

    await _sb.rpc(
      'set_order_commercial_phase',
      params: {
        'p_order_id': orderId,
        'p_commercial_phase_id': _concludedPhaseId,
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Propostas Enviadas',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSentOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Erro a carregar propostas enviadas: ${snap.error}'),
            );
          }

          final rows = snap.data ?? const [];
          if (rows.isEmpty) {
            return const Center(
              child: Text('Sem propostas enviadas.'),
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
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = rows[i];

                      String ref = (r['order_ref'] ?? '').toString();
                      final customer =
                          (r['customers'] is Map ? r['customers']['name'] : null)?.toString() ?? '';

                      final orderVersions = r['versions'] is List
                          ? List<dynamic>.from(r['versions'] as List)
                          : <dynamic>[];

                      Map<String, dynamic>? latestVersion;

                      for (final v in orderVersions) {
                        if (v is! Map) continue;

                        final versionMap = Map<String, dynamic>.from(v);

                        if (latestVersion == null) {
                          latestVersion = versionMap;
                          continue;
                        }

                        final currentCreatedAt = DateTime.tryParse(
                          (versionMap['created_at'] ?? '').toString(),
                        );
                        final latestCreatedAt = DateTime.tryParse(
                          (latestVersion['created_at'] ?? '').toString(),
                        );

                        if (currentCreatedAt != null &&
                            (latestCreatedAt == null ||
                                currentCreatedAt.isAfter(latestCreatedAt))) {
                          latestVersion = versionMap;
                        }
                      }

                      final latestRevisionRef =
                          (latestVersion?['revision_ref'] ?? '').toString().trim();

                      if (latestRevisionRef.isNotEmpty) {
                        ref = latestRevisionRef;
                      }

                      Map<String, dynamic>? latestProposal;
                      final proposalsRaw = latestVersion?['proposals'];

                      if (proposalsRaw is List && proposalsRaw.isNotEmpty) {
                        for (final p in proposalsRaw) {
                          if (p is! Map) continue;

                          final proposalMap = Map<String, dynamic>.from(p);

                          if (latestProposal == null) {
                            latestProposal = proposalMap;
                            continue;
                          }

                          final currentSentAt = DateTime.tryParse(
                            (proposalMap['sent_at'] ?? '').toString(),
                          );
                          final latestSentAt = DateTime.tryParse(
                            (latestProposal['sent_at'] ?? '').toString(),
                          );

                          if (currentSentAt != null &&
                              (latestSentAt == null || currentSentAt.isAfter(latestSentAt))) {
                            latestProposal = proposalMap;
                          }
                        }
                      }

                      final sentAt = _fmtDate(latestProposal?['sent_at']);
                      final feedbackAt = _fmtDate(latestProposal?['feedback_at']);
                      final validUntil = _fmtDate(latestProposal?['valid_until']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 18,
                              child: Text(
                                ref,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              flex: 24,
                              child: Text(customer, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 14,
                              child: Text(sentAt, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 16,
                              child: _buildDateStatusCell(
                                latestProposal?['feedback_at'],
                                isExpiry: false,
                              ),
                            ),
                            Expanded(
                              flex: 18,
                              child: _buildDateStatusCell(
                                latestProposal?['valid_until'],
                                isExpiry: true,
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Editar',
                                onPressed: () => _markAsConcluded(r['id'].toString()),
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
Future<void> _openSendProposalDialog(
  BuildContext context,
  Map<String, dynamic> order,
) async {
  final orderVersions = order['versions'] is List
      ? List<dynamic>.from(order['versions'] as List)
      : <dynamic>[];

  Map<String, dynamic>? latestVersion;

  for (final v in orderVersions) {
    if (v is! Map) continue;

    final versionMap = Map<String, dynamic>.from(v);

    if (latestVersion == null) {
      latestVersion = versionMap;
      continue;
    }

    final currentCreatedAt = DateTime.tryParse(
      (versionMap['created_at'] ?? '').toString(),
    );
    final latestCreatedAt = DateTime.tryParse(
      (latestVersion['created_at'] ?? '').toString(),
    );

    if (currentCreatedAt != null &&
        (latestCreatedAt == null || currentCreatedAt.isAfter(latestCreatedAt))) {
      latestVersion = versionMap;
    }
  }

  final proposalsRaw = latestVersion?['proposals'];

  Map<String, dynamic>? latestProposal;
  if (proposalsRaw is List) {
    for (final p in proposalsRaw) {
      if (p is! Map) continue;
      latestProposal = Map<String, dynamic>.from(p);
      break;
    }
  }

  final proposalId = (latestProposal?['id'] ?? 'TEMP_PLACEHOLDER').toString();
  final orderRef = (latestVersion?['revision_ref'] ?? order['order_ref'] ?? '').toString();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SendProposalDialog(
      orderRef: orderRef,
      proposalId: proposalId,
    ),
  );

  if (result == null) return;

  debugPrint('Enviar proposta payload: $result');
}