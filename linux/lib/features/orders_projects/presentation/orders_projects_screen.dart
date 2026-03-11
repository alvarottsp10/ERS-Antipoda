import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersProjectsScreen extends StatelessWidget {
  const OrdersProjectsScreen({super.key});

  static const Color menuGrey = Color(0xFFE7E7E7);
  static const Color borderSoft = Color(0xFFC9C9C9);
  static const Color dividerSoft = Color(0xFFD6D6D6);
  static const Color textDark = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrdersProjectsFilters(),
          SizedBox(height: 16),
          Expanded(
            child: _Panel(
              title: 'Pedidos e Projetos',
              child: _OrdersProjectsListPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersProjectsFilters extends StatelessWidget {
  const _OrdersProjectsFilters();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineFilterField(
                label: 'Ano',
                fieldWidth: 70,
                child: TextField(
                  decoration: _inputDecoration(),
                ),
              ),
              _InlineFilterField(
                label: 'Sigla Comercial',
                fieldWidth: 50,
                child: TextField(
                  decoration: _inputDecoration(),
                ),
              ),
              _InlineFilterField(
                label: 'Número',
                fieldWidth: 70,
                child: TextField(
                  decoration: _inputDecoration(),
                ),
              ),
              SizedBox(
                width: 42,
                height: 38,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7E4C7),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.search, size: 18),
                ),
              )
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineFilterField(
              label: 'Cliente',
              fieldWidth: 280,
              child: TextField(
                decoration: _inputDecoration(
                  hintText: 'Procurar cliente',
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 42,
              height: 38,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB7E4C7),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.search, size: 18),
              ),
            )
          ],
        ),
      ],
    );
  }

  static InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: OrdersProjectsScreen.borderSoft,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: OrdersProjectsScreen.borderSoft,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: OrdersProjectsScreen.borderSoft,
          width: 1.2,
        ),
      ),
    );
  }
}

class _InlineFilterField extends StatelessWidget {
  const _InlineFilterField({
    required this.label,
    required this.fieldWidth,
    required this.child,
  });

  final String label;
  final double fieldWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: OrdersProjectsScreen.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: fieldWidth,
          child: child,
        ),
      ],
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: OrdersProjectsScreen.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OrdersProjectsScreen.menuGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OrdersProjectsScreen.borderSoft,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: OrdersProjectsScreen.textDark,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(
            height: 1,
            color: OrdersProjectsScreen.dividerSoft,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _OrdersProjectsListPlaceholder extends StatelessWidget {
  const _OrdersProjectsListPlaceholder();

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final sb = Supabase.instance.client;

    final res = await sb
        .from('orders')
        .select('''
          id,
          order_ref,
          created_at,
          customers(name)
        ''')
        .order('created_at', ascending: false)
        .limit(50);

    return (res as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Erro ao carregar pedidos: ${snapshot.error}',
              style: const TextStyle(color: Colors.black54),
            ),
          );
        }

        final data = snapshot.data ?? const [];
        if (data.isEmpty) {
          return const Center(
            child: Text(
              'Sem pedidos.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 18,
                      child: Text(
                        'Ref',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 32,
                      child: Text(
                        'Cliente',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final row = data[i];
                    final orderRef = (row['order_ref'] ?? '').toString();
                    final customerName =
                        (row['customers'] is Map ? row['customers']['name'] : null)?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 18,
                            child: Text(
                              orderRef.isEmpty ? '-' : orderRef,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            flex: 32,
                            child: Text(
                              customerName.isEmpty ? '-' : customerName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}