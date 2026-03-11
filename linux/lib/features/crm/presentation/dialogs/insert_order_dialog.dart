import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerItem {
  final String id;
  final String name;
  final String? vatNumber;

  const CustomerItem({
    required this.id,
    required this.name,
    this.vatNumber,
  });

  factory CustomerItem.fromMap(Map<String, dynamic> m) {
    return CustomerItem(
      id: m['id'] as String,
      name: (m['name'] ?? '') as String,
      vatNumber: m['vat_number'] as String?,
    );
  }

  String get display => vatNumber == null || vatNumber!.trim().isEmpty
      ? name
      : '$name — ${vatNumber!.trim()}';
}

class ContactItem {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final bool isPrimary;

  const ContactItem({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.isPrimary,
  });

  factory ContactItem.fromMap(Map<String, dynamic> m) {
    return ContactItem(
      id: m['id'] as String,
      name: (m['name'] ?? '') as String,
      email: m['email'] as String?,
      phone: m['phone'] as String?,
      isPrimary: m['is_primary'] == true,
    );
  }

  String get display {
    final parts = <String>[
      name,
      if (email != null && email!.trim().isNotEmpty) email!.trim(),
      if (phone != null && phone!.trim().isNotEmpty) phone!.trim(),
    ];
    return parts.join(' — ');
  }
}

class InsertOrderDialog extends StatefulWidget {
  const InsertOrderDialog({super.key});

  @override
  State<InsertOrderDialog> createState() => _InsertOrderDialogState();
}

class _InsertOrderDialogState extends State<InsertOrderDialog> {
  final _formKey = GlobalKey<FormState>();

  // UI controllers
  final _customerCtrl = TextEditingController();

    // data
  List<CustomerItem> _customers = [];
  CustomerItem? _selectedCustomer;

  List<ContactItem> _contacts = [];
  ContactItem? _selectedContact;
  bool _loadingContacts = false;

  List<Map<String, dynamic>> _commercials = [];
  String? _selectedCommercialUserId;
  bool _loadingCommercials = true;

  bool _loadingCustomers = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadCommercials(); // <-- novo
  }

  Future<void> _loadCustomers() async {
    try {
      final res = await Supabase.instance.client
          .from('customers')
          .select('id,name,vat_number')
          .order('name', ascending: true);

      final list = (res as List)
          .map((e) => CustomerItem.fromMap(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _customers = list;
        _loadingCustomers = false;
      });
    } catch (e) {
      setState(() => _loadingCustomers = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a carregar clientes: $e')),
      );
    }
  }

    Future<void> _loadContactsForCustomer(String customerId) async {
    setState(() {
      _loadingContacts = true;
      _contacts = [];
      _selectedContact = null;
    });

    try {
      final res = await Supabase.instance.client
          .from('contacts')
          .select('id,name,email,phone,is_primary')
          .eq('customer_id', customerId)
          .order('is_primary', ascending: false)
          .order('name', ascending: true);

      final list = (res as List)
          .map((e) => ContactItem.fromMap(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _contacts = list;
        _selectedContact = list.isNotEmpty ? list.first : null;
        _loadingContacts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingContacts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a carregar contactos: $e')),
      );
    }
  }

  Future<void> _loadCommercials() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;

    try {
      final res = await sb
          .from('commercials_list_view')
          .select()
          .eq('is_active', true);

      final list = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // default: o user logado (se estiver na lista), senão o primeiro
      String? selected;
      if (user != null) {
        final me = list.where((c) => c['user_id'] == user.id).toList();
        if (me.isNotEmpty) selected = me.first['user_id'] as String?;
      }
      selected ??= list.isNotEmpty ? list.first['user_id'] as String? : null;

      if (!mounted) return;
      setState(() {
        _commercials = list;
        _selectedCommercialUserId = selected;
        _loadingCommercials = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCommercials = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a carregar comerciais: $e')),
      );
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  Future<void> _submit() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um cliente.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _creating = true);

    try {
      // 1) Ir buscar a sigla (initials) do comercial selecionado no dropdown
      final selected = _commercials.where(
        (c) => c['user_id'] == _selectedCommercialUserId,
      ).toList();

      final initials = selected.isNotEmpty
          ? (selected.first['initials'] ?? '').toString().trim()
          : '';

      if (initials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleciona um comercial válido.')),
        );
        setState(() => _creating = false);
        return;
      }

      // 2) Chamar a SP com customer + sigla
      final res = await Supabase.instance.client.rpc(
        'create_order',
        params: {
          'p_commercial_phase_id': null,     // bigint (podes manter null)
          'p_commercial_sigla': initials,    // TEXT -> a sigla que calculaste acima
          'p_commercial_user_id': _selectedCommercialUserId, // UUID -> o user_id do comercial
          'p_customer_id': _selectedCustomer!.id,            // UUID -> cliente
        },
      );

      // returns table -> lista com 1 row
      final row = (res as List).first as Map<String, dynamic>;

      if (!mounted) return;
      Navigator.of(context).pop(row); // devolve ao ecrã principal

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Igual ao teu AddCustomerDialog
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
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.add_shopping_cart_outlined, color: textDark),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Inserir Pedido',
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

                    const _SectionTitle('Pedido'),
                    const SizedBox(height: 10),

                    // Cliente (Autocomplete para UX melhor)
                    _loadingCustomers
                        ? const _LoadingField(label: 'Cliente', icon: Icons.business_outlined)
                        : Autocomplete<CustomerItem>(
                            displayStringForOption: (c) => c.display,
                            optionsBuilder: (text) {
                              final q = text.text.trim().toLowerCase();
                              if (q.isEmpty) return _customers;
                              return _customers.where((c) {
                                final name = c.name.toLowerCase();
                                final vat = (c.vatNumber ?? '').toLowerCase();
                                return name.contains(q) || vat.contains(q);
                              });
                            },
                            onSelected: (c) {
                              setState(() => _selectedCustomer = c);
                              _customerCtrl.text = c.display;
                              _loadContactsForCustomer(c.id);
                            },
                            fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
                              // sincroniza com o nosso controller para validação
                              textCtrl.text = _customerCtrl.text;
                              textCtrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: textCtrl.text.length),
                              );

                              return TextFormField(
                                controller: textCtrl,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Cliente',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                validator: (_) => _selectedCustomer == null ? 'Obrigatório' : null,
                                onChanged: (v) {
                                  _customerCtrl.text = v;
                                  setState(() {
                                    _selectedCustomer = null;
                                    _contacts = [];
                                    _selectedContact = null;
                                  });
                                },
                              );
                            },
                          ),
                                      
                    const SizedBox(height: 12),

                    _loadingCommercials
                      ? const _LoadingField(label: 'Sigla Comercial', icon: Icons.badge_outlined)
                      : DropdownButtonFormField<String>(
                          value: _selectedCommercialUserId,
                          decoration: const InputDecoration(
                            labelText: 'Sigla Comercial',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: _commercials.map((c) {
                            final userId = c['user_id'] as String;
                            final initials = (c['initials'] ?? '').toString();
                            final name = (c['full_name'] ?? '').toString();
                            return DropdownMenuItem(
                              value: userId,
                              child: Text('$initials — $name'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCommercialUserId = v),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),

                    const SizedBox(height: 12),

                    if (_selectedCustomer == null)
                      const InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Contacto do Pedido',
                          prefixIcon: Icon(Icons.contact_phone_outlined),
                        ),
                        child: Text('Seleciona primeiro um cliente.'),
                      )
                    else if (_loadingContacts)
                      const _LoadingField(
                        label: 'Contacto do Pedido',
                        icon: Icons.contact_phone_outlined,
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedContact?.id,
                        decoration: const InputDecoration(
                          labelText: 'Contacto do Pedido',
                          prefixIcon: Icon(Icons.contact_phone_outlined),
                        ),
                        items: _contacts.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.display, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) {
                          final picked = _contacts.where((c) => c.id == v).toList();
                          setState(() {
                            _selectedContact = picked.isNotEmpty ? picked.first : null;
                          });
                        },
                        validator: (_) {
                          if (_selectedCustomer != null && _selectedContact == null) {
                            return 'Obrigatório';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: 14),

                    // Footer
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
                            backgroundColor: const Color(0xFFB7E4C7), // verde pastel
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _creating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Criar'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
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

class _LoadingField extends StatelessWidget {
  const _LoadingField({required this.label, required this.icon});
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