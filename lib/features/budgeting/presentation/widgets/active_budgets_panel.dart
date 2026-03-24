import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/budgeting_dashboard_providers.dart';
import '../../application/budgeting_dashboard_view_models.dart';
import '../dialog/edit_budget_dialog.dart';
import 'budgeting_panel.dart';

class ActiveBudgetsPanel extends ConsumerWidget {
  const ActiveBudgetsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(budgetingActiveBudgetsProvider);

    return BudgetingPanel(
      title: 'Orcamentos',
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Erro ao carregar os orcamentos ativos: $error',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Sem orcamentos ativos.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ActiveBudgetCard(
                      item: item,
                      onEdit: () async {
                        final changed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => EditBudgetDialog(
                            orderId: item.orderId,
                            latestVersionId: item.latestVersionId,
                            orderRef: item.orderRef,
                            customerName: item.customerName,
                            currentBudgetingPhaseId: item.budgetingPhaseId,
                            currentBudgetingPhaseName: item.budgetingPhaseName,
                            currentTypologyId: null,
                            currentTypologyName: '',
                            currentProductTypeId: null,
                            currentProductTypeName: '',
                            currentIsSpecial: item.isSpecial,
                            currentProposalId: item.activeProposalId,
                            currentProposalSellTotal: item.activeProposalSellTotal,
                            currentProposalCostTotal: item.activeProposalCostTotal,
                            currentProposalCostMaterialTotal:
                                item.activeProposalCostMaterialTotal,
                            currentProposalCostLaborTotal:
                                item.activeProposalCostLaborTotal,
                            currentProposalCostProjectTotal:
                                item.activeProposalCostProjectTotal,
                            currentProposalMarginPct: item.activeProposalMarginPct,
                            currentProposalSentAt: item.activeProposalSentAt,
                            currentProposalFeedbackAt: item.activeProposalFeedbackAt,
                            currentProposalValidUntil: item.activeProposalValidUntil,
                            currentProposalItems: item.activeProposalItems,
                          ),
                        );

                        if (changed == true) {
                          ref.invalidate(budgetingNewOrdersProvider);
                          ref.invalidate(budgetingActiveBudgetsProvider);
                          ref.invalidate(budgetingMyBudgetsProvider);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      actions: itemsAsync.valueOrNull == null || itemsAsync.valueOrNull!.isEmpty
          ? null
          : [
              _SummaryBadge(
                label: 'Ativos',
                value: (itemsAsync.valueOrNull!.length) -
                    itemsAsync.valueOrNull!
                        .where(
                          (item) => item.budgetingPhaseName
                              .toLowerCase()
                              .contains('espera'),
                        )
                        .length,
                backgroundColor: const Color(0xFFDCE7DA),
                foregroundColor: const Color(0xFF234126),
              ),
              _SummaryBadge(
                label: 'Em espera',
                value: itemsAsync.valueOrNull!
                    .where(
                      (item) => item.budgetingPhaseName
                          .toLowerCase()
                          .contains('espera'),
                    )
                    .length,
                backgroundColor: const Color(0xFFF1ECE0),
                foregroundColor: const Color(0xFF5A4820),
              ),
            ],
    );
  }
}

class _ActiveBudgetCard extends StatelessWidget {
  const _ActiveBudgetCard({required this.item, required this.onEdit});

  final BudgetingActiveBudgetItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final leadAssignment = item.assignments.cast<BudgetingAssignmentItem?>().firstWhere(
          (assignment) => assignment?.assignmentRole == 'lead',
          orElse: () => null,
        );
    final supportAssignment = item.assignments.cast<BudgetingAssignmentItem?>().firstWhere(
          (assignment) => assignment?.assignmentRole != 'lead',
          orElse: () => null,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BudgetingPanel.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _buildProcessLabel(item),
                  style: const TextStyle(
                    fontSize: 14,
                    color: BudgetingPanel.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                _MetaChip(
                  label: leadAssignment == null
                      ? 'Lead: Sem lead'
                      : 'Lead: ${leadAssignment.assigneeName}',
                  backgroundColor: const Color(0xFFF1ECE0),
                  foregroundColor: const Color(0xFF5A4820),
                ),
                if (supportAssignment != null)
                  _MetaChip(
                    label: 'Support: ${_displayValue(supportAssignment.assigneeName)}',
                    backgroundColor: const Color(0xFFE3E7ED),
                    foregroundColor: const Color(0xFF29394E),
                  ),
                _MetaChip(
                  label: item.budgetingPhaseName.isEmpty
                      ? 'Fase: -'
                      : 'Fase: ${item.budgetingPhaseName}',
                  backgroundColor: const Color(0xFFDCE7DA),
                  foregroundColor: const Color(0xFF234126),
                ),
                _MetaChip(
                  label: 'Horas Totais: ${item.totalWorkedHours.toStringAsFixed(2)}h',
                  backgroundColor: const Color(0xFFE3E7ED),
                  foregroundColor: const Color(0xFF29394E),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  String _buildProcessLabel(BudgetingActiveBudgetItem item) {
    final process =
        item.orderRef.trim().isEmpty ? '(sem referencia)' : item.orderRef.trim();
    final customer = item.customerName.trim();
    if (customer.isEmpty) {
      return process;
    }
    return '$process - $customer';
  }

  String _displayValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});

  final BudgetingAssignmentItem assignment;

  @override
  Widget build(BuildContext context) {
    final isLead = assignment.assignmentRole == 'lead';

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLead
            ? const Color(0xFFF4F0E5)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLead ? const Color(0xFFD8C59A) : const Color(0xFFD6D6D6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaChip(
            label: assignment.roleLabel,
            backgroundColor:
                isLead ? const Color(0xFFE6D4A8) : const Color(0xFFE5E9EE),
            foregroundColor:
                isLead ? const Color(0xFF5E4410) : const Color(0xFF33465B),
          ),
          const SizedBox(height: 8),
          Text(
            assignment.assigneeName.isEmpty
                ? '(sem utilizador)'
                : assignment.assigneeName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '${assignment.workedHours.toStringAsFixed(2)} horas',
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    required this.minWidth,
  });

  final String label;
  final String value;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3D3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value.trim(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final int value;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withOpacity(0.9)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
