import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/budgeting_dashboard_providers.dart';
import '../data/budgeting_repository.dart';
import 'application/view_budgets_screen_manager.dart';
import 'widgets/budgeting_panel.dart';
import 'widgets/order_detail_panel.dart';

class ViewBudgetsScreen extends ConsumerStatefulWidget {
  const ViewBudgetsScreen({super.key});

  @override
  ConsumerState<ViewBudgetsScreen> createState() => _ViewBudgetsScreenState();
}

class _ViewBudgetsScreenState extends ConsumerState<ViewBudgetsScreen> {
  late final BudgetingRepository _repository;
  late final ViewBudgetsScreenManager _manager;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(budgetingRepositoryProvider);
    _manager = ViewBudgetsScreenManager(repository: _repository);
    _manager.addListener(_handleManagerChanged);
    _manager.loadOrders();
  }

  @override
  void dispose() {
    _manager.removeListener(_handleManagerChanged);
    _manager.dispose();
    super.dispose();
  }

  void _handleManagerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Ver orcamentos'),
        backgroundColor: const Color(0xFFE7E7E7),
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Builder(
          builder: (context) {
            final visibleOrders = _manager.getVisibleOrders();
            final years = _manager.getAvailableYears();

            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: BudgetingPanel(
                    title: 'Pedidos',
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 10.0;
                              const buttonWidth = 42.0;
                              const yearWidth = 92.0;
                              final availableForFields =
                                  constraints.maxWidth - buttonWidth - yearWidth - (spacing * 3);
                              final textFieldWidth = availableForFields > 0
                                  ? availableForFields / 2
                                  : 0.0;

                              return Row(
                                children: [
                                  SizedBox(
                                    width: textFieldWidth,
                                    child: TextField(
                                      controller: _manager.customerController,
                                      decoration: const InputDecoration(
                                        labelText: 'Cliente',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _manager.applyFilters(),
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  SizedBox(
                                    width: textFieldWidth,
                                    child: TextField(
                                      controller: _manager.orderRefController,
                                      decoration: const InputDecoration(
                                        labelText: 'Referencia',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _manager.applyFilters(),
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  SizedBox(
                                    width: yearWidth,
                                    child: DropdownButtonFormField<int?>(
                                      value: _manager.selectedYear,
                                      decoration: const InputDecoration(
                                        labelText: 'Ano',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      items: [
                                        const DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('Todos'),
                                        ),
                                        ...years.map(
                                          (year) => DropdownMenuItem<int?>(
                                            value: year,
                                            child: Text(year.toString()),
                                          ),
                                        ),
                                      ],
                                      onChanged: _manager.setSelectedYear,
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  SizedBox(
                                    width: buttonWidth,
                                    height: 42,
                                    child: FilledButton(
                                      onPressed: _manager.applyFilters,
                                      style: FilledButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(Icons.search, size: 18),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          if (_manager.ordersError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Erro a carregar orcamentos: ${_manager.ordersError}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                          Expanded(
                            child: Stack(
                              children: [
                                if (visibleOrders.isEmpty && !_manager.ordersLoading)
                                  const Center(
                                    child: Text(
                                      'Sem pedidos para mostrar.',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  )
                                else
                                  ValueListenableBuilder<String?>(
                                    valueListenable: _manager.selectedOrderId,
                                    builder: (context, selectedOrderId, _) {
                                      return ListView.separated(
                                        itemCount: visibleOrders.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final item = visibleOrders[index];
                                          final isSelected =
                                              item['id'] == selectedOrderId;
                                          final orderRef =
                                              (item['order_ref'] ?? '').toString().trim();
                                          final customerName = (item['customer_name'] ?? '')
                                              .toString()
                                              .trim();
                                          final title = customerName.isEmpty
                                              ? orderRef
                                              : '$orderRef - $customerName';

                                          return InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => _manager.selectOrder(
                                              item['id']?.toString(),
                                            ),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 140),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 9,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFFFCE8E7)
                                                    : Colors.white.withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFFC94B47)
                                                      : BudgetingPanel.borderSoft,
                                                  width: isSelected ? 1.4 : 1,
                                                ),
                                              ),
                                              child: Text(
                                                title.isEmpty ? '-' : title,
                                                style: TextStyle(
                                                  color: BudgetingPanel.textDark,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                if (_manager.ordersLoading)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 8,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _manager.selectedOrderId,
                    builder: (context, selectedOrderId, _) {
                      return ValueListenableBuilder<Future<Map<String, dynamic>>?>(
                        valueListenable: _manager.orderDetailFuture,
                        builder: (context, orderDetailFuture, __) {
                          return OrderDetailPanel(
                            orderId: selectedOrderId,
                            expandedVersionId: _manager.expandedVersionId,
                            orderDetailFuture: orderDetailFuture,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
