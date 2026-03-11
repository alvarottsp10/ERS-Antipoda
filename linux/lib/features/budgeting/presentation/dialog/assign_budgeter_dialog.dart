import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignBudgeterDialog extends StatefulWidget {
  const AssignBudgeterDialog({
    super.key,
    required this.orderId,
    required this.orderRef,
    required this.customerName,
  });

  final String orderId; // uuid
  final String orderRef;
  final String customerName;

  @override
  State<AssignBudgeterDialog> createState() => _AssignBudgeterDialogState();
}

class _AssignBudgeterDialogState extends State<AssignBudgeterDialog> {
  final _sb = Supabase.instance.client;

  late Future<void> _boot;

  List<Map<String, dynamic>> _budgeters = [];
  List<Map<String, dynamic>> _typologies = [];
  List<Map<String, dynamic>> _productTypes = [];

  String? _selectedBudgeterUserId; // profiles.user_id
  int? _selectedTypologyId; // budget_typologies.id
  int? _selectedProductTypeId; // product_types.id (opcional)
  bool _isSpecial = false;

  bool _saving = false;

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
        .inFilter('profile_roles.roles.code', ['ORCAMENTISTA', 'ORC_MANAGER', 'ADMIN'])
        .order('full_name', ascending: true);

    _budgeters = (res as List).cast<Map<String, dynamic>>();
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

  Future<void> _assign() async {
    if (_selectedBudgeterUserId == null || _selectedBudgeterUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um orçamentista.')),
      );
      return;
    }
    if (_selectedTypologyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona uma tipologia.')),
      );
      return;
    }

    final me = _sb.auth.currentUser?.id;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão inválida. Faz login novamente.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Desativar assignments anteriores (se existirem)
      await _sb
          .from('order_budget_assignments')
          .update({'is_active': false})
          .eq('order_id', widget.orderId);

      // 2) Inserir novo assignment ativo
      final payload = <String, dynamic>{
        'order_id': widget.orderId,
        'assignee_user_id': _selectedBudgeterUserId,
        'assigned_by': me,
        'is_active': true,
        'is_special': _isSpecial,
        'budget_typology_id': _selectedTypologyId,
        // product_type_id é opcional
        if (_selectedProductTypeId != null) 'product_type_id': _selectedProductTypeId,
      };

      await _sb.rpc(
        'assign_budgeter',
        params: {
          'p_order_id': widget.orderId,
          'p_assignee_user_id': _selectedBudgeterUserId,
          'p_budget_typology_id': _selectedTypologyId,
          'p_product_type_id': _selectedProductTypeId,
          'p_is_special': _isSpecial,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atribuir: $e')),
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
          title: const Text('Atribuir orçamentista'),
          content: SizedBox(
            width: 560,
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
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedBudgeterUserId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Orçamentista',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Selecionar...'),
                      ),
                      ..._budgeters.map((p) {
                        final id = (p['user_id'] ?? '').toString();
                        final name = (p['full_name'] ?? '').toString();
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _selectedBudgeterUserId = v),
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
              onPressed: (loading || _saving) ? null : _assign,
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