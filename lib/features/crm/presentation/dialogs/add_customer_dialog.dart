import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CountryItem {
  final int id;
  final String name;
  final String? iso2;
  final String? vatPrefix;   // countries.vat_prefix
  final String? phonePrefix; // countries.phone_prefix

  const CountryItem({
    required this.id,
    required this.name,
    this.iso2,
    this.vatPrefix,
    this.phonePrefix,
  });

  factory CountryItem.fromMap(Map<String, dynamic> m) {
    return CountryItem(
      id: m['id'] as int,
      name: (m['name'] ?? '') as String,
      iso2: m['iso2'] as String?,
      vatPrefix: m['vat_prefix'] as String?,
      phonePrefix: m['phone_prefix'] as String?,
    );
  }
}

class ContactDraft {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  bool isPrimary = false;

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    roleCtrl.dispose();
  }
}

/// (Opcional) resultado para devolver ao dashboard.
/// Ainda não é usado para insert — isso fazemos depois.
class AddCustomerResult {
  final String name;
  final int countryId;
  final String vat;
  final String? email;
  final String? phone;
  final List<ContactDraft> contacts;

  AddCustomerResult({
    required this.name,
    required this.countryId,
    required this.vat,
    this.email,
    this.phone,
    required this.contacts,
  });
}

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  // Cliente
  final _nameCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Países
  CountryItem? _selectedCountry;
  List<CountryItem> _countries = [];
  bool _loadingCountries = true;

  // Contactos
  final List<ContactDraft> _contacts = [];

  // Para substituição de prefixos
  String? _lastPhonePrefixApplied;

  Set<String> get _knownVatPrefixes => _countries
      .map((c) => (c.vatPrefix ?? c.iso2 ?? '').trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toSet();

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final res = await Supabase.instance.client
        .from('countries')
        .select('id,name,iso2,vat_prefix,phone_prefix')
        .order('name', ascending: true);

    final list = (res as List)
        .map((e) => CountryItem.fromMap(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _countries = list;
      _loadingCountries = false;
    });
  }

  // ------------------------------
  // Prefix logic (VAT + Phones)
  // ------------------------------

  void _applyVatPrefix(CountryItem c) {
    final newPrefix = (c.vatPrefix ?? c.iso2 ?? '').trim().toUpperCase();
    if (newPrefix.isEmpty) return;

    var text = _vatCtrl.text.trimLeft();

    // Remove múltiplos prefixos antigos (ex: "NL PT 123" -> "123")
    while (true) {
      final parts = text.split(RegExp(r'\s+'));
      if (parts.isEmpty) break;
      final first = parts.first.toUpperCase();
      if (_knownVatPrefixes.contains(first)) {
        // remove o primeiro token + espaços
        text = text.replaceFirst(RegExp(r'^[A-Za-z]{2,3}\s+'), '');
        text = text.trimLeft();
        continue;
      }
      break;
    }

    _vatCtrl.text = text.isEmpty ? '$newPrefix ' : '$newPrefix $text';
    _vatCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _vatCtrl.text.length),
    );
  }

  void _applyPhonePrefixToCustomer(CountryItem c) {
    final newPrefix = (c.phonePrefix ?? '').trim();
    if (newPrefix.isEmpty) return;

    final current = _phoneCtrl.text.trim();

    // se está vazio -> preenche
    if (current.isEmpty) {
      _phoneCtrl.text = '$newPrefix ';
      _phoneCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneCtrl.text.length),
      );
      _lastPhonePrefixApplied = newPrefix;
      return;
    }

    // se já tem o novo prefixo -> não mexe
    if (current.startsWith(newPrefix)) {
      _lastPhonePrefixApplied = newPrefix;
      return;
    }

    // se tinha o prefixo anterior aplicado por nós -> substitui
    if (_lastPhonePrefixApplied != null &&
        current.startsWith(_lastPhonePrefixApplied!)) {
      final rest = current.substring(_lastPhonePrefixApplied!.length).trimLeft();
      _phoneCtrl.text = rest.isEmpty ? '$newPrefix ' : '$newPrefix $rest';
      _phoneCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneCtrl.text.length),
      );
      _lastPhonePrefixApplied = newPrefix;
      return;
    }

    // caso contrário: não força (para não estragar números já formatados)
    _lastPhonePrefixApplied = newPrefix;
  }

  void _applyPhonePrefixToContacts(CountryItem c) {
    final newPrefix = (c.phonePrefix ?? '').trim();
    if (newPrefix.isEmpty) return;

    for (final contact in _contacts) {
      final cur = contact.phoneCtrl.text.trim();

      if (cur.isEmpty) {
        contact.phoneCtrl.text = '$newPrefix ';
        continue;
      }

      if (_lastPhonePrefixApplied != null && cur.startsWith(_lastPhonePrefixApplied!)) {
        final rest = cur.substring(_lastPhonePrefixApplied!.length).trimLeft();
        contact.phoneCtrl.text = rest.isEmpty ? '$newPrefix ' : '$newPrefix $rest';
      }
    }
  }

  void _onCountryChanged(CountryItem? v) {
    setState(() => _selectedCountry = v);
    if (v == null) return;

    _applyVatPrefix(v);
    _applyPhonePrefixToCustomer(v);
    _applyPhonePrefixToContacts(v);
  }

  // ------------------------------
  // Contacts handling
  // ------------------------------

  void _addContact() {
    setState(() {
      final c = ContactDraft();

      // 1º contacto = primário por defeito
      if (_contacts.isEmpty) c.isPrimary = true;

      // preenche prefixo no telemóvel
      final prefix = (_selectedCountry?.phonePrefix ?? '').trim();
      if (prefix.isNotEmpty) {
        c.phoneCtrl.text = '$prefix ';
      }

      _contacts.add(c);
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts[index].dispose();
      _contacts.removeAt(index);

      // garante que existe no máximo 1 primário; se ficou nenhum e há contactos, marca o 1º
      if (_contacts.isNotEmpty && !_contacts.any((c) => c.isPrimary)) {
        _contacts.first.isPrimary = true;
      }
    });
  }

  void _setPrimary(int index) {
    setState(() {
      for (var i = 0; i < _contacts.length; i++) {
        _contacts[i].isPrimary = i == index;
      }
    });
  }

  // ------------------------------
  // Validation + Submit (ainda sem insert)
  // ------------------------------

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  String? _optionalEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Email inválido';
  }

  Future<void> _submit() async {
    final country = _selectedCountry;
    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um país.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // validar contactos
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É obrigatório pelo menos um contacto.')),
      );
      return;
    }

    int primaryCount = 0;

    for (var i = 0; i < _contacts.length; i++) {
      final c = _contacts[i];

      if (c.emailCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contacto ${i + 1}: email é obrigatório.')),
        );
        return;
      }

      if (c.roleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contacto ${i + 1}: role é obrigatório.')),
        );
        return;
      }

      if (c.isPrimary) primaryCount++;
    }

    if (primaryCount != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deve existir exatamente um contacto primário.')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final contactsJson = _contacts.map((c) {
        return {
          'name': c.nameCtrl.text.trim(),
          'email': c.emailCtrl.text.trim(),
          'phone': c.phoneCtrl.text.trim(),
          'role': c.roleCtrl.text.trim(),
          'is_primary': c.isPrimary,
        };
      }).toList();

      final response = await supabase.rpc(
        'create_customer_with_contacts',
        params: {
          'p_name': _nameCtrl.text.trim(),
          'p_country_id': country.id,
          'p_vat_number': _vatCtrl.text.trim(),
          'p_email': _emailCtrl.text.trim(),
          'p_phone': _phoneCtrl.text.trim(),
          'p_contacts': contactsJson,
        },
      );

      // sucesso
      if (!mounted) return;

      Navigator.of(context).pop(response);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _contacts) {
      c.dispose();
    }
    _nameCtrl.dispose();
    _vatCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ------------------------------
  // UI
  // ------------------------------

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE7E7E7);
    const border = Color(0xFFC9C9C9);
    const textDark = Color(0xFF151515);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
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
                        const Icon(Icons.person_add_alt_1_outlined, color: textDark),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Adicionar Cliente',
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

                    // Cliente
                    const _SectionTitle('Cliente'),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, c) {
                        final twoCols = c.maxWidth >= 760;

                        Widget gap() => const SizedBox(height: 12);

                        final left = Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              validator: _required,
                            ),
                            gap(),
                            _loadingCountries
                                ? const _LoadingField(label: 'País', icon: Icons.public)
                                : DropdownButtonFormField<CountryItem>(
                                    value: _selectedCountry,
                                    items: _countries
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _onCountryChanged,
                                    decoration: const InputDecoration(
                                      labelText: 'País',
                                      prefixIcon: Icon(Icons.public),
                                    ),
                                    validator: (v) => v == null ? 'Obrigatório' : null,
                                  ),
                            gap(),
                            TextFormField(
                              controller: _vatCtrl,
                              decoration: const InputDecoration(
                                labelText: 'VAT / NIF',
                                hintText: 'Ex: PT 123456789',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: _required,
                            ),
                          ],
                        );

                        final right = Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email (opcional)',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: _optionalEmail,
                            ),
                            gap(),
                            TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Telefone (opcional)',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                          ],
                        );

                        if (!twoCols) {
                          return Column(
                            children: [
                              left,
                              const SizedBox(height: 12),
                              right,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 16),
                            Expanded(child: right),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Contactos header + botão
                    Row(
                      children: [
                        const Expanded(child: _SectionTitle('Contactos')),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _addContact,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar contacto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: textDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: border, width: 1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_contacts.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Sem contactos adicionados.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),

                    for (var i = 0; i < _contacts.length; i++)
                      _ContactCard(
                        index: i,
                        contact: _contacts[i],
                        borderSoft: border,
                        onRemove: () => _removeContact(i),
                        onPrimary: () => _setPrimary(i),
                      ),

                    const SizedBox(height: 12),

                    // Footer
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB00020),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Guardar'),
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.index,
    required this.contact,
    required this.borderSoft,
    required this.onRemove,
    required this.onPrimary,
  });

  final int index;
  final ContactDraft contact;
  final Color borderSoft;
  final VoidCallback onRemove;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF151515);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSoft, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contacto ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover contacto',
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: contact.nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do contacto',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: contact.roleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Role (obrigatório)',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: contact.emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (obrigatório)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: contact.phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telemóvel (opcional)',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Checkbox(
                value: contact.isPrimary,
                onChanged: (_) => onPrimary(),
              ),
              const Text('Contacto primário'),
            ],
          ),
        ],
      ),
    );
  }
}