import 'package:erp_app/features/crm/application/crm_view_customers_models.dart';
import 'package:erp_app/features/crm/application/crm_view_customers_service.dart';
import 'package:erp_app/features/crm/data/crm_repository.dart';
import 'package:flutter/material.dart';

class ViewCustomersDialog extends StatefulWidget {
  const ViewCustomersDialog({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  State<ViewCustomersDialog> createState() => _ViewCustomersDialogState();
}

enum ViewMode { list, detail }

class _ContactDraft {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  bool isPrimary = false;

  CrmAddCustomerContactInput toInput(String customerId) {
    return CrmAddCustomerContactInput(
      customerId: customerId,
      name: nameCtrl.text,
      email: emailCtrl.text,
      phone: phoneCtrl.text,
      role: roleCtrl.text,
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

class _SiteDraft {
  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final address1Ctrl = TextEditingController();
  final address2Ctrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  CrmViewCustomerCountry? country;

  CrmAddCustomerSiteInput toInput(String customerId) {
    return CrmAddCustomerSiteInput(
      customerId: customerId,
      name: nameCtrl.text,
      code: codeCtrl.text,
      addressLine1: address1Ctrl.text,
      addressLine2: address2Ctrl.text,
      postalCode: postalCodeCtrl.text,
      city: cityCtrl.text,
      countryId: country?.id ?? 0,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    address1Ctrl.dispose();
    address2Ctrl.dispose();
    postalCodeCtrl.dispose();
    cityCtrl.dispose();
  }
}

class _ViewCustomersDialogState extends State<ViewCustomersDialog> {
  final _repository = CrmRepository();
  final _service = const CrmViewCustomersService();

  ViewMode _mode = ViewMode.list;

  List<CrmViewCustomerListItem> _customers = const [];
  List<CrmViewCustomerContact> _contacts = const [];
  List<CrmViewCustomerSite> _sites = const [];
  List<CrmViewCustomerCountry> _countries = const [];

  bool _loading = true;
  bool _detailLoading = false;
  bool _contactsLoading = false;
  bool _sitesLoading = false;
  bool _countriesLoading = true;

  String _search = '';
  String? _error;

  CrmViewCustomerListItem? _selectedCustomer;
  CrmViewCustomerDetail? _detailCustomer;

  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadCountries();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _vatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final customers = await _repository.fetchCustomersList(
        commercialUserId:
            widget.useCurrentCommercialOnly ? _repository.currentUserId : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _customers = customers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Erro a carregar clientes: $error';
      });
    }
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _repository.fetchCountries();

      if (!mounted) {
        return;
      }

      setState(() {
        _countries = countries;
        _countriesLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _countriesLoading = false;
        _error = 'Erro a carregar paises: $error';
      });
    }
  }

  Future<void> _openCustomer(CrmViewCustomerListItem customer) async {
    final customerId = customer.id;
    if (customerId.isEmpty) {
      return;
    }

    setState(() {
      _selectedCustomer = customer;
      _mode = ViewMode.detail;
      _detailLoading = true;
      _error = null;
    });

    _nameCtrl.text = customer.name;
    _vatCtrl.text = customer.vatNumber;
    _countryCtrl.text = customer.countryName;

    await _loadCustomerDetail(customerId);
    await _loadContacts(customerId);
    await _loadSites(customerId);
  }

  Future<void> _loadCustomerDetail(String customerId) async {
    try {
      final customer = await _repository.fetchCustomerDetail(customerId);

      if (!mounted) {
        return;
      }

      setState(() {
        _detailCustomer = customer;
        _detailLoading = false;
      });

      _nameCtrl.text = customer.name;
      _vatCtrl.text = customer.vatNumber;
      _countryCtrl.text = customer.countryName;
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detailLoading = false;
        _error = 'Erro a carregar detalhe: $error';
      });
    }
  }

  Future<void> _loadContacts(String customerId) async {
    setState(() => _contactsLoading = true);

    try {
      final contacts = await _repository.fetchCustomerContacts(customerId);

      if (!mounted) {
        return;
      }

      setState(() {
        _contacts = contacts;
        _contactsLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _contactsLoading = false;
        _error = 'Erro a carregar contactos: $error';
      });
    }
  }

  Future<void> _loadSites(String customerId) async {
    setState(() => _sitesLoading = true);

    try {
      final sites = await _repository.fetchCustomerSites(customerId);

      if (!mounted) {
        return;
      }

      setState(() {
        _sites = sites;
        _sitesLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sitesLoading = false;
        _error = 'Erro a carregar locais: $error';
      });
    }
  }

  Future<void> _addContact(String customerId) async {
    final draft = _ContactDraft();

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
                  controller: draft.nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: draft.roleCtrl,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                TextField(
                  controller: draft.emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: draft.phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                StatefulBuilder(
                  builder: (_, setLocal) => CheckboxListTile(
                    value: draft.isPrimary,
                    title: const Text('Contacto primario'),
                    onChanged: (value) {
                      setLocal(() => draft.isPrimary = value ?? false);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      draft.dispose();
      return;
    }

    try {
      final input = draft.toInput(customerId);
      final message = _service.validateAddContactInput(input);
      if (message != null) {
        throw Exception(message);
      }

      await _repository.addCustomerContact(input);
      await _loadContacts(customerId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = 'Erro ao adicionar contacto: $error');
    } finally {
      draft.dispose();
    }
  }

  Future<void> _removeContact(String customerId, String contactId) async {
    try {
      await _repository.removeCustomerContact(contactId);
      await _loadContacts(customerId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = 'Erro ao remover contacto: $error');
    }
  }

  Future<void> _addSite(String customerId) async {
    if (_countriesLoading) {
      setState(() => _error = 'Paises ainda em carregamento.');
      return;
    }

    final draft = _SiteDraft();

    final customerCountryId = _detailCustomer?.countryId;
    if (customerCountryId != null) {
      for (final country in _countries) {
        if (country.id == customerCountryId) {
          draft.country = country;
          break;
        }
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Adicionar local'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: draft.nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome do local'),
                      ),
                      TextField(
                        controller: draft.codeCtrl,
                        decoration: const InputDecoration(labelText: 'Codigo (opcional)'),
                      ),
                      TextField(
                        controller: draft.address1Ctrl,
                        decoration: const InputDecoration(labelText: 'Morada'),
                      ),
                      TextField(
                        controller: draft.address2Ctrl,
                        decoration: const InputDecoration(labelText: 'Morada 2 (opcional)'),
                      ),
                      TextField(
                        controller: draft.postalCodeCtrl,
                        decoration: const InputDecoration(labelText: 'Codigo Postal'),
                      ),
                      TextField(
                        controller: draft.cityCtrl,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CrmViewCustomerCountry>(
                        value: draft.country,
                        items: _countries
                            .map(
                              (country) => DropdownMenuItem<CrmViewCustomerCountry>(
                                value: country,
                                child: Text(country.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setLocal(() => draft.country = value),
                        decoration: const InputDecoration(labelText: 'Pais'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      draft.dispose();
      return;
    }

    try {
      final input = draft.toInput(customerId);
      final message = _service.validateAddSiteInput(input);
      if (message != null) {
        throw Exception(message);
      }

      await _repository.addCustomerSite(input);
      await _loadSites(customerId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = 'Erro ao adicionar local: $error');
    } finally {
      draft.dispose();
    }
  }

  Future<void> _removeSite(String customerId, String siteId) async {
    try {
      await _repository.removeCustomerSite(siteId);
      await _loadSites(customerId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = 'Erro ao remover local: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 760,
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
            child: _mode == ViewMode.list ? _buildListView() : _buildDetailView(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final filtered = _service.filterCustomers(
      customers: _customers,
      query: _search,
    );

    return Column(
      key: const ValueKey('list'),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Clientes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Pesquisar',
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final customer = filtered[index];
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(
                        '${customer.vatNumber.isEmpty ? '-' : customer.vatNumber} • '
                        '${customer.countryName.isEmpty ? '-' : customer.countryName}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _openCustomer(customer),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailView() {
    final customerId = _detailCustomer?.id ?? _selectedCustomer?.id;

    return Column(
      key: const ValueKey('detail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _mode = ViewMode.list),
            ),
            Expanded(
              child: Text(
                _service.buildCustomerTitle(
                  detail: _detailCustomer,
                  fallback: _selectedCustomer,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 16),
        if (_detailLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _countryCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Pais'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vatCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'VAT / NIF'),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Contactos',
                    buttonLabel: 'Adicionar contacto',
                    onPressed: customerId == null ? null : () => _addContact(customerId),
                  ),
                  const SizedBox(height: 12),
                  _contactsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _contacts.isEmpty
                          ? const Text('Sem contactos.')
                          : Column(
                              children: _contacts.map((contact) {
                                return Card(
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(contact.name)),
                                        if (contact.isPrimary)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Text(
                                              'Primario',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${contact.role.isEmpty ? '-' : contact.role} • '
                                      '${contact.email.isEmpty ? '-' : contact.email}',
                                    ),
                                    trailing: customerId == null
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _removeContact(
                                              customerId,
                                              contact.id,
                                            ),
                                          ),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Locais',
                    buttonLabel: 'Adicionar local',
                    onPressed: customerId == null ? null : () => _addSite(customerId),
                  ),
                  const SizedBox(height: 12),
                  _sitesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _sites.isEmpty
                          ? const Text('Sem locais.')
                          : Column(
                              children: _sites.map((site) {
                                final subtitleParts = <String>[
                                  if (site.addressLine1.isNotEmpty) site.addressLine1,
                                  if (site.addressLine2.isNotEmpty) site.addressLine2,
                                  [site.postalCode, site.city]
                                      .where((part) => part.isNotEmpty)
                                      .join(' '),
                                  if (site.countryName.isNotEmpty) site.countryName,
                                ].where((part) => part.isNotEmpty).toList(growable: false);

                                return Card(
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(site.name)),
                                        if (site.code.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Text(
                                              site.code,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      subtitleParts.join(' • ').isEmpty
                                          ? '-'
                                          : subtitleParts.join(' • '),
                                    ),
                                    trailing: customerId == null
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _removeSite(
                                              customerId,
                                              site.id,
                                            ),
                                          ),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, size: 18),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}
