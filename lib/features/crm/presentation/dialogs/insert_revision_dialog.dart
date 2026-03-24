import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/crm_dashboard_providers.dart';
import '../../application/crm_insert_revision_models.dart';
import '../../application/crm_insert_revision_service.dart';

class InsertRevisionDialog extends ConsumerStatefulWidget {
  const InsertRevisionDialog({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  ConsumerState<InsertRevisionDialog> createState() =>
      _InsertRevisionDialogState();
}

class _InsertRevisionDialogState extends ConsumerState<InsertRevisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = const CrmInsertRevisionService();
  final _orderController = TextEditingController();
  final _requestedAtController = TextEditingController();
  final _expectedDeliveryDateController = TextEditingController();

  List<CrmInsertRevisionOrder> _orders = [];
  List<CrmInsertRevisionContact> _contacts = [];
  CrmInsertRevisionOrder? _selectedOrder;
  CrmInsertRevisionContact? _selectedContact;
  DateTime? _requestedAt;
  DateTime? _expectedDeliveryDate;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _requestedAt = DateTime(now.year, now.month, now.day);
    _requestedAtController.text = _formatDate(_requestedAt);
    _expectedDeliveryDate = DateTime(now.year, now.month, now.day);
    _expectedDeliveryDateController.text = _formatDate(_expectedDeliveryDate);
    _loadOrders();
  }

  @override
  void dispose() {
    _orderController.dispose();
    _requestedAtController.dispose();
    _expectedDeliveryDateController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);

    try {
      final repository = ref.read(crmRepositoryProvider);
      final rawOrders = await repository.fetchOrdersEligibleForRevision(
        commercialUserId:
            widget.useCurrentCommercialOnly ? repository.currentUserId : null,
      );
      final orders = _service.filterEligibleOrders(rawOrders);

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadContacts(String customerId) async {
    try {
      final repository = ref.read(crmRepositoryProvider);
      final contacts = await repository.fetchRevisionContactsForCustomer(
        customerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _contacts = contacts;
        final orderContactId = _selectedOrder?.contactId;
        _selectedContact = orderContactId == null
            ? null
            : contacts.cast<CrmInsertRevisionContact?>().firstWhere(
                  (contact) => contact?.id == orderContactId,
                  orElse: () => null,
                );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar contactos: $e')),
      );
    }
  }

  Future<void> _pickRequestedAt() async {
    final now = DateTime.now();
    final initialDate = _requestedAt ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Selecionar data do pedido da revisao',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _requestedAt = DateTime(picked.year, picked.month, picked.day);
      _requestedAtController.text = _formatDate(_requestedAt);
    });
  }

  Future<void> _pickExpectedDeliveryDate() async {
    final now = DateTime.now();
    final initialDate =
        _expectedDeliveryDate ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Selecionar data prevista de entrega',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _expectedDeliveryDate = DateTime(picked.year, picked.month, picked.day);
      _expectedDeliveryDateController.text =
          _formatDate(_expectedDeliveryDate);
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validation = _service.validateSelection(
      order: _selectedOrder,
      requestedAt: _requestedAt,
      expectedDeliveryDate: _expectedDeliveryDate,
    );
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    setState(() => _saving = true);

    try {
      final input = _service.buildInput(
        order: _selectedOrder!,
        selectedContact: _selectedContact,
        requestedAt: _requestedAt!,
        expectedDeliveryDate: _expectedDeliveryDate,
      );

      final repository = ref.read(crmRepositoryProvider);
      final revisionId = await repository.createOrderRevisionFromCrm(
        orderId: input.orderId,
        contactId: input.contactId,
        requestedAt: input.requestedAt,
        expectedDeliveryDate: input.expectedDeliveryDate,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(revisionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisao criada com sucesso')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar revisao: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Inserir Revisao'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<CrmInsertRevisionOrder>(
                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return _orders;
                    }

                    return _orders.where((order) {
                      return order.display.toLowerCase().contains(query) ||
                          order.orderRef.toLowerCase().contains(query) ||
                          order.customerName.toLowerCase().contains(query);
                    });
                  },
                  displayStringForOption: (option) => option.display,
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    _orderController.value = controller.value;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Pedido',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                      validator: (_) =>
                          _selectedOrder == null ? 'Obrigatorio' : null,
                    );
                  },
                  onSelected: (selection) {
                    setState(() {
                      _selectedOrder = selection;
                      _selectedContact = null;
                      _contacts = [];
                    });
                    _loadContacts(selection.customerId);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _requestedAtController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data do Pedido',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  validator: (_) => _requestedAt == null ? 'Obrigatorio' : null,
                  onTap: _pickRequestedAt,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _expectedDeliveryDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data Prevista de Entrega',
                    prefixIcon: Icon(Icons.event_available_outlined),
                  ),
                  validator: (_) =>
                      _expectedDeliveryDate == null ? 'Obrigatorio' : null,
                  onTap: _pickExpectedDeliveryDate,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedContact?.id,
                  decoration: const InputDecoration(
                    labelText: 'Contacto do Pedido',
                    prefixIcon: Icon(Icons.alternate_email_outlined),
                  ),
                  items: _contacts
                      .map(
                        (contact) => DropdownMenuItem<String>(
                          value: contact.id,
                          child: Text(contact.display),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContact = _contacts
                          .cast<CrmInsertRevisionContact?>()
                          .firstWhere(
                            (contact) => contact?.id == value,
                            orElse: () => null,
                          );
                    });
                  },
                ),
                if (_selectedOrder != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Contacto atual: ${_selectedOrder!.currentContactDisplay}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar Revisao'),
        ),
      ],
    );
  }
}
