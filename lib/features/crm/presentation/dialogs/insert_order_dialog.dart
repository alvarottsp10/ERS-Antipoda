import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/crm_dashboard_providers.dart';
import '../../application/crm_insert_order_models.dart';
import '../../application/crm_insert_order_service.dart';

class InsertOrderDialog extends ConsumerStatefulWidget {
  const InsertOrderDialog({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  ConsumerState<InsertOrderDialog> createState() => _InsertOrderDialogState();
}

class _InsertOrderDialogState extends ConsumerState<InsertOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = const CrmInsertOrderService();
  static const _dialogBackground = Color(0xFFE7E7E7);
  static const _dialogBorder = Color(0xFFC9C9C9);
  static const _dangerRed = Color(0xFFB1121D);

  final _customerController = TextEditingController();
  final _requestedAtController = TextEditingController();
  final _expectedDeliveryDateController = TextEditingController();

  List<CrmInsertOrderCustomer> _customers = [];
  List<CrmInsertOrderContact> _contacts = [];
  List<CrmInsertOrderCommercial> _commercials = [];

  CrmInsertOrderCustomer? _selectedCustomer;
  CrmInsertOrderContact? _selectedContact;
  String? _selectedCommercialUserId;
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
    _loadData();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _requestedAtController.dispose();
    _expectedDeliveryDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final repository = ref.read(crmRepositoryProvider);
      final currentUserId = repository.currentUserId;
      final customersRaw = await repository.fetchInsertOrderCustomers(
        commercialUserId:
            widget.useCurrentCommercialOnly ? currentUserId : null,
      );
      final commercialsRaw = await repository.fetchActiveCommercialsList();

      if (!mounted) {
        return;
      }

      final customers = customersRaw
          .map(
            (item) => CrmInsertOrderCustomer(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
              vatNumber: item['vat_number']?.toString(),
            ),
          )
          .toList(growable: false);

      final commercials = commercialsRaw
          .map(
            (item) => CrmInsertOrderCommercial(
              userId: (item['user_id'] ?? '').toString(),
              fullName: (item['full_name'] ?? '').toString(),
              initials: (item['initials'] ?? '').toString(),
            ),
          )
          .where((item) => item.userId.isNotEmpty)
          .toList(growable: false);

      setState(() {
        _customers = customers;
        _commercials = commercials;
        _selectedCommercialUserId = widget.useCurrentCommercialOnly
            ? currentUserId
            : commercials.any((item) => item.userId == currentUserId)
                ? currentUserId
                : (commercials.isNotEmpty ? commercials.first.userId : null);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadContactsForCustomer(String customerId) async {
    try {
      final repository = ref.read(crmRepositoryProvider);
      final contactsRaw = await repository.fetchContactsForCustomer(customerId);

      if (!mounted) {
        return;
      }

      final contacts = contactsRaw
          .map(
            (item) => CrmInsertOrderContact(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
              email: item['email']?.toString(),
              phone: item['phone']?.toString(),
              isPrimary: item['is_primary'] == true,
            ),
          )
          .toList(growable: false);

      setState(() {
        _contacts = contacts;
        _selectedContact = contacts.cast<CrmInsertOrderContact?>().firstWhere(
              (contact) => contact?.isPrimary == true,
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
      helpText: 'Selecionar data do pedido',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _dangerRed,
              onPrimary: Colors.white,
              surface: _dialogBackground,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: _dialogBackground,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _dangerRed,
              onPrimary: Colors.white,
              surface: _dialogBackground,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: _dialogBackground,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
      customer: _selectedCustomer,
      contact: _selectedContact,
      commercialUserId: _selectedCommercialUserId,
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
      final input = _service.buildCreateOrderInput(
        customer: _selectedCustomer!,
        contact: _selectedContact!,
        commercialUserId: _selectedCommercialUserId!,
        commercials: _commercials,
        requestedAt: _requestedAt!,
        expectedDeliveryDate: _expectedDeliveryDate,
      );

      final repository = ref.read(crmRepositoryProvider);
      final result = await repository.createOrder(
        customerId: input.customerId,
        commercialUserId: input.commercialUserId,
        commercialSigla: input.commercialSigla,
        contactId: input.contactId,
        requestedAt: input.requestedAt,
        expectedDeliveryDate: input.expectedDeliveryDate,
        commercialPhaseId: input.commercialPhaseId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido criado com sucesso: ${(result['order_ref'] ?? '').toString()}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar pedido: $e')),
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
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Container(
            decoration: BoxDecoration(
              color: _dialogBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _dialogBorder, width: 1),
            ),
            padding: const EdgeInsets.all(20),
            child: const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _dialogBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _dialogBorder,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Inserir Pedido',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Pedido',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<CrmInsertOrderCustomer>(
                        optionsBuilder: (textEditingValue) {
                          final query =
                              textEditingValue.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return _customers;
                          }

                          return _customers.where((customer) {
                            final name = customer.name.toLowerCase();
                            final vat =
                                (customer.vatNumber ?? '').toLowerCase();
                            return name.contains(query) || vat.contains(query);
                          });
                        },
                        displayStringForOption: (option) => option.name,
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          _customerController.value = controller.value;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            validator: (_) =>
                                _selectedCustomer == null ? 'Obrigatorio' : null,
                          );
                        },
                        onSelected: (selection) {
                          setState(() {
                            _selectedCustomer = selection;
                          });
                          _loadContactsForCustomer(selection.id);
                        },
                      ),
                      const SizedBox(height: 10),
                      if (!widget.useCurrentCommercialOnly) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCommercialUserId,
                          decoration: const InputDecoration(
                            labelText: 'Comercial',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: _commercials
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.userId,
                                  child: Text(item.fullName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCommercialUserId = value;
                            });
                          },
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Obrigatorio' : null,
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: _requestedAtController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data do Pedido',
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                        validator: (_) =>
                            _requestedAt == null ? 'Obrigatorio' : null,
                        onTap: _pickRequestedAt,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _expectedDeliveryDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data Prevista de Entrega',
                          prefixIcon: Icon(Icons.event_available_outlined),
                        ),
                        validator: (_) => _expectedDeliveryDate == null
                            ? 'Obrigatorio'
                            : null,
                        onTap: _pickExpectedDeliveryDate,
                      ),
                      const SizedBox(height: 10),
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
                                child: Text(contact.name),
                              ),
                            )
                            .toList(),
                        onChanged: _contacts.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedContact = _contacts
                                      .cast<CrmInsertOrderContact?>()
                                      .firstWhere(
                                        (contact) => contact?.id == value,
                                        orElse: () => null,
                                      );
                                });
                              },
                        validator: (_) =>
                            _selectedContact == null ? 'Obrigatorio' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: _dangerRed,
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dangerRed,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar Pedido'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
