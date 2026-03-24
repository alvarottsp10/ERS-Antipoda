import 'package:flutter/material.dart';

import '../../data/budgeting_repository.dart';
import '../../domain/budgeting_models.dart';
import 'upload_proposal_dialog.dart';
import 'view_proposal_dialog.dart';

class EditBudgetDialog extends StatefulWidget {
  const EditBudgetDialog({
    super.key,
    required this.orderId,
    required this.latestVersionId,
    required this.orderRef,
    required this.customerName,
    required this.currentBudgetingPhaseId,
    required this.currentBudgetingPhaseName,
    required this.currentTypologyId,
    required this.currentTypologyName,
    required this.currentProductTypeId,
    required this.currentProductTypeName,
    required this.currentIsSpecial,
    required this.currentProposalId,
    required this.currentProposalSellTotal,
    required this.currentProposalCostTotal,
    this.currentProposalCostMaterialTotal,
    this.currentProposalCostLaborTotal,
    this.currentProposalCostProjectTotal,
    required this.currentProposalMarginPct,
    required this.currentProposalSentAt,
    required this.currentProposalFeedbackAt,
    required this.currentProposalValidUntil,
    this.currentProposalItems = const [],
  });

  final String orderId;
  final String latestVersionId;
  final String orderRef;
  final String customerName;
  final int? currentBudgetingPhaseId;
  final String currentBudgetingPhaseName;
  final int? currentTypologyId;
  final String currentTypologyName;
  final int? currentProductTypeId;
  final String currentProductTypeName;
  final bool currentIsSpecial;
  final String? currentProposalId;
  final double? currentProposalSellTotal;
  final double? currentProposalCostTotal;
  final double? currentProposalCostMaterialTotal;
  final double? currentProposalCostLaborTotal;
  final double? currentProposalCostProjectTotal;
  final double? currentProposalMarginPct;
  final DateTime? currentProposalSentAt;
  final DateTime? currentProposalFeedbackAt;
  final DateTime? currentProposalValidUntil;
  final List<Map<String, dynamic>> currentProposalItems;

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final _repository = BudgetingRepository();

  late Future<void> _boot;

  List<BudgetingWorkflowPhaseOption> _budgetingPhases = [];
  List<BudgetingOption> _typologies = [];
  List<BudgetingOption> _productTypes = [];

  int? _selectedBudgetingPhaseId;
  int? _selectedTypologyId;
  int? _selectedProductTypeId;
  bool _isSpecial = false;

  String? _proposalId;
  String? _proposalFileName;
  double? _proposalTotalMaterial;
  double? _proposalTotalMO;
  double? _proposalTotalProjeto;
  double? _proposalTotalVenda;
  double? _proposalMargemPct;
  DateTime? _proposalSentAt;
  DateTime? _proposalFeedbackAt;
  DateTime? _proposalValidUntil;
  List<Map<String, dynamic>> _proposalEquipmentBlocks = const [];

  bool get _hasActiveProposal => (_proposalId ?? '').trim().isNotEmpty;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedBudgetingPhaseId = widget.currentBudgetingPhaseId;
    _selectedTypologyId = widget.currentTypologyId;
    _selectedProductTypeId = widget.currentProductTypeId;
    _isSpecial = widget.currentIsSpecial;
    _proposalId = widget.currentProposalId;
    _proposalTotalVenda = widget.currentProposalSellTotal;
    _proposalTotalMaterial = widget.currentProposalCostMaterialTotal;
    _proposalTotalMO = widget.currentProposalCostLaborTotal;
    _proposalTotalProjeto = widget.currentProposalCostProjectTotal;
    _proposalEquipmentBlocks = _normalizeProposalItems(widget.currentProposalItems);
    _proposalMargemPct = widget.currentProposalMarginPct == null
        ? null
        : widget.currentProposalMarginPct! / 100;
    _proposalSentAt = widget.currentProposalSentAt;
    _proposalFeedbackAt = widget.currentProposalFeedbackAt;
    _proposalValidUntil = widget.currentProposalValidUntil;
    _boot = _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBudgetingPhases(),
      _loadTypologies(),
      _loadProductTypes(),
    ]);
  }

  Future<void> _loadBudgetingPhases() async {
    _budgetingPhases = await _repository.fetchBudgetingWorkflowPhases();
  }

  Future<void> _loadTypologies() async {
    _typologies = await _repository.fetchBudgetTypologies();
  }

  Future<void> _loadProductTypes() async {
    _productTypes = await _repository.fetchProductTypes();
  }

  Future<void> _save() async {
    if (_selectedBudgetingPhaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um estado de orcamentacao.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.updateOrderBudgetDetails(
        orderId: widget.orderId,
        orderVersionId: widget.latestVersionId,
        budgetingPhaseId: _selectedBudgetingPhaseId!,
        budgetTypologyId: _selectedTypologyId,
        productTypeId: _selectedProductTypeId,
        isSpecial: _isSpecial,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar: $error')),
      );
      setState(() => _saving = false);
    }
  }


  Future<void> _closeBudget() async {
    if (_proposalMargemPct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrega primeiro a proposta em Excel.')),
      );
      return;
    }

    final pendingCommercialPhase = _budgetingPhases.where(
      (item) => item.sortOrder == 6,
    );
    if (pendingCommercialPhase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado de validacao comercial nao encontrado.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Fechar orcamento'),
          content: const Text(
            'Queres enviar este orcamento para validacao comercial?',
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

    final targetPhase = pendingCommercialPhase.first;
    setState(() => _saving = true);

    try {
      await _repository.updateOrderBudgetDetails(
        orderId: widget.orderId,
        orderVersionId: widget.latestVersionId,
        budgetingPhaseId: targetPhase.id,
        budgetTypologyId: _selectedTypologyId,
        productTypeId: _selectedProductTypeId,
        isSpecial: _isSpecial,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fechar orcamento: $error')),
      );
      setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  Future<void> _openProposalDetails() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ViewProposalDialog(
        proposalFileName: _proposalFileName,
        proposalTotalMaterial: _proposalTotalMaterial,
        proposalTotalMO: _proposalTotalMO,
        proposalTotalProjeto: _proposalTotalProjeto,
        proposalTotalVenda: _proposalTotalVenda,
        proposalMargemPct: _proposalMargemPct,
        proposalEquipmentBlocks: _proposalEquipmentBlocks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return AlertDialog(
          backgroundColor: const Color(0xFFE7E7E7),
          surfaceTintColor: Colors.transparent,
          title: const Text('Editar orcamento'),
          content: SizedBox(
            width: _hasActiveProposal ? 700 : 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.orderRef.isEmpty ? '(sem referencia)' : widget.orderRef,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customerName.isEmpty
                      ? '(sem cliente)'
                      : widget.customerName,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                if (isLoading)
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
                      labelText: 'Estado Orcamentacao',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Selecionar...'),
                      ),
                      ..._budgetingPhases.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _selectedBudgetingPhaseId = value),
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
                      ..._typologies.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _selectedTypologyId = value),
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
                        child: Text('-'),
                      ),
                      ..._productTypes.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _selectedProductTypeId = value),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isSpecial,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isSpecial = value),
                    title: const Text('Especial'),
                  ),
                  const SizedBox(height: 10),
                  if (_hasActiveProposal) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openProposalDetails,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC9C9C9)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6E9D7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Proposta ativa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF235B2A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (_proposalFileName == null ||
                                        _proposalFileName!.isEmpty)
                                    ? 'Abrir detalhe da proposta'
                                    : _proposalFileName!,
                                style: const TextStyle(color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
                                  orderVersionId: widget.latestVersionId,
                                  orderRef: widget.orderRef,
                                ),
                              );

                              if (result == null) {
                                return;
                              }

                              setState(() {
                                _proposalId = (result['proposal_id'] ?? _proposalId)
                                    ?.toString();
                                _proposalFileName =
                                    (result['file_name'] ?? '').toString();
                                _proposalTotalMaterial =
                                    (result['total_material'] as num?)
                                        ?.toDouble();
                                _proposalTotalMO =
                                    (result['total_mo'] as num?)?.toDouble();
                                _proposalTotalProjeto =
                                    (result['total_projeto'] as num?)
                                        ?.toDouble();
                                _proposalTotalVenda =
                                    (result['total_venda'] as num?)?.toDouble();
                                _proposalMargemPct =
                                    (result['margem_pct'] as num?)?.toDouble();
                                _proposalEquipmentBlocks =
                                    ((result['equipment_blocks'] as List?) ?? const [])
                                        .whereType<Map>()
                                        .map(
                                          (item) => Map<String, dynamic>.from(item),
                                        )
                                        .toList(growable: false);
                              });
                            },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _hasActiveProposal
                            ? 'Recarregar proposta (Excel)'
                            : 'Carregar proposta (Excel)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_hasActiveProposal)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC9C9C9)),
                      ),
                      child: const Text(
                        'Depois de carregar o Excel, aqui aparecem os valores para fechar o orcamento.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12.5,
                        ),
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
              onPressed: (isLoading || _saving || _proposalMargemPct == null)
                  ? null
                  : _closeBudget,
              child: const Text('Fechar orcamento'),
            ),
            ElevatedButton(
              onPressed: (isLoading || _saving) ? null : _save,
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

    List<Map<String, dynamic>> _normalizeProposalItems(
      List<Map<String, dynamic>> items,
    ) {
      return items.map((item) {
        final rawPayload = item['raw_payload'];
        final rawMap = rawPayload is Map
            ? Map<String, dynamic>.from(rawPayload)
            : <String, dynamic>{};

        final detectedAttributesRaw =
            rawMap['detected_attributes'] ?? rawMap['attributes'];
        final detectedAttributes = detectedAttributesRaw is Map
            ? Map<String, dynamic>.from(detectedAttributesRaw)
            : <String, dynamic>{};

        final mainEquipment =
            rawMap['main_equipment'] ??
            rawMap['equipment_name'] ??
            item['main_equipment'] ??
            item['equipment_name'];

        final mainDescription =
            rawMap['main_description'] ??
            rawMap['specification'] ??
            item['main_description'] ??
            item['specification'];

        return {
          'main_equipment': mainEquipment,
          'main_description': mainDescription,
          'quantity': rawMap['quantity'] ?? item['quantity'],
          'cost_total': rawMap['cost_total'] ?? item['cost_total'],
          'margin': rawMap['margin'] ?? item['margin'],
          'detected_attributes': detectedAttributes,
        };
      }).toList(growable: false);
    }
}
