import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderItem {
  final String id;
  final String orderRef;
  final String? customerName;
  final String? contactId;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;

  const OrderItem({
    required this.id,
    required this.orderRef,
    this.customerName,
    this.contactId,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    final customerMap = m['customers'];
    final contactMap = m['contacts'];

    return OrderItem(
      id: m['id'] as String,
      orderRef: (m['order_ref'] ?? '').toString(),
      customerName: customerMap is Map ? (customerMap['name'] ?? '').toString() : null,
      contactId: contactMap is Map ? contactMap['id']?.toString() : null,
      contactName: contactMap is Map ? contactMap['name']?.toString() : null,
      contactEmail: contactMap is Map ? contactMap['email']?.toString() : null,
      contactPhone: contactMap is Map ? contactMap['phone']?.toString() : null,
    );
  }

  String get display {
    final customer = (customerName ?? '').trim();
    if (customer.isEmpty) return orderRef;
    return '$orderRef — $customer';
  }

  String get contactDisplay {
    final parts = <String>[
      if ((contactName ?? '').trim().isNotEmpty) contactName!.trim(),
      if ((contactEmail ?? '').trim().isNotEmpty) contactEmail!.trim(),
      if ((contactPhone ?? '').trim().isNotEmpty) contactPhone!.trim(),
    ];

    if (parts.isEmpty) return 'Sem contacto associado';
    return parts.join(' — ');
  }
}

class InsertRevisionDialog extends StatefulWidget {
  const InsertRevisionDialog({super.key});

  @override
  State<InsertRevisionDialog> createState() => _InsertRevisionDialogState();
}

class _InsertRevisionDialogState extends State<InsertRevisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderCtrl = TextEditingController();

  List<OrderItem> _orders = [];
  OrderItem? _selectedOrder;

  bool _loadingOrders = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
        final res = await Supabase.instance.client
          .from('orders')
          .select('''
            id,
            order_ref,
            customer_id,
            contact_id,
            commercial_phase_id,
            customers(name),
            contacts(id,name,email,phone)
          ''')
          .eq('commercial_phase_id', 13)
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() {
        _orders = list;
        _loadingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOrders = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a carregar pedidos: $e')),
      );
    }
  }

    Future<void> _submit() async {
    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um pedido.')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final res = await Supabase.instance.client.rpc(
        'create_order_revision_from_crm',
        params: {
          'p_order_id': _selectedOrder!.id,
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(res);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar revisão: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE7E7E7);
    const border = Color(0xFFC9C9C9);
    const textDark = Color(0xFF151515);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_outlined, color: textDark),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Inserir Revisão',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const _RevisionSectionTitle('Revisão'),
                    const SizedBox(height: 10),

                    _loadingOrders
                        ? const _RevisionLoadingField(
                            label: 'Pedido',
                            icon: Icons.search_outlined,
                          )
                        : Autocomplete<OrderItem>(
                            displayStringForOption: (o) => o.display,
                            optionsBuilder: (text) {
                              final q = text.text.trim().toLowerCase();
                              if (q.isEmpty) return _orders;
                              return _orders.where((o) {
                                final ref = o.orderRef.toLowerCase();
                                final customer = (o.customerName ?? '').toLowerCase();
                                return ref.contains(q) || customer.contains(q);
                              });
                            },
                            onSelected: (o) {
                              setState(() => _selectedOrder = o);
                              _orderCtrl.text = o.display;
                            },
                            fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
                              textCtrl.text = _orderCtrl.text;
                              textCtrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: textCtrl.text.length),
                              );

                              return TextFormField(
                                controller: textCtrl,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Pedido',
                                  prefixIcon: Icon(Icons.search_outlined),
                                ),
                                validator: (_) => _selectedOrder == null ? 'Obrigatório' : null,
                                onChanged: (v) {
                                  _orderCtrl.text = v;
                                  setState(() => _selectedOrder = null);
                                },
                              );
                            },
                          ),

                    const SizedBox(height: 12),

                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Contacto atual do Pedido',
                        prefixIcon: Icon(Icons.contact_phone_outlined),
                      ),
                      child: Text(
                        _selectedOrder?.contactDisplay ?? 'Seleciona primeiro um pedido.',
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        TextButton(
                          onPressed: _creating ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _creating ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7E4C7),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevisionSectionTitle extends StatelessWidget {
  const _RevisionSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF151515),
      ),
    );
  }
}

class _RevisionLoadingField extends StatelessWidget {
  const _RevisionLoadingField({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: const SizedBox(
        height: 24,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('A carregar...'),
        ),
      ),
    );
  }
}