import 'package:flutter/material.dart';

import '../../application/process_folder_helper.dart';
import '../../data/budgeting_repository.dart';
import '../../domain/budgeting_models.dart';

class AssignBudgeterDialog extends StatefulWidget {
  const AssignBudgeterDialog({
    super.key,
    required this.orderId,
    required this.orderRef,
    required this.customerName,
    required this.entryDateLabel,
    required this.expectedDeliveryDateLabel,
  });

  final String orderId;
  final String orderRef;
  final String customerName;
  final String entryDateLabel;
  final String expectedDeliveryDateLabel;

  @override
  State<AssignBudgeterDialog> createState() => _AssignBudgeterDialogState();
}

class _AssignBudgeterDialogState extends State<AssignBudgeterDialog> {
  static const int _emptyOptionId = -1;
  final _repository = BudgetingRepository();

  late Future<void> _boot;

  List<BudgetingBudgeterOption> _budgeters = [];
  List<BudgetingOption> _typologies = [];
  List<BudgetingOption> _productTypes = [];

  String? _selectedLeadUserId;
  String? _selectedSupportUserId;
  int? _selectedTypologyId;
  int? _selectedProductTypeId;
  bool _isSpecial = false;

  bool _saving = false;

  static const _testProcessFolderPath =
      r'Y:\9999 - TECNOLOGIA E SERVIÇOS DE INFORMAÇÃO\040 - DEV\01 - ERP APP\2000 - PROCESSOS\2026\2026 AP 002 - Antípoda Lda\000 - DEP.COMERCIAL\00 - Especificações';

  @override
  void initState() {
    super.initState();
    _boot = _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBudgeters(),
      _loadTypologies(),
      _loadProductTypes(),
    ]);
  }

  Future<void> _loadBudgeters() async {
    _budgeters = await _repository.fetchBudgeters();
  }

  Future<void> _loadTypologies() async {
    _typologies = await _repository.fetchBudgetTypologies();
  }

  Future<void> _loadProductTypes() async {
    _productTypes = await _repository.fetchProductTypes();
  }

  Future<void> _assign() async {
    final leadUserId = _selectedLeadUserId?.trim();
    final supportUserId = _selectedSupportUserId?.trim();

    if (leadUserId == null || leadUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um orcamentista lead.')),
      );
      return;
    }

    if (supportUserId != null &&
        supportUserId.isNotEmpty &&
        supportUserId == leadUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead e support nao podem ser o mesmo utilizador.'),
        ),
      );
      return;
    }

    if (_repository.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessao invalida. Faz login novamente.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.assignBudgeter(
        orderId: widget.orderId,
        assigneeUserId: leadUserId,
        assignmentRole: 'lead',
        budgetTypologyId: _selectedTypologyId,
        productTypeId: _selectedProductTypeId,
        isSpecial: _isSpecial,
      );

      if (supportUserId != null && supportUserId.isNotEmpty) {
        await _repository.assignBudgeter(
          orderId: widget.orderId,
          assigneeUserId: supportUserId,
          assignmentRole: 'support',
          budgetTypologyId: _selectedTypologyId,
          productTypeId: _selectedProductTypeId,
          isSpecial: _isSpecial,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atribuir: $error')),
      );
      setState(() => _saving = false);
    }
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
          title: const Text('Atribuir orcamentista'),
          content: SizedBox(
            width: 560,
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: widget.entryDateLabel,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          labelText: 'Data esperada de entrada',
                          prefixIcon: Icon(Icons.event_available_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: widget.expectedDeliveryDateLabel,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          labelText: 'Data prevista de entrega',
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ProcessFolderHelper.isSupported)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        debugPrint(
                          'AssignBudgeterDialog opening process folder: '
                          '$_testProcessFolderPath',
                        );
                        final opened = await ProcessFolderHelper.openFolder(
                          _testProcessFolderPath,
                        );
                        if (!mounted) {
                          return;
                        }
                        if (!opened) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Nao foi possivel abrir a pasta do processo: '
                                '$_testProcessFolderPath',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Abrir pasta com informacao do cliente'),
                    ),
                  ),
                if (ProcessFolderHelper.isSupported) const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: _selectedLeadUserId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Lead',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Selecionar...'),
                      ),
                      ..._budgeters.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.userId,
                          child: Text(
                            item.fullName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _selectedLeadUserId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: _selectedSupportUserId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Support (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Nenhum'),
                      ),
                      ..._budgeters.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.userId,
                          child: Text(
                            item.fullName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _selectedSupportUserId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedTypologyId ?? _emptyOptionId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Tipologia (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: _emptyOptionId,
                        child: Text('Selecionar...'),
                      ),
                      ..._typologies.map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(
                              () => _selectedTypologyId =
                                  value == _emptyOptionId ? null : value,
                            ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedProductTypeId ?? _emptyOptionId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Produtos (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: _emptyOptionId,
                        child: Text('-'),
                      ),
                      ..._productTypes.map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _selectedProductTypeId =
                                value == _emptyOptionId ? null : value),
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
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: (isLoading || _saving) ? null : _assign,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Atribuir'),
            ),
          ],
        );
      },
    );
  }
}
