import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewCustomersDialog extends StatefulWidget {
  const ViewCustomersDialog({super.key});

  @override
  State<ViewCustomersDialog> createState() => _ViewCustomersDialogState();
}

enum ViewMode { list, detail }

class _ViewCustomersDialogState extends State<ViewCustomersDialog> {
  ViewMode _mode = ViewMode.list;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _contacts = [];

  bool _loading = true;
  bool _detailLoading = false;
  bool _contactsLoading = false;

  String _search = '';
  String? _error;

  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _detailCustomer;

  bool _isEditing = false;

  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();

  SupabaseClient get _sb => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _vatCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // LISTA CLIENTES
  // =========================================================

  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res =
          await _sb.from('customer_list_view').select().order('name');

      final list = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;
      setState(() {
        _customers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro a carregar clientes: $e';
      });
    }
  }

  // =========================================================
  // DETALHE CLIENTE
  // =========================================================

  Future<void> _openCustomer(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) return;

    setState(() {
      _selectedCustomer = row;
      _mode = ViewMode.detail;
      _detailLoading = true;
      _isEditing = false;
      _error = null;
    });

    _nameCtrl.text = row['name'] ?? '';
    _vatCtrl.text = row['vat_number'] ?? '';
    _countryCtrl.text = row['country_name'] ?? '';

    await _loadCustomerDetail(id.toString());
    await _loadContacts(id.toString());
  }

  Future<void> _loadCustomerDetail(String customerId) async {
    try {
      final res = await _sb
          .from('customers')
          .select('id,name,vat_number,country_id,countries(name)')
          .eq('id', customerId)
          .single();

      final map = Map<String, dynamic>.from(res);

      final countryName =
          (map['countries'] is Map) ? map['countries']['name'] ?? '' : '';

      if (!mounted) return;

      setState(() {
        _detailCustomer = map;
        _detailLoading = false;
      });

      _nameCtrl.text = map['name'] ?? '';
      _vatCtrl.text = map['vat_number'] ?? '';
      _countryCtrl.text = countryName;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailLoading = false;
        _error = 'Erro a carregar detalhe: $e';
      });
    }
  }

  // =========================================================
  // CONTACTOS
  // =========================================================

  Future<void> _loadContacts(String customerId) async {
    setState(() => _contactsLoading = true);

    try {
      final res = await _sb
          .from('contacts')
          .select('id,name,email,phone,role,is_primary,created_at')
          .eq('customer_id', customerId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);

      final list = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;
      setState(() {
        _contacts = list;
        _contactsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsLoading = false;
        _error = 'Erro a carregar contactos: $e';
      });
    }
  }

  Future<void> _addContact(String customerId) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    bool isPrimary = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Adicionar contacto'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                StatefulBuilder(
                  builder: (_, setLocal) => CheckboxListTile(
                    value: isPrimary,
                    title: const Text('Contacto primário'),
                    onChanged: (v) => setLocal(() => isPrimary = v ?? false),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Adicionar')),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _sb.rpc('add_customer_contact', params: {
        'p_customer_id': customerId,
        'p_name': nameCtrl.text.trim(),
        'p_email': emailCtrl.text.trim(),
        'p_phone': phoneCtrl.text.trim(),
        'p_role': roleCtrl.text.trim(),
        'p_is_primary': isPrimary,
      });

      await _loadContacts(customerId);
    } catch (e) {
      setState(() => _error = 'Erro ao adicionar contacto: $e');
    }
  }

  Future<void> _removeContact(
      String customerId, String contactId) async {
    try {
      await _sb.rpc('remove_customer_contact',
          params: {'p_contact_id': contactId});
      await _loadContacts(customerId);
    } catch (e) {
      setState(() => _error = 'Erro ao remover contacto: $e');
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 700,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE7E7E7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFC9C9C9),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _mode == ViewMode.list
                ? _buildListView()
                : _buildDetailView(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final filtered = _search.isEmpty
        ? _customers
        : _customers.where((c) {
            final name =
                (c['name'] ?? '').toString().toLowerCase();
            final vat =
                (c['vat_number'] ?? '').toString().toLowerCase();
            return name.contains(_search.toLowerCase()) ||
                vat.contains(_search.toLowerCase());
          }).toList();

    return Column(
      key: const ValueKey('list'),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text("Clientes",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context))
          ],
        ),
        TextField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Pesquisar"),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    return ListTile(
                      title: Text(c['name'] ?? ''),
                      subtitle: Text(
                          "${c['vat_number']} • ${c['country_name']}"),
                      trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16),
                      onTap: () => _openCustomer(c),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildDetailView() {
    final customerId =
        (_detailCustomer?['id'] ?? _selectedCustomer?['id'])
            ?.toString();

    return Column(
      key: const ValueKey('detail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    setState(() => _mode = ViewMode.list)),
            Expanded(
              child: Text(
                _nameCtrl.text,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _nameCtrl,
          readOnly: !_isEditing,
          decoration:
              const InputDecoration(labelText: "Nome"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _countryCtrl,
          readOnly: true,
          decoration:
              const InputDecoration(labelText: "País"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _vatCtrl,
          readOnly: !_isEditing,
          decoration:
              const InputDecoration(labelText: "VAT / NIF"),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            const Expanded(
              child: Text("Contactos",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            ElevatedButton.icon(
              onPressed: customerId == null
                  ? null
                  : () => _addContact(customerId),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Adicionar contacto"),
            )
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: _contactsLoading
              ? const Center(
                  child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (_, i) {
                    final c = _contacts[i];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(c['name'] ?? ''),
                            if (c['is_primary'] == true)
                              const Padding(
                                padding:
                                    EdgeInsets.only(left: 8),
                                child: Text("Primário",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.bold)),
                              )
                          ],
                        ),
                        subtitle: Text(
                            "${c['role']} • ${c['email']}"),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete_outline),
                          onPressed: () =>
                              _removeContact(
                                  customerId!,
                                  c['id']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}