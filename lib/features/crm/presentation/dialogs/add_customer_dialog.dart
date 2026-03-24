import 'package:erp_app/features/app/application/app_access_providers.dart';
import 'package:erp_app/features/crm/application/crm_add_customer_models.dart';
import 'package:erp_app/features/crm/application/crm_add_customer_service.dart';
import 'package:erp_app/features/crm/data/crm_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountryItem {
  const CountryItem({
    required this.id,
    required this.name,
    this.iso2,
    this.vatPrefix,
    this.phonePrefix,
  });

  final int id;
  final String name;
  final String? iso2;
  final String? vatPrefix;
  final String? phonePrefix;

  factory CountryItem.fromMap(Map<String, dynamic> map) {
    return CountryItem(
      id: (map['id'] as num).toInt(),
      name: (map['name'] ?? '').toString(),
      iso2: map['iso2'] as String?,
      vatPrefix: map['vat_prefix'] as String?,
      phonePrefix: map['phone_prefix'] as String?,
    );
  }

  CrmAddCustomerCountry toModel() {
    return CrmAddCustomerCountry(
      id: id,
      name: name,
      iso2: iso2,
      vatPrefix: vatPrefix,
      phonePrefix: phonePrefix,
    );
  }
}

class ContactDraft {
  ContactDraft();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  bool isPrimary = false;

  CrmAddCustomerContactDraft toModel() {
    return CrmAddCustomerContactDraft(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      role: roleCtrl.text.trim(),
      isPrimary: isPrimary,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    roleCtrl.dispose();
  }
}

class SiteDraft {
  SiteDraft({this.country});

  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final addressLine1Ctrl = TextEditingController();
  final addressLine2Ctrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  CountryItem? country;

  CrmAddCustomerSiteDraft toModel() {
    return CrmAddCustomerSiteDraft(
      name: nameCtrl.text.trim(),
      code: codeCtrl.text.trim(),
      addressLine1: addressLine1Ctrl.text.trim(),
      addressLine2: addressLine2Ctrl.text.trim(),
      postalCode: postalCodeCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      countryId: country!.id,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    addressLine1Ctrl.dispose();
    addressLine2Ctrl.dispose();
    postalCodeCtrl.dispose();
    cityCtrl.dispose();
  }
}

class AddCustomerResult {
  const AddCustomerResult({
    required this.customerId,
    required this.customerName,
    required this.vatNumber,
    required this.contacts,
    required this.siteCount,
  });

  final String customerId;
  final String customerName;
  final String vatNumber;
  final List<CrmAddCustomerContactDraft> contacts;
  final int siteCount;
}

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CrmRepository();
  final _service = const CrmAddCustomerService();

  final _nameCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  CountryItem? _selectedCustomerCountry;
  List<CountryItem> _countries = const [];
  List<Map<String, dynamic>> _commercials = const [];
  String? _selectedCommercialUserId;
  bool _loadingCountries = true;
  bool _loadingCommercials = true;
  bool _saving = false;

  final List<ContactDraft> _contacts = [];
  final List<SiteDraft> _sites = [];
  String? _lastPhonePrefixApplied;

  Set<String> get _knownVatPrefixes => _countries
      .map((country) => (country.vatPrefix ?? country.iso2 ?? '').trim().toUpperCase())
      .where((prefix) => prefix.isNotEmpty)
      .toSet();

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadCommercials();
  }

  Future<void> _loadCountries() async {
    try {
      final response = await _repository.fetchCountries();

      final countries = response
          .map(
            (item) => CountryItem(
              id: item.id,
              name: item.name,
              iso2: item.iso2,
              vatPrefix: item.vatPrefix,
              phonePrefix: item.phonePrefix,
            ),
          )
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loadingCountries = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a carregar paises: $error')),
      );
    }
  }

  Future<void> _loadCommercials() async {
    try {
      final response = await _repository.fetchActiveCommercialsList();
      final currentUserId = _repository.currentUserId;
      final currentUserExistsInList = response.any(
        (item) => (item['user_id'] ?? '').toString() == currentUserId,
      );
      final fallbackCommercialUserId = response.isEmpty
          ? null
          : (response.first['user_id'] ?? '').toString();

      if (!mounted) {
        return;
      }

      setState(() {
        _commercials = response;
        _selectedCommercialUserId = widget.useCurrentCommercialOnly
            ? currentUserId
            : (currentUserExistsInList ? currentUserId : fallbackCommercialUserId);
        _loadingCommercials = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loadingCommercials = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a carregar comerciais: $error')),
      );
    }
  }

  void _applyVatPrefix(CountryItem country) {
    final newPrefix = (country.vatPrefix ?? country.iso2 ?? '').trim().toUpperCase();
    if (newPrefix.isEmpty) {
      return;
    }

    var text = _vatCtrl.text.trimLeft();
    while (true) {
      final parts = text.split(RegExp(r'\s+'));
      if (parts.isEmpty) {
        break;
      }

      final first = parts.first.toUpperCase();
      if (_knownVatPrefixes.contains(first)) {
        text = text.replaceFirst(RegExp(r'^[A-Za-z]{2,3}\s+'), '').trimLeft();
        continue;
      }
      break;
    }

    _vatCtrl.text = text.isEmpty ? '$newPrefix ' : '$newPrefix $text';
    _vatCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _vatCtrl.text.length),
    );
  }

  void _applyPhonePrefixToCustomer(CountryItem country) {
    final newPrefix = (country.phonePrefix ?? '').trim();
    if (newPrefix.isEmpty) {
      return;
    }

    final current = _phoneCtrl.text.trim();
    if (current.isEmpty) {
      _phoneCtrl.text = '$newPrefix ';
      _phoneCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneCtrl.text.length),
      );
      _lastPhonePrefixApplied = newPrefix;
      return;
    }

    if (current.startsWith(newPrefix)) {
      _lastPhonePrefixApplied = newPrefix;
      return;
    }

    if (_lastPhonePrefixApplied != null && current.startsWith(_lastPhonePrefixApplied!)) {
      final rest = current.substring(_lastPhonePrefixApplied!.length).trimLeft();
      _phoneCtrl.text = rest.isEmpty ? '$newPrefix ' : '$newPrefix $rest';
      _phoneCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneCtrl.text.length),
      );
      _lastPhonePrefixApplied = newPrefix;
      return;
    }

    _lastPhonePrefixApplied = newPrefix;
  }

  void _applyPhonePrefixToContacts(CountryItem country) {
    final newPrefix = (country.phonePrefix ?? '').trim();
    if (newPrefix.isEmpty) {
      return;
    }

    for (final contact in _contacts) {
      final current = contact.phoneCtrl.text.trim();
      if (current.isEmpty) {
        contact.phoneCtrl.text = '$newPrefix ';
        continue;
      }

      if (_lastPhonePrefixApplied != null && current.startsWith(_lastPhonePrefixApplied!)) {
        final rest = current.substring(_lastPhonePrefixApplied!.length).trimLeft();
        contact.phoneCtrl.text = rest.isEmpty ? '$newPrefix ' : '$newPrefix $rest';
      }
    }
  }

  void _onCustomerCountryChanged(CountryItem? country) {
    setState(() {
      _selectedCustomerCountry = country;
      if (country != null) {
        for (final site in _sites) {
          site.country ??= country;
        }
      }
    });

    if (country == null) {
      return;
    }

    _applyVatPrefix(country);
    _applyPhonePrefixToCustomer(country);
    _applyPhonePrefixToContacts(country);
  }

  void _addContact() {
    setState(() {
      final contact = ContactDraft();
      if (_contacts.isEmpty) {
        contact.isPrimary = true;
      }

      final prefix = (_selectedCustomerCountry?.phonePrefix ?? '').trim();
      if (prefix.isNotEmpty) {
        contact.phoneCtrl.text = '$prefix ';
      }

      _contacts.add(contact);
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts[index].dispose();
      _contacts.removeAt(index);
      if (_contacts.isNotEmpty && !_contacts.any((contact) => contact.isPrimary)) {
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

  void _addSite() {
    setState(() {
      _sites.add(SiteDraft(country: _selectedCustomerCountry));
    });
  }

  void _removeSite(int index) {
    setState(() {
      _sites[index].dispose();
      _sites.removeAt(index);
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Obrigatorio' : null;

  String? _optionalEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Email invalido';
  }

  String? _requiredEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Obrigatorio';
    }
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Email invalido';
  }

  Future<void> _submit() async {
    final contacts = _contacts.map((contact) => contact.toModel()).toList(growable: false);
    final selectionMessage = _service.validateSelection(
      customerCountry: _selectedCustomerCountry?.toModel(),
      commercialUserId: _selectedCommercialUserId,
      contacts: contacts,
      siteCount: _sites.length,
    );

    if (selectionMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selectionMessage)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final contactsMessage = _service.validateContacts(contacts);
    if (contactsMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contactsMessage)),
      );
      return;
    }

    final sites = <CrmAddCustomerSiteDraft>[];
    for (var i = 0; i < _sites.length; i++) {
      final site = _sites[i];
      if (site.country == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Local ${i + 1}: seleciona um pais.')),
        );
        return;
      }
      sites.add(site.toModel());
    }

    final sitesMessage = _service.validateSites(sites);
    if (sitesMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sitesMessage)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final input = _service.buildCreateCustomerInput(
        customerName: _nameCtrl.text,
        customerCountry: _selectedCustomerCountry!.toModel(),
        vatNumber: _vatCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        commercialUserId: _selectedCommercialUserId!,
        contacts: contacts,
        sites: sites,
      );

      final customerId = await _repository.createCustomerWithContacts(input);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        AddCustomerResult(
          customerId: customerId,
          customerName: input.customerName,
          vatNumber: input.vatNumber,
          contacts: contacts,
          siteCount: sites.length,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    for (final contact in _contacts) {
      contact.dispose();
    }
    for (final site in _sites) {
      site.dispose();
    }
    _nameCtrl.dispose();
    _vatCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE7E7E7);
    const border = Color(0xFFC9C9C9);
    const textDark = Color(0xFF151515);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
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
                          onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _SectionTitle('Cliente'),
                    const SizedBox(height: 10),
                    _CustomerFields(
                      loadingCountries: _loadingCountries,
                      loadingCommercials: _loadingCommercials,
                      commercials: _commercials,
                      selectedCommercialUserId: _selectedCommercialUserId,
                      onCommercialChanged: widget.useCurrentCommercialOnly
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCommercialUserId = value;
                              });
                            },
                      showCommercialField: !widget.useCurrentCommercialOnly,
                      countries: _countries,
                      selectedCountry: _selectedCustomerCountry,
                      onCountryChanged: _onCustomerCountryChanged,
                      nameCtrl: _nameCtrl,
                      vatCtrl: _vatCtrl,
                      emailCtrl: _emailCtrl,
                      phoneCtrl: _phoneCtrl,
                      requiredValidator: _required,
                      optionalEmailValidator: _optionalEmail,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: _SectionTitle('Locais')),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _addSite,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar local'),
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
                    if (_sites.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Sem locais adicionados.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    for (var i = 0; i < _sites.length; i++)
                      _SiteCard(
                        index: i,
                        site: _sites[i],
                        countries: _countries,
                        loadingCountries: _loadingCountries,
                        borderSoft: border,
                        onRemove: _saving ? null : () => _removeSite(i),
                        onCountryChanged: (country) {
                          setState(() => _sites[i].country = country);
                        },
                        requiredValidator: _required,
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: _SectionTitle('Contactos')),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _addContact,
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
                        onRemove: _saving ? null : () => _removeContact(i),
                        onPrimary: _saving ? null : () => _setPrimary(i),
                        requiredValidator: _required,
                        requiredEmailValidator: _requiredEmail,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB00020),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Guardar'),
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

class _CustomerFields extends StatelessWidget {
  const _CustomerFields({
    required this.loadingCountries,
    required this.loadingCommercials,
    required this.commercials,
    required this.selectedCommercialUserId,
    required this.onCommercialChanged,
    required this.showCommercialField,
    required this.countries,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.nameCtrl,
    required this.vatCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.requiredValidator,
    required this.optionalEmailValidator,
  });

  final bool loadingCountries;
  final bool loadingCommercials;
  final List<Map<String, dynamic>> commercials;
  final String? selectedCommercialUserId;
  final ValueChanged<String?>? onCommercialChanged;
  final bool showCommercialField;
  final List<CountryItem> countries;
  final CountryItem? selectedCountry;
  final ValueChanged<CountryItem?> onCountryChanged;
  final TextEditingController nameCtrl;
  final TextEditingController vatCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> optionalEmailValidator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 760;
        final left = Column(
          children: [
            if (showCommercialField) ...[
              loadingCommercials
                  ? const _LoadingField(
                      label: 'Comercial',
                      icon: Icons.person_outline,
                    )
                  : DropdownButtonFormField<String>(
                      value: selectedCommercialUserId,
                      items: commercials
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: (item['user_id'] ?? '').toString(),
                              child: Text((item['full_name'] ?? '').toString()),
                            ),
                          )
                          .toList(),
                      onChanged: onCommercialChanged,
                      decoration: const InputDecoration(
                        labelText: 'Comercial Responsavel',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Obrigatorio'
                              : null,
                    ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            loadingCountries
                ? const _LoadingField(label: 'Pais', icon: Icons.public)
                : DropdownButtonFormField<CountryItem>(
                    value: selectedCountry,
                    items: countries
                        .map(
                          (country) => DropdownMenuItem<CountryItem>(
                            value: country,
                            child: Text(country.name),
                          ),
                        )
                        .toList(),
                    onChanged: onCountryChanged,
                    decoration: const InputDecoration(
                      labelText: 'Pais',
                      prefixIcon: Icon(Icons.public),
                    ),
                    validator: (value) => value == null ? 'Obrigatorio' : null,
                  ),
            const SizedBox(height: 12),
            TextFormField(
              controller: vatCtrl,
              decoration: const InputDecoration(
                labelText: 'VAT / NIF',
                hintText: 'Ex: PT 123456789',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: requiredValidator,
            ),
          ],
        );
        final right = Column(
          children: [
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: optionalEmailValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        );

        if (!twoCols) {
          return Column(
            children: [left, const SizedBox(height: 12), right],
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

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.index,
    required this.site,
    required this.countries,
    required this.loadingCountries,
    required this.borderSoft,
    required this.onRemove,
    required this.onCountryChanged,
    required this.requiredValidator,
  });

  final int index;
  final SiteDraft site;
  final List<CountryItem> countries;
  final bool loadingCountries;
  final Color borderSoft;
  final VoidCallback? onRemove;
  final ValueChanged<CountryItem?> onCountryChanged;
  final FormFieldValidator<String> requiredValidator;

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
                  'Local ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: textDark),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover local',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: site.nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do local',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: site.codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Codigo (opcional)',
                    prefixIcon: Icon(Icons.tag_outlined),
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
                  controller: site.addressLine1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Morada',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  validator: requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: site.addressLine2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Morada 2 (opcional)',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
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
                  controller: site.postalCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Codigo Postal',
                    prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                  ),
                  validator: requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: site.cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          loadingCountries
              ? const _LoadingField(label: 'Pais do local', icon: Icons.public)
              : DropdownButtonFormField<CountryItem>(
                  value: site.country,
                  items: countries
                      .map(
                        (country) => DropdownMenuItem<CountryItem>(
                          value: country,
                          child: Text(country.name),
                        ),
                      )
                      .toList(),
                  onChanged: onCountryChanged,
                  decoration: const InputDecoration(
                    labelText: 'Pais do local',
                    prefixIcon: Icon(Icons.public),
                  ),
                  validator: (value) => value == null ? 'Obrigatorio' : null,
                ),
        ],
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
    required this.requiredValidator,
    required this.requiredEmailValidator,
  });

  final int index;
  final ContactDraft contact;
  final Color borderSoft;
  final VoidCallback? onRemove;
  final VoidCallback? onPrimary;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> requiredEmailValidator;

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
                  style: const TextStyle(fontWeight: FontWeight.w700, color: textDark),
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
                  validator: requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: contact.roleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: requiredValidator,
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
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: requiredEmailValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: contact.phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telemovel (opcional)',
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
                onChanged: onPrimary == null ? null : (_) => onPrimary!(),
              ),
              const Text('Contacto primario'),
            ],
          ),
        ],
      ),
    );
  }
}
