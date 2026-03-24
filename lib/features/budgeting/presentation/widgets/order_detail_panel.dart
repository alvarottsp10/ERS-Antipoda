import 'package:flutter/material.dart';

import '../../application/view_budgets_mapper.dart';
import 'budgeting_panel.dart';
import 'version_card.dart';

class OrderDetailPanel extends StatelessWidget {
  const OrderDetailPanel({
    super.key,
    required this.orderId,
    required this.expandedVersionId,
    required this.orderDetailFuture,
  });

  final String? orderId;
  final ValueNotifier<String?> expandedVersionId;
  final Future<Map<String, dynamic>>? orderDetailFuture;

  @override
  Widget build(BuildContext context) {
    if (orderId == null || orderId!.trim().isEmpty || orderDetailFuture == null) {
      return const BudgetingPanel(
        title: 'Detalhe do pedido',
        placeholder: 'Seleciona um pedido para ver as versoes.',
      );
    }

    return BudgetingPanel(
      title: 'Detalhe do pedido',
      child: FutureBuilder<Map<String, dynamic>>(
        future: orderDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Erro a carregar detalhe: ${snapshot.error}',
                style: const TextStyle(color: Colors.black54),
              ),
            );
          }

          final detail = snapshot.data ?? const <String, dynamic>{};
          final budgeters = readBudgeters(detail);
          final versions =
              (detail['versions'] as List?)?.cast<Map<String, dynamic>>() ??
                  const <Map<String, dynamic>>[];

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    (detail['order_ref'] ?? '').toString().trim(),
                    (detail['customer_name'] ?? '').toString().trim(),
                  ].where((part) => part.isNotEmpty).join(' - '),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: BudgetingPanel.textDark,
                    fontSize: 16,
                  ),
                ),
                if (readViewBudgetText(detail['primary_typology']).isNotEmpty ||
                    readViewBudgetText(detail['primary_product_type']).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (readViewBudgetText(detail['primary_typology']).isNotEmpty)
                        _DetailChip(
                          label:
                              'Tipologia: ${readViewBudgetText(detail['primary_typology'])}',
                        ),
                      if (readViewBudgetText(detail['primary_product_type']).isNotEmpty)
                        _DetailChip(
                          label:
                              'Produto: ${readViewBudgetText(detail['primary_product_type'])}',
                        ),
                    ],
                  ),
                ],
                if (budgeters.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BudgetingPanel.borderSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orcamentistas',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: BudgetingPanel.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: budgeters
                              .map<Widget>(
                                (item) {
                                  final hours =
                                      (((item['hours'] as num?) ?? 0).toDouble())
                                          .toStringAsFixed(2);
                                  final backgroundColor =
                                      item['role'] == 'lead'
                                          ? const Color(0xFFF1ECE0)
                                          : const Color(0xFFE3E7ED);
                                  final borderColor = item['role'] == 'lead'
                                      ? const Color(0xFFD8C59A)
                                      : const Color(0xFFC9D3E0);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          readViewBudgetText(item['name']).isEmpty
                                              ? 'Orcamentista'
                                              : readViewBudgetText(item['name']),
                                          style: const TextStyle(
                                            color: BudgetingPanel.textDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Horas: ${hours}h',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: versions.isEmpty
                      ? const Center(
                          child: Text(
                            'Sem versoes para este pedido.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.separated(
                          itemCount: versions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final version = versions[index];
                            return VersionCard(
                              version: version,
                              detail: detail,
                              expandedVersionId: expandedVersionId,
                              index: index,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BudgetingPanel.borderSoft),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: BudgetingPanel.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
