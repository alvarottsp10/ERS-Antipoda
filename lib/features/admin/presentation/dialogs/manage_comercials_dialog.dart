import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageCommercialsDialog extends StatefulWidget {
  const ManageCommercialsDialog({super.key});

  @override
  State<ManageCommercialsDialog> createState() =>
      _ManageCommercialsDialogState();
}

class _ManageCommercialsDialogState
    extends State<ManageCommercialsDialog> {
  final SupabaseClient _sb = Supabase.instance.client;

  List<Map<String, dynamic>> _commercials = [];
  bool _loading = true;
  bool _showInactive = false;
  String _search = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res =
          await _sb.from('commercials_list_view').select();

      final list = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;

      setState(() {
        _commercials = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive(
      String userId, bool current) async {
    await _sb
        .from('profiles')
        .update({'is_active': !current})
        .eq('user_id', userId);

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _commercials.where((c) {
      final name =
          (c['full_name'] ?? '').toString().toLowerCase();
      final matchSearch =
          name.contains(_search.toLowerCase());
      final matchActive =
          _showInactive ? true : c['is_active'] == true;
      return matchSearch && matchActive;
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 900, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Comerciais",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      icon: const Icon(Icons.close))
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Pesquisar comercial",
                ),
                onChanged: (v) =>
                    setState(() => _search = v),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                      value: _showInactive,
                      onChanged: (v) => setState(
                          () => _showInactive = v ?? false)),
                  const Text("Mostrar inativos")
                ],
              ),

              const SizedBox(height: 12),

              if (_loading)
                const Expanded(
                    child: Center(
                        child:
                            CircularProgressIndicator()))
              else if (_error != null)
                Expanded(
                    child: Center(child: Text(_error!)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final isActive =
                          c['is_active'] == true;

                      return Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(c['full_name']),
                              const SizedBox(width: 10),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green
                                          .withOpacity(0.15)
                                      : Colors.red
                                          .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  isActive
                                      ? "Ativo"
                                      : "Inativo",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              )
                            ],
                          ),
                          subtitle:
                              Text(c['initials'] ?? ''),
                          trailing: IconButton(
                            icon: Icon(isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off),
                            onPressed: () =>
                                _toggleActive(
                                    c['user_id'],
                                    isActive),
                          ),
                        ),
                      );
                    },
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}