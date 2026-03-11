import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_proposal_dialog.dart';

class EditBudgetDialog extends StatefulWidget {
  const EditBudgetDialog({
    super.key,
    required this.orderId,
    required this.orderRef,
    required this.customerName,
    required this.currentBudgetingPhaseId,
    required this.currentBudgetingPhaseName,
    required this.currentTypologyId,
    required this.currentTypologyName,
    required this.currentProductTypeId,
    required this.currentProductTypeName,
    required this.currentIsSpecial,
  });

  final String orderId; // uuid
  final String orderRef;
  final String customerName;

  final int? currentBudgetingPhaseId;
  final String currentBudgetingPhaseName;

  final int? currentTypologyId;
  final String currentTypologyName;

  final int? currentProductTypeId;
  final String currentProductTypeName;

  final bool currentIsSpecial;

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final _sb = Supabase.instance.client;

  late Future<void> _boot;

  List<Map<String, dynamic>> _budgetingPhases = [];
  List<Map<String, dynamic>> _typologies = [];
  List<Map<String, dynamic>> _productTypes = [];
  List<Map<String, dynamic>> _proposals = [];

  int? _selectedBudgetingPhaseId;
  int? _selectedTypologyId;
  int? _selectedProductTypeId;
  bool _isSpecial = false;

  String? _selectedProposalId; // proposals.id (uuid)

  bool _saving = false;

  // Valores vindos do Excel (para preview + fecho)
  String? _proposalFileName;
  double? _proposalTotalMaterial;
  double? _proposalTotalMO;
  double? _proposalTotalProjeto;
  double? _proposalTotalVenda;
  double? _proposalMargemPct; // 0..1

  @override
  void initState() {
    super.initState();

    _selectedBudgetingPhaseId = widget.currentBudgetingPhaseId;
    _selectedTypologyId = widget.currentTypologyId;
    _selectedProductTypeId = widget.currentProductTypeId;
    _isSpecial = widget.currentIsSpecial;

    _boot = _loadAll();
  }

    Future<void> _loadAll() async {
    await Future.wait([
      _loadBudgetingPhases(),
      _loadTypologies(),
      _loadProductTypes(),
      _loadProposals(),
    ]);
  }

  Future<void> _loadBudgetingPhases() async {
    // NOTA: sem assumir “departamento ORC”/filtros — apenas lista simples.
    final res = await _sb
        .from('workflow_phases')
        .select('id, name')
        .order('id', ascending: true);

    _budgetingPhases = (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _loadTypologies() async {
    final res = await _sb
        .from('budget_typologies')
        .select('id, name, sort_order, is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    _typologies = (res as List).cast<Map<String, dynamic>>();
  }

    Future<void> _loadProductTypes() async {
    final res = await _sb
        .from('product_types')
        .select('id, name, sort_order, is_active')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    _productTypes = (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _loadProposals() async {
    // proposals -> order_revisions (para filtrar por order_id)
    final res = await _sb
        .from('proposals')
        .select('''
          id,
          title,
          created_at,
          order_revision:order_revisions!inner(
            order_id,
            revision_ref
          )
        ''')
        .eq('order_revision.order_id', widget.orderId)
        .order('created_at', ascending: false)
        .limit(200);

    _proposals = (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _savePlaceholder() async {
    // Regra do projeto: escrita SEMPRE via SP/RPC
    if (_selectedTypologyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona uma tipologia.')),
      );
      return;
    }
    if (_selectedBudgetingPhaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um estado de orçamentação.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _sb.rpc(
        'update_order_budget_details',
        params: {
          'p_order_id': widget.orderId,
          'p_budgeting_phase_id': _selectedBudgetingPhaseId,
          'p_budget_typology_id': _selectedTypologyId,
          // pode ser null (SP aceita bigint NULL)
          'p_product_type_id': _selectedProductTypeId,
          'p_is_special': _isSpecial,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;

        return AlertDialog(
          backgroundColor: const Color(0xFFE7E7E7),
          surfaceTintColor: Colors.transparent,
          title: const Text('Editar orçamento'),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.orderRef.isEmpty ? '(sem referência)' : widget.orderRef,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customerName.isEmpty ? '(sem cliente)' : widget.customerName,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    value: _selectedBudgetingPhaseId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Estado Orçamentação',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Selecionar...'),
                      ),
                      ..._budgetingPhases.map((p) {
                        final id = (p['id'] as num?)?.toInt();
                        final name = (p['name'] ?? '').toString();
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _selectedBudgetingPhaseId = v),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    value: _selectedTypologyId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Tipologia',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Selecionar...'),
                      ),
                      ..._typologies.map((t) {
                        final id = (t['id'] as num?)?.toInt();
                        final name = (t['name'] ?? '').toString();
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _selectedTypologyId = v),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    value: _selectedProductTypeId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Produtos (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      ..._productTypes.map((t) {
                        final id = (t['id'] as num?)?.toInt();
                        final name = (t['name'] ?? '').toString();
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _selectedProductTypeId = v),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isSpecial,
                    onChanged: _saving ? null : (v) => setState(() => _isSpecial = v),
                    title: const Text('Especial'),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _saving
                        ? null
                        : () async {
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => UploadProposalDialog(
                                orderId: widget.orderId,
                                orderRef: widget.orderRef,
                              ),
                            );

                            if (result == null) return;

                            setState(() {
                              _proposalFileName = (result['file_name'] ?? '').toString();
                              _proposalTotalMaterial = (result['total_material'] as num?)?.toDouble();
                              _proposalTotalMO = (result['total_mo'] as num?)?.toDouble();
                              _proposalTotalProjeto = (result['total_projeto'] as num?)?.toDouble();
                              _proposalTotalVenda = (result['total_venda'] as num?)?.toDouble();
                              _proposalMargemPct = (result['margem_pct'] as num?)?.toDouble();
                            });
                          },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Carregar proposta (Excel)'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC9C9C9)),
                    ),
                    child: (_proposalMargemPct == null)
                        ? const Text(
                            'Depois de carregar o Excel, aqui aparecem os valores para fechar o orçamento.',
                            style: TextStyle(color: Colors.black54, fontSize: 12.5),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_proposalFileName == null || _proposalFileName!.isEmpty)
                                    ? 'Proposta (Excel)'
                                    : 'Proposta: $_proposalFileName',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text('TOTAL MATERIAL: ${_proposalTotalMaterial?.toStringAsFixed(2)}'),
                              Text('TOTAL M.O.: ${_proposalTotalMO?.toStringAsFixed(2)}'),
                              Text('TOTAL PROJETO: ${_proposalTotalProjeto?.toStringAsFixed(2)}'),
                              Text('VALOR VENDA: ${_proposalTotalVenda?.toStringAsFixed(2)}'),
                              const SizedBox(height: 6),
                              Text(
                                'MARGEM (%): ${(100 * (_proposalMargemPct ?? 0)).toStringAsFixed(2)}%',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: (loading || _saving || _proposalMargemPct == null)
                  ? null
                  : () {
                      // Placeholder: no próximo passo chama RPC para fechar
                      debugPrint('Fechar orçamento ${widget.orderId} com excel totals');
                    },
              child: const Text('Fechar orçamento'),
            ),
            ElevatedButton(
              onPressed: (loading || _saving) ? null : _savePlaceholder,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}